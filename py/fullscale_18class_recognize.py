"""18 类识别入口：从 checkpoint 加载类别顺序，拒绝旧 20 类权重。"""
import argparse
from pathlib import Path

import numpy as np
import torch

from correlation_modulation_model import CorrelationIQCNN
from fullscale_18class_config import DEFAULT_OUTPUT, validate_checkpoint_classes
from fullscale_training import probabilities
from signal_preprocess import to_iq_channels


def load_model(checkpoint, device):
    if not checkpoint.exists():
        raise FileNotFoundError('18-class weights not found. Run fullscale_18class_training.py first.')
    cp = torch.load(checkpoint, map_location='cpu', weights_only=True)
    metadata = cp['metadata']
    validate_checkpoint_classes(metadata)
    if metadata['architecture'] != 'correlation_multiscale' or metadata['sample_length'] != 1024:
        raise ValueError('Incompatible checkpoint architecture or input length')
    model = CorrelationIQCNN(len(metadata['classes'])).to(device)
    model.load_state_dict(cp['model_state'], strict=True)
    return model.eval(), metadata


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path, help='.npy IQ or little-endian int16 interleaved .iq')
    parser.add_argument('--checkpoint', type=Path, default=DEFAULT_OUTPUT / 'best.pt')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--batch-size', type=int, default=128)
    parser.add_argument('--device', choices=['cpu', 'cuda'], default='cuda' if torch.cuda.is_available() else 'cpu')
    args = parser.parse_args()
    if args.output.exists() or args.output.suffix.lower() != '.npz' or args.batch_size <= 0:
        raise ValueError('Choose a new .npz output and a positive batch size')
    torch.set_num_threads(4)
    model, metadata = load_model(args.checkpoint, args.device)
    if args.input.suffix.lower() == '.iq':
        if args.input.stat().st_size % 4096:
            raise ValueError('Truncated IQ frame')
        x = np.memmap(args.input, mode='r', dtype='<i2').reshape(-1, 1024, 2).transpose(0, 2, 1)
    else:
        x = to_iq_channels(np.load(args.input, allow_pickle=False))
    if not len(x) or x.shape[-1] != 1024:
        raise ValueError('Expected nonempty 1024-point IQ frames sampled at 1 MHz')
    p = probabilities(model, x, args.batch_size, args.device)
    labels = np.array(metadata['classes'])
    np.savez_compressed(args.output, prediction=p.argmax(1), labels=labels[p.argmax(1)], probabilities=p, classes=labels)
    print(f'classes={len(labels)} frames={len(x)} output={args.output.resolve()}')


if __name__ == '__main__':
    main()
