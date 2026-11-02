"""Model test interface: run an exported IQ classifier on live or recorded IQ.

Contract KU5P_IQ_MODEL_1 (written by the V2 project's `python -m v2 export`):
    <name>.onnx        input 'iq' float32 (N,2,L), output 'logits' float32 (N,C)
    <name>.model.json  schema, classes (column order), fs_hz, window_points,
                       normalization 'per_window_rms_no_dc', output_kind 'logits'

Preprocessing uses the model card's window length: each IQ window is divided by
sqrt(mean(I^2,Q^2)) with no mean removal. K-frame fusion averages logits over
consecutive windows. Labels used for scoring are the TX1 configuration
readback, not an independent truth. No hardware access in this module.
"""
from __future__ import annotations

import json
import math
import struct
import zlib
from pathlib import Path

import numpy as np

SCHEMA='KU5P_IQ_MODEL_1'
NORMALIZATIONS=('per_window_rms_no_dc',)
INDEX=struct.Struct('>IIQQIiHHI')
ALIASES={'AM':'AM-DSB-WC','BPSK':'2PSK','QPSK':'4PSK'}


class ModelError(ValueError):
    pass


def canonical(label):
    return ALIASES.get(label,label) if label else label


class IQModel:
    """An ONNX classifier plus its model card. Thread/process local: create one per worker."""

    def __init__(self,path):
        path=Path(path)
        card_path=path if path.suffix=='.json' else path.with_suffix('.model.json')
        try:card=json.loads(card_path.read_text(encoding='utf-8'))
        except (OSError,ValueError) as exc:raise ModelError(f'无法读取模型说明 {card_path.name}：{exc}') from exc
        if card.get('schema')!=SCHEMA:raise ModelError(f'模型说明 schema 不是 {SCHEMA}')
        if card.get('normalization') not in NORMALIZATIONS:raise ModelError('不支持的预处理：'+str(card.get('normalization')))
        if card.get('output_kind','logits') not in ('logits','probabilities'):raise ModelError('不支持的输出类型')
        self.card=card;self.classes=tuple(card['classes']);self.fs=int(card['fs_hz'])
        self.points=int(card['window_points']);self.onnx=card_path.parent/card['onnx_file']
        if not self.classes:raise ModelError('模型说明没有类别')
        try:import onnxruntime
        except ImportError as exc:raise ModelError('缺少 onnxruntime，无法加载 ONNX 模型') from exc
        options=onnxruntime.SessionOptions()
        # Leave cores to the GUI, the receiver and the analysis workers.
        options.intra_op_num_threads=2;options.inter_op_num_threads=1
        try:self.session=onnxruntime.InferenceSession(str(self.onnx),options,providers=['CPUExecutionProvider'])
        except Exception as exc:raise ModelError(f'ONNX 加载失败：{exc}') from exc
        inputs=self.session.get_inputs();outputs=self.session.get_outputs()
        self.input=card.get('input_name',inputs[0].name);self.output=card.get('output_name',outputs[0].name)
        shape=inputs[0].shape
        if len(shape)!=3 or shape[1:]!=[2,self.points]:raise ModelError(f'ONNX 输入形状 {shape} 与说明 (N,2,{self.points}) 不符')

    def describe(self):
        c=self.card
        return dict(name=self.onnx.stem,architecture=c.get('architecture'),classes=list(self.classes),
                    fs_hz=self.fs,window_points=self.points,fixture_only=bool(c.get('fixture_only')),
                    onnx_sha256=c.get('onnx_sha256'),project_version=c.get('project_version'))

    def windows(self,raw):
        """Little-endian int16 I,Q bytes -> (N,2,points) float32 normalized windows and a keep mask."""
        x=np.frombuffer(raw,dtype='<i2')
        n=len(x)//(2*self.points)
        if not n:return np.zeros((0,2,self.points),np.float32),np.zeros(0,bool)
        w=x[:n*2*self.points].reshape(n,self.points,2).transpose(0,2,1).astype(np.float32)
        rms=np.sqrt(np.mean(w*w,axis=(1,2)))
        keep=rms>=1e-8
        w[keep]/=rms[keep,None,None]
        return w,keep

    def logits(self,windows,batch=256):
        if not len(windows):return np.zeros((0,len(self.classes)),np.float32)
        rows=[self.session.run([self.output],{self.input:np.ascontiguousarray(windows[i:i+batch])})[0]
              for i in range(0,len(windows),batch)]
        out=np.concatenate(rows).astype(np.float64)
        if out.shape[1]!=len(self.classes):raise ModelError(f'模型输出 {out.shape[1]} 列，说明文件有 {len(self.classes)} 类')
        if self.card.get('output_kind')=='probabilities':out=np.log(np.clip(out,1e-12,None))
        return out


def softmax(logits):
    z=np.asarray(logits,dtype=np.float64);z=z-z.max(axis=-1,keepdims=True);e=np.exp(z)
    return e/e.sum(axis=-1,keepdims=True)


def classify_block(model,raw,fs,frames=1,label=None,top=5):
    """Live inference on one preview block (consecutive accepted windows).

    Returns per-window predictions and a fused decision over the newest `frames`
    windows. Runs in a worker process; model is created there once and reused.
    """
    if fs!=model.fs:
        return dict(error=f'模型要求 {model.fs/1e6:g} MSPS 输入，当前接收为 {fs/1e6:g} MSPS')
    windows,keep=model.windows(raw)
    if not keep.any():return dict(error='没有有效窗口（全零或数据不足 1 窗）')
    windows=windows[keep]
    logit=model.logits(windows)
    per=softmax(logit)
    k=max(1,min(int(frames),len(logit)))
    fused=softmax(logit[-k:].mean(axis=0))
    order=np.argsort(fused)[::-1][:top]
    label=canonical(label)
    single=per.argmax(axis=1)
    result=dict(windows=len(logit),fused_frames=k,
                top=[(model.classes[i],float(fused[i])) for i in order],
                predicted=model.classes[int(order[0])],confidence=float(fused[order[0]]),
                single_predictions=[model.classes[i] for i in single[-16:]],
                label=label,label_known=label in model.classes if label else False)
    if label and label in model.classes:
        li=model.classes.index(label)
        result.update(correct=result['predicted']==label,label_probability=float(fused[li]),
                      single_window_accuracy=float(np.mean(single==li)))
    return result


def read_capture(json_path,limit=None):
    """Yield (window_seq, sample_index, flags, raw_bytes) from a KU5P .json/.iq/.index.bin recording, CRC-checked."""
    json_path=Path(json_path).with_suffix('.json')
    meta=json.loads(json_path.read_text(encoding='utf-8'))
    iq,index=json_path.with_suffix('.iq'),json_path.with_suffix('.index.bin')
    points=meta.get('points_per_window',1024);size=points*4
    with index.open('rb') as fi,iq.open('rb') as fq:
        count=0
        while (record:=fi.read(INDEX.size)) and (limit is None or count<limit):
            seq,cid,sample,offset,fs,gain,flags,reserved,crc=INDEX.unpack(record)
            fq.seek(offset);raw=fq.read(size)
            if len(raw)!=size or zlib.crc32(raw)!=crc:raise ModelError(f'{json_path.name}: 窗口 {seq} CRC 错误')
            yield seq,sample,flags,raw;count+=1


def capture_label(meta):
    cfg=meta.get('capture_configuration') or {}
    return canonical(meta.get('label') or cfg.get('label') or cfg.get('configured_modulation'))


def assemble_model_windows(rows, source_points, model_points):
    """Join only adjacent clean recorder packets into full model windows.

    ``rows`` have already passed packet flags, zero and ADC-rail checks.
    A gap after filtering must discard any unfinished long window.
    """
    if source_points <= 0 or model_points < source_points or model_points % source_points:
        raise ModelError('Model window must be an integer multiple of recorder window')
    factor = model_points // source_points
    if factor == 1:
        return rows
    joined = []
    block = []
    for row in rows:
        if block and (row[0] != block[-1][0] + 1 or row[1] != block[-1][1] + source_points):
            block = []
        block.append(row)
        if len(block) == factor:
            flags = 0
            for item in block:
                flags |= item[2]
            joined.append((block[0][0], block[0][1], flags, b''.join(item[3] for item in block)))
            block = []
    return joined


def evaluate_directory(model_path,directory,frames=(1,2,4,8),limit=4096,progress=None):
    """Offline test over every training recording (*.json sidecar) in one directory.

    Uses the same window filter as V2 training (flags bit0..2, all-zero, >1 % ADC
    rail) and fuses K consecutive windows (same capture, contiguous sample_index
    and window_seq, no flags). Returns a JSON-serializable report.
    """
    model=IQModel(model_path)
    paths=sorted(Path(directory).glob('*.json'))
    if not paths:raise ModelError('目录中没有录制 .json')
    classes=list(model.classes)
    files=[];confusion={k:np.zeros((len(classes),len(classes)),np.int64) for k in frames}
    totals={k:[0,0] for k in frames};skipped=[]
    for n,path in enumerate(paths):
        if progress:progress(n,len(paths),path.name)
        try:meta=json.loads(path.read_text(encoding='utf-8'))
        except (OSError,ValueError):continue
        if 'points_per_window' not in meta or 'capture_configuration' not in meta and 'label' not in meta:
            continue
        label=capture_label(meta)
        if meta.get('fs_hz')!=model.fs:
            skipped.append(dict(file=path.name,reason=f"采样率 {meta.get('fs_hz')} 与模型 {model.fs} 不符"));continue
        if label not in classes:
            skipped.append(dict(file=path.name,reason=f'标签 {label} 不在模型类别中'));continue
        try:rows=list(read_capture(path,limit))
        except (OSError,ModelError) as exc:
            skipped.append(dict(file=path.name,reason=str(exc)));continue
        good=[];excluded=0
        for seq,sample,flags,raw in rows:
            a=np.frombuffer(raw,dtype='<i2')
            if flags&7 or not a.any() or np.mean((a<=-2048)|(a>=2047))>.01:excluded+=1;continue
            good.append((seq,sample,flags,raw))
        if not good:
            skipped.append(dict(file=path.name,reason='没有可用窗口'));continue
        source_points=int(meta.get('points_per_window',1024))
        source_windows=len(good)
        try:good=assemble_model_windows(good,source_points,model.points)
        except ModelError as exc:
            skipped.append(dict(file=path.name,reason=str(exc)));continue
        if not good:
            skipped.append(dict(file=path.name,reason='No complete contiguous model windows'));continue
        sequence_step=model.points//source_points
        windows,_=model.windows(b''.join(r[3] for r in good))
        logit=model.logits(windows)
        li=classes.index(label);entry=dict(file=path.name,label=label,windows=len(good),excluded=excluded,
                                          source_windows=source_windows,window_points=model.points,
                                          tx_internal_snr_db=(meta.get('capture_configuration') or {}).get('tx',{}).get('snr_db'),
                                          simulated=bool(meta.get('simulated')))
        for k in frames:
            groups=[];run=[]
            for i,(seq,sample,flags,_) in enumerate(good):
                if run and not (sample==good[run[-1]][1]+model.points and seq==good[run[-1]][0]+sequence_step):run=[]
                if flags:run=[];continue
                run.append(i)
                if len(run)==k:groups.append(run);run=[]
            if not groups:entry[f'accuracy_{k}']=None;continue
            pred=np.array([logit[g].mean(axis=0).argmax() for g in groups])
            np.add.at(confusion[k],(np.full(len(pred),li),pred),1)
            totals[k][0]+=int(np.sum(pred==li));totals[k][1]+=len(pred)
            entry[f'accuracy_{k}']=float(np.mean(pred==li))
        files.append(entry)
    if progress:progress(len(paths),len(paths),'')
    summary={str(k):dict(groups=totals[k][1],accuracy=(totals[k][0]/totals[k][1] if totals[k][1] else None),
                         confusion_matrix=confusion[k].tolist()) for k in frames}
    return dict(schema='KU5P_MODEL_TEST_REPORT_1',model=model.describe(),directory=str(Path(directory).resolve()),
                classes=classes,frames=list(frames),summary=summary,files=files,skipped=skipped,
                label_definition='TX1 configuration readback; not an independent truth',
                filter='flags&7, all-zero, >1% ADC rail windows excluded (same as V2 training)')


# Worker-process entry points: one cached model per process.
_MODEL=None


def _worker_model(path,stamp):
    global _MODEL
    if _MODEL is None or _MODEL[0]!=(path,stamp):_MODEL=((path,stamp),IQModel(path))
    return _MODEL[1]


def live_job(path,stamp,raw,fs,frames,label):
    return classify_block(_worker_model(path,stamp),raw,fs,frames,label)


def describe_job(path):
    return IQModel(path).describe()
