"""Training-only CFO/phase augmentation with an explicit untouched fraction."""
from __future__ import annotations

import math


def augment_carrier(batch, generator, probability=0.5, max_cfo=0.01, max_phase=math.pi,
                    return_parameters=False):
    import torch
    if batch.ndim != 3 or batch.shape[1] != 2:
        raise ValueError("batch must have shape (N,2,L)")
    if not 0 <= probability <= 1 or not 0 <= max_cfo < 0.5 or not 0 <= max_phase <= math.pi:
        raise ValueError("invalid augmentation probability or frequency/phase limits")
    count, _, length = batch.shape
    # 按“帧”抽签：一帧内的全部采样点共享同一个频偏和初始相位。
    # 最新微调使用 probability=0.25，约 75% 的训练帧保持原样。
    selected = torch.rand(count, device=batch.device, generator=generator) < probability
    cfo = (2 * torch.rand(count, device=batch.device, generator=generator) - 1) * max_cfo * selected
    phase = (2 * torch.rand(count, device=batch.device, generator=generator) - 1) * max_phase * selected
    # cfo 的单位为 cycles/sample；实际频偏 Hz = cfo * 采样率 Hz。
    # theta[n] = phi + 2*pi*cfo*n：相位常量负责整体旋转，频偏负责随时间旋转。
    angle = phase[:, None] + 2 * math.pi * cfo[:, None] * torch.arange(length, device=batch.device)
    cosine, sine = torch.cos(angle), torch.sin(angle)
    i, q = batch[:, 0], batch[:, 1]
    # 等价于复数乘法 (I+jQ)*exp(j*theta)，保持每点复幅度及调制标签不变。
    # 这是训练时主动“加失真”，让分类器适应失真，并没有估计或消除原有频偏。
    rotated = torch.stack((i * cosine - q * sine, i * sine + q * cosine), dim=1)
    # Exact passthrough for unselected frames, including their float32 bits.
    output = torch.where(selected[:, None, None], rotated, batch)
    # generator 由调用方独立管理，避免增强抽样改变训练数据的洗牌顺序。
    if return_parameters:
        return output, {"selected": selected, "cfo": cfo, "phase": phase}
    return output
