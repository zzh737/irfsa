"""在 fullscale 实采数据上从头训练 20 类多尺度相关 CNN，按采集记录隔离测试。"""
from __future__ import annotations

import argparse
import collections
import math
from pathlib import Path
import shutil
import time

import numpy as np
import torch

from correlation_modulation_model import CorrelationIQCNN
from fullscale_dataset import digest, read_frames, sample_split, scan_recordings, split_recordings, valid_rows, write_json
from targeted_augmentation import augment_carrier


def normalized_tensor(raw, device):
    x = torch.as_tensor(raw, device=device).float()
    return x / x.square().mean((1, 2), keepdim=True).sqrt().clamp_min(1e-8)


@torch.inference_mode()
def probabilities(model, x, batch_size, device):
    model.eval()
    return np.concatenate([model(normalized_tensor(x[start:start + batch_size], device)).softmax(1).cpu().numpy()
                           for start in range(0, len(x), batch_size)])


def snr_loss_weights(records, record_ids, device):
    """提高低 SNR 帧在训练目标中的占比，避免高 SNR 样本主导总体损失。"""
    weights = {'-3': 2.20, '0': 1.85, '3': 1.50, '6': 1.25,
               '9': 1.05, '12': 0.95, '15': 0.90, '18': 0.85,
               '20': 0.80, 'off': 0.65}
    return torch.as_tensor([weights[str(records[int(i)]['snr_setting'])] for i in record_ids],
                           dtype=torch.float32, device=device)


def scores(y, prediction, classes):
    cm = np.zeros((len(classes), len(classes)), dtype=np.int64)
    np.add.at(cm, (y, prediction), 1)
    recall = cm.diagonal() / np.maximum(cm.sum(1), 1)
    return {'accuracy': float((prediction == y).mean()), 'macro_recall': float(recall.mean()),
            'count': len(y), 'per_class_recall': dict(zip(classes, recall.tolist())),
            'confusion_matrix': cm.tolist()}


def train(args, records, protocol):
    device = args.device
    classes = protocol['classes']
    torch.manual_seed(args.seed)
    model = CorrelationIQCNN(len(classes)).to(device)
    if getattr(args, 'init_checkpoint', None) is not None:
        initial = torch.load(args.init_checkpoint, map_location='cpu', weights_only=True)
        if initial.get('metadata', {}).get('classes') != classes:
            raise ValueError('Initial checkpoint class order differs from protocol')
        model.load_state_dict(initial['model_state'])
        del initial
    optimizer = torch.optim.AdamW(model.parameters(), lr=args.lr, weight_decay=1e-4)
    scaler = torch.amp.GradScaler('cuda', enabled=device == 'cuda')
    aug_rng = torch.Generator(device=device).manual_seed(args.seed + 100)
    shuffle_rng = torch.Generator(device=device).manual_seed(args.seed + 200)
    vx, vy, vi, vr = sample_split(records, 'validation', args.validation_frames, args.seed + 300)
    np.savez_compressed(args.output / 'validation_rows.npz', record_ids=vi, source_rows=vr, true=vy)
    history, best, best_epoch, first_epoch = [], -1., 0, 1
    last = args.output / 'last.pt'
    if last.exists():
        cp = torch.load(last, map_location='cpu', weights_only=True)
        if cp['protocol_sha256'] != digest(args.output / 'protocol.json'):
            raise ValueError('Resume protocol differs')
        model.load_state_dict(cp['model_state'])
        optimizer.load_state_dict(cp['optimizer'])
        scaler.load_state_dict(cp['scaler'])
        torch.set_rng_state(cp['torch_rng'])
        if device == 'cuda':
            torch.cuda.set_rng_state_all(cp['cuda_rng'])
        aug_rng.set_state(cp['augmentation_rng'])
        shuffle_rng.set_state(cp['shuffle_rng'])
        history, best, best_epoch, first_epoch = cp['history'], cp['best'], cp['best_epoch'], cp['epoch'] + 1
        del cp
    for epoch in range(first_epoch, args.epochs + 1):
        started = time.perf_counter()
        # 只暂存本轮抽样的 IQ，避免一次加载约 10 GB 的整个数据集。
        raw, labels, ids, rows = sample_split(records, 'train', args.train_frames, args.seed + 1000 + epoch)
        np.savez_compressed(args.output / 'train_rows_latest.npz', epoch=epoch, record_ids=ids, source_rows=rows)
        tx = torch.as_tensor(raw, device=device)
        ty = torch.as_tensor(labels, device=device)
        sample_weights = snr_loss_weights(records, ids, device) if getattr(args, 'snr_weighting', False) else None
        del raw, ids, rows
        order = torch.randperm(len(ty), device=device, generator=shuffle_rng)
        model.train()
        loss_sum, correct = torch.zeros((), device=device), torch.zeros((), device=device)
        steps = math.ceil(len(ty) / args.batch_size)
        for step, start in enumerate(range(0, len(ty), args.batch_size)):
            index = order[start:start + args.batch_size]
            bx = normalized_tensor(tx[index], device)
            # 不消除实采的 120 kHz 频偏；仅添加小频偏和随机整体相位以增强鲁棒性。
            bx = augment_carrier(bx, aug_rng, probability=.5, max_cfo=.003)
            progress = (epoch - 1 + step / steps) / args.epochs
            warmup = min(1., (epoch - 1 + (step + 1) / steps) / 2)
            lr = args.lr * warmup * (.05 + .95 * .5 * (1 + math.cos(math.pi * progress)))
            for group in optimizer.param_groups:
                group['lr'] = lr
            optimizer.zero_grad(set_to_none=True)
            with torch.autocast(device_type=device, enabled=device == 'cuda', dtype=torch.float16):
                logits = model(bx)
                loss_values = torch.nn.functional.cross_entropy(
                    logits, ty[index], label_smoothing=.02, reduction='none')
                loss = ((loss_values * sample_weights[index]).mean()
                        if sample_weights is not None else loss_values.mean())
            scaler.scale(loss).backward()
            scaler.unscale_(optimizer)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 5.)
            scaler.step(optimizer)
            scaler.update()
            loss_sum += loss.detach() * len(index)
            correct += (logits.argmax(1) == ty[index]).sum()
        train_count = len(ty)
        del tx, ty, order, sample_weights
        p = probabilities(model, vx, args.batch_size, device)
        validation = scores(vy, p.argmax(1), classes)
        if not math.isfinite(float(loss_sum)):
            raise ValueError('Nonfinite training loss')
        if validation['accuracy'] > best:
            best, best_epoch = validation['accuracy'], epoch
            torch.save({'model_state': {k: v.detach().cpu() for k, v in model.state_dict().items()},
                        'metadata': {'architecture': 'correlation_multiscale', 'classes': classes,
                                     'sample_length': 1024, 'sample_rate_hz': 1000000,
                                     'normalization': 'per_sample_rms', 'training_dataset': protocol['data'],
                                     'input_frequency_shift_hz': 0, 'seed': args.seed},
                        'epoch': epoch, 'validation': validation,
                        'protocol_sha256': digest(args.output / 'protocol.json')}, args.output / 'best.pt')
        row = {'epoch': epoch, 'train_frames': train_count, 'train_loss': float(loss_sum) / train_count,
               'train_accuracy': float(correct) / train_count, 'validation': validation,
               'seconds': time.perf_counter() - started, 'learning_rate': lr}
        history.append(row)
        write_json(args.output / 'history.json', history)
        state = {'epoch': epoch, 'model_state': model.state_dict(), 'optimizer': optimizer.state_dict(),
                 'scaler': scaler.state_dict(), 'history': history, 'best': best, 'best_epoch': best_epoch,
                 'torch_rng': torch.get_rng_state(), 'cuda_rng': torch.cuda.get_rng_state_all() if device == 'cuda' else [],
                 'augmentation_rng': aug_rng.get_state(), 'shuffle_rng': shuffle_rng.get_state(),
                 'protocol_sha256': digest(args.output / 'protocol.json')}
        torch.save(state, args.output / 'last.tmp.pt')
        (args.output / 'last.tmp.pt').replace(last)
        del state
        print(f"epoch={epoch:02d}/{args.epochs} loss={row['train_loss']:.4f} train={row['train_accuracy']:.2%} "
              f"validation={validation['accuracy']:.2%} best={best:.2%}@{best_epoch} seconds={row['seconds']:.1f}", flush=True)
        if epoch >= 16 and epoch - best_epoch >= args.patience:
            print('Early stop: validation patience reached', flush=True)
            break
    return history


def final_test(args, records, protocol):
    # 先固定最佳验证权重及哈希，再读取独立测试记录的 IQ。
    checkpoint = args.output / 'best.pt'
    lock = {'checkpoint': str(checkpoint.resolve()), 'checkpoint_sha256': digest(checkpoint),
            'protocol_sha256': digest(args.output / 'protocol.json'), 'selection': 'maximum validation accuracy',
            'test_used_for_selection': False}
    write_json(args.output / 'locked_selection.json', lock)
    cp = torch.load(checkpoint, map_location='cpu', weights_only=True)
    model = CorrelationIQCNN(len(protocol['classes'])).to(args.device)
    model.load_state_dict(cp['model_state'])
    all_y, all_p, all_ids, all_rows = [], [], [], []
    started = time.perf_counter()
    for i, r in enumerate(records):
        if r['split'] != 'test':
            continue
        rows = valid_rows(r)
        p = probabilities(model, read_frames(r, rows), args.batch_size, args.device)
        all_y.append(np.full(len(rows), protocol['classes'].index(r['label']), dtype=np.int64))
        all_p.append(p)
        all_ids.append(np.full(len(rows), i, dtype=np.int32))
        all_rows.append(rows.astype(np.int32))
    y, p, ids = np.concatenate(all_y), np.concatenate(all_p), np.concatenate(all_ids)
    result = scores(y, p.argmax(1), protocol['classes'])
    result.update({'checkpoint_sha256': lock['checkpoint_sha256'], 'best_epoch': cp['epoch'],
                   'validation_accuracy': cp['validation']['accuracy'], 'seconds': time.perf_counter() - started,
                   'test_used_for_selection': False})
    for field in ['snr_setting', 'bandwidth_hz', 'rx_gain_mdB', 'attenuation1_db']:
        values = np.array([str(records[int(i)][field]) for i in ids])
        result[field] = {v: {'accuracy': float((p.argmax(1)[values == v] == y[values == v]).mean()),
                             'count': int((values == v).sum())} for v in sorted(set(values))}
    # 同段采集帧相关，置信区间按整段重采样，而不是把所有帧当作独立样本。
    groups = np.unique(ids)
    hits = np.array([((p.argmax(1) == y) & (ids == i)).sum() for i in groups])
    counts = np.array([(ids == i).sum() for i in groups])
    chosen = np.random.default_rng(args.seed + 500).integers(0, len(groups), (2000, len(groups)))
    result['record_bootstrap_accuracy_ci95'] = np.quantile(hits[chosen].sum(1) / counts[chosen].sum(1), [.025, .975]).tolist()
    np.savez_compressed(args.output / 'test_predictions.npz', true=y, probabilities=p,
                        record_ids=ids, source_rows=np.concatenate(all_rows), classes=protocol['classes'])
    write_json(args.output / 'test_results.json', result)
    assert digest(checkpoint) == lock['checkpoint_sha256']
    print(f"FINAL TEST accuracy={result['accuracy']:.4%} frames={len(y)} checkpoint={checkpoint}", flush=True)
    return result


def report(args, protocol, history, result):
    counts = collections.Counter(r['split'] for r in protocol['records'])
    text = f'''# fullscale_v2 训练结果

使用实采数据 `{protocol['data']}`，共 {len(protocol['classes'])} 类、{len(protocol['records'])} 段记录。
带宽下限 {protocol['minimum_bandwidth_hz']} Hz；当前纳入带宽 100/200 kHz。
训练/验证/测试采集段数：{counts['train']}/{counts['validation']}/{counts['test']}。

## 模型与结果

- 架构：实数多尺度 CNN（3/15/31）+ 延迟相关分支，单模型、单视图。
- 最佳轮次：{result['best_epoch']}；实际训练 {len(history)} 轮。
- 验证集准确率：{result['validation_accuracy']:.4%}。
- 独立测试集准确率：{result['accuracy']:.4%}；宏平均召回率：{result['macro_recall']:.4%}。
- 测试有效帧：{result['count']}；按记录 bootstrap 的 95% 区间：{result['record_bootstrap_accuracy_ci95']}。
- 权重：`best.pt`；分类别及 SNR/带宽/增益指标：`test_results.json`。

## 数据处理与可信范围

输入为 1 MHz、1024 点实采 IQ，逐帧 RMS 归一化，不执行载波/符号同步，不使用 TX 参数作为模型输入。
2PSK/4PSK 保持数据集原标签，分别对应通常所称 BPSK/QPSK。
每个类别/带宽/TX SNR 设置内，整段记录按 2/1/1 分组；随机种子及采集 ID 不跨集合。
训练每轮每段无放回抽取 {args.train_frames} 帧，各轮重新抽样；验证每段固定 {args.validation_frames} 帧；测试使用各段全部有效帧。
所有 flags 非零帧排除；每段抽检首中末三个有效帧 CRC，并检查全部索引、帧数和文件大小。不是全文件 CRC 校验。
本数据集只有同一采集 campaign，结果只衡量同次采集内不同记录的泛化，不能代表跨硬件、跨日期或任意频偏表现。
SNR 字段是发射端内部设定，`off` 表示内部噪声关闭，不能当作接收端实测 SNR。
测试只在验证选定权重后运行；没有依据测试结果继续选择模型。与旧的 6 类 RadioML 准确率不能直接比较。

## 复现与识别

```powershell
./.venv-sync/Scripts/python.exe fullscale_training.py --data "{protocol['data']}" --output "{args.output.as_posix()}"
./.venv-sync/Scripts/python.exe fullscale_recognize.py your_iq.npy --checkpoint "{(args.output / 'best.pt').as_posix()}" --output predictions.npz
```

记录清单及分割见 `protocol.json`；每轮抽帧由 seed+1000+epoch 确定；`last.pt` 可断点续训。
历史 RadioML 源码、权重及默认识别入口保持原版本，本次使用独立识别入口。
'''
    (args.output / '训练报告.md').write_text(text, encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--data', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=Path('outputs/fullscale_v2_20261031'))
    parser.add_argument('--epochs', type=int, default=32)
    parser.add_argument('--train-frames', type=int, default=256)
    parser.add_argument('--validation-frames', type=int, default=128)
    parser.add_argument('--batch-size', type=int, default=128)
    parser.add_argument('--patience', type=int, default=10)
    parser.add_argument('--minimum-bandwidth-hz', type=int, default=60000)
    parser.add_argument('--lr', type=float, default=.001)
    parser.add_argument('--seed', type=int, default=2026103101)
    parser.add_argument('--device', choices=['cpu', 'cuda'], default='cuda' if torch.cuda.is_available() else 'cpu')
    args = parser.parse_args()
    if min(args.epochs, args.train_frames, args.validation_frames, args.batch_size, args.patience) <= 0:
        raise ValueError('Positive training limits required')
    torch.set_num_threads(4)
    torch.backends.cudnn.benchmark = False
    args.output.mkdir(parents=True, exist_ok=True)
    if (args.output / 'test_results.json').exists():
        raise FileExistsError('Test already evaluated; preserve completed results')
    print('Scanning metadata/indexes and checking sampled CRCs...', flush=True)
    records, excluded = scan_recordings(args.data, args.minimum_bandwidth_hz)
    records = split_recordings(records, args.seed)
    sources = ['fullscale_training.py', 'fullscale_dataset.py', 'fullscale_recognize.py',
               'correlation_modulation_model.py', 'multiscale_modulation_model.py', 'modulation_model.py', 'targeted_augmentation.py']
    protocol = {'data': str(args.data.resolve()), 'classes': sorted({r['label'] for r in records}),
                'records': records, 'excluded': excluded, 'minimum_bandwidth_hz': args.minimum_bandwidth_hz,
                'configuration': {k: v for k, v in vars(args).items() if k not in ('data', 'output')},
                'selection': 'maximum validation accuracy; test after selection only',
                'code_sha256': {n: digest(Path(__file__).parent / n) for n in sources},
                'environment': {'torch': str(torch.__version__), 'numpy': np.__version__,
                                'gpu': torch.cuda.get_device_name() if args.device == 'cuda' else None}}
    if (args.output / 'protocol.json').exists():
        import json
        if json.loads((args.output / 'protocol.json').read_text(encoding='utf-8')) != protocol:
            raise ValueError('Protocol changed; use a new output directory')
    else:
        write_json(args.output / 'protocol.json', protocol)
        (args.output / 'sources').mkdir(exist_ok=True)
        for name in sources:
            shutil.copyfile(Path(__file__).parent / name, args.output / 'sources' / name)
    print('records', dict(collections.Counter(r['split'] for r in records)), 'classes', protocol['classes'], flush=True)
    history = train(args, records, protocol)
    result = final_test(args, records, protocol)
    report(args, protocol, history, result)
    assert all(digest(Path(__file__).parent / n) == h for n, h in protocol['code_sha256'].items())


if __name__ == '__main__':
    main()
