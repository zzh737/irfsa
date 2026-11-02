"""IQ shape conversion, normalization and numerical checks."""

from __future__ import annotations

import numpy as np


def to_iq_channels(signals: np.ndarray) -> np.ndarray:
    """Convert complex or real IQ arrays to ``(N, 2, L)`` float32."""

    # 统一表示：N 为帧数，2 为 I/Q 两通道，L 为每帧采样点数。
    # 复数输入 x=I+jQ 被拆成实部和虚部；转换不改变采样率或采样顺序。
    values = np.asarray(signals)
    if np.iscomplexobj(values):
        if values.ndim != 2:
            raise ValueError("complex input must have shape (N, L)")
        values = np.stack((values.real, values.imag), axis=1)
    elif values.ndim == 3 and values.shape[1] == 2:
        pass
    elif values.ndim == 3 and values.shape[2] == 2:
        values = values.transpose(0, 2, 1)
    else:
        raise ValueError("IQ input must have shape (N, 2, L), (N, L, 2), or (N, L) complex")
    values = np.asarray(values, dtype=np.float32)
    validate_signals(values)
    return values


def validate_signals(signals: np.ndarray) -> None:
    values = np.asarray(signals)
    if values.ndim != 3 or values.shape[1] != 2 or values.shape[2] == 0:
        raise ValueError("signals must have shape (N, 2, L) with L > 0")
    if not np.isfinite(values).all():
        raise ValueError("signals contain NaN or infinite values")


def normalize_iq(signals: np.ndarray, mode: str = "per_sample_rms", epsilon: float = 1e-8) -> np.ndarray:
    """Normalize I/Q power while preserving the two-channel representation."""

    values = to_iq_channels(signals)
    if not np.isfinite(epsilon) or epsilon <= 0:
        raise ValueError("epsilon must be positive and finite")
    if mode == "none":
        return values
    if mode not in {"per_sample_rms", "global_rms"}:
        raise ValueError("normalization mode must be none, per_sample_rms, or global_rms")
    if len(values) == 0:
        return values.copy()
    # 每帧 r=sqrt(sum_n(I[n]^2+Q[n]^2)/(2*L))；I/Q 共用尺度，保留相位关系。
    # global_rms 的尺度依赖整个批次；推荐权重使用逐帧模式。
    axes = (1, 2) if mode == "per_sample_rms" else None
    with np.errstate(over="ignore", under="ignore", invalid="ignore"):
        scale = np.sqrt(np.mean(values**2, axis=axes, keepdims=True))
    # 正常幅度沿用历史 float32 运算，避免改变已有模型的输入。
    # 有限的 float32 输入平方/求和仍可能溢出，极小值也可能下溢；仅异常尺度
    # 回退到 float64，防止“有效大信号 / inf”静默变为全零。
    unstable = ~np.isfinite(scale) | (scale < np.sqrt(np.finfo(np.float32).tiny))
    if np.any(unstable):
        # 逐帧模式只修复异常帧：一帧异常或全零，不应改变同批正常帧的舍入结果。
        selected = unstable[:, 0, 0] if axes is not None else None
        wide = (values[selected] if selected is not None else values).astype(np.float64)
        wide_axes = (1, 2) if axes is not None else None
        wide_scale = np.sqrt(np.mean(wide**2, axis=wide_axes, keepdims=True))
        # 极端动态范围下，小分量转回 float32 可能自然舍入为零，允许这种下溢。
        with np.errstate(under="ignore"):
            repaired = (wide / np.maximum(wide_scale, epsilon)).astype(np.float32)
        if selected is None:
            return repaired
        output = np.empty_like(values)
        np.divide(values, np.maximum(scale, epsilon), out=output, where=~unstable)
        output[selected] = repaired
        return output
    # epsilon 防止全零帧除零；归一化只消除幅度尺度，不执行载波或符号同步。
    return values / np.maximum(scale, epsilon)


def preprocess_signals(signals: np.ndarray, mode: str = "per_sample_rms") -> np.ndarray:
    processed = normalize_iq(signals, mode=mode)
    validate_signals(processed)
    return processed.astype(np.float32, copy=False)

