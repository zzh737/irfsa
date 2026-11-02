"""Deterministic Q1.15 reference FFT for the FMQL30TAI PL work package.

Pure Python, deliberately independent of Procise/iCraft and third-party packages.
Arithmetic conventions are documented in ../spec.md.
"""

from __future__ import annotations

import math
from typing import Iterable, Sequence

N = 1024
Q15 = 32767
INT16_MIN = -32768
INT16_MAX = 32767


def _round_div_symmetric(numerator: int, denominator: int) -> int:
    """Round a signed ratio to nearest integer, ties away from zero."""
    if denominator <= 0:
        raise ValueError("denominator must be positive")
    sign = -1 if numerator < 0 else 1
    magnitude = abs(numerator)
    return sign * ((magnitude + denominator // 2) // denominator)


def _sat16(value: int) -> int:
    return max(INT16_MIN, min(INT16_MAX, value))


def _quantize_q15(value: float) -> int:
    magnitude = int(math.floor(abs(value) * Q15 + 0.5))
    return max(INT16_MIN, min(INT16_MAX, -magnitude if value < 0 else magnitude))


def _mul_q15(a: int, b: int) -> int:
    return _sat16(_round_div_symmetric(a * b, Q15))


def hann_q15(length: int = N) -> list[int]:
    if length <= 0:
        raise ValueError("length must be positive")
    if length == 1:
        return [Q15]
    return [_quantize_q15(0.5 - 0.5 * math.cos(2 * math.pi * i / (length - 1))) for i in range(length)]


def _bit_reverse(value: int, bits: int) -> int:
    result = 0
    for _ in range(bits):
        result = (result << 1) | (value & 1)
        value >>= 1
    return result


def _complex_mul_q15(ar: int, ai: int, br: int, bi: int) -> tuple[int, int]:
    real = _round_div_symmetric(ar * br - ai * bi, Q15)
    imag = _round_div_symmetric(ar * bi + ai * br, Q15)
    return _sat16(real), _sat16(imag)


def fft_q15(samples: Sequence[Sequence[int]], window: str = "hann") -> list[tuple[int, int]]:
    """Return 1024 scaled complex FFT bins in natural order."""
    if len(samples) != N:
        raise ValueError(f"expected exactly {N} IQ samples")
    if window not in {"hann", "rectangular"}:
        raise ValueError("window must be 'hann' or 'rectangular'")
    iq: list[tuple[int, int]] = []
    coefficients = hann_q15() if window == "hann" else None
    for index, pair in enumerate(samples):
        if len(pair) != 2:
            raise ValueError("each sample must be an [I, Q] pair")
        i, q = int(pair[0]), int(pair[1])
        if not (INT16_MIN <= i <= INT16_MAX and INT16_MIN <= q <= INT16_MAX):
            raise ValueError("IQ input must fit signed int16")
        if coefficients is not None:
            i = _mul_q15(i, coefficients[index])
            q = _mul_q15(q, coefficients[index])
        iq.append((i, q))

    bits = N.bit_length() - 1
    work = [iq[_bit_reverse(index, bits)] for index in range(N)]
    span = 2
    while span <= N:
        half = span // 2
        for base in range(0, N, span):
            for offset in range(half):
                angle = -2.0 * math.pi * offset / span
                wr = _quantize_q15(math.cos(angle))
                wi = _quantize_q15(math.sin(angle))
                ar, ai = work[base + offset]
                br, bi = work[base + offset + half]
                tr, ti = _complex_mul_q15(br, bi, wr, wi)
                work[base + offset] = (
                    _sat16(_round_div_symmetric(ar + tr, 2)),
                    _sat16(_round_div_symmetric(ai + ti, 2)),
                )
                work[base + offset + half] = (
                    _sat16(_round_div_symmetric(ar - tr, 2)),
                    _sat16(_round_div_symmetric(ai - ti, 2)),
                )
        span *= 2
    return work


def power_spectrum(samples: Sequence[Sequence[int]], window: str = "hann") -> list[int]:
    """Return unsigned integer power bins in natural FFT order."""
    return [real * real + imag * imag for real, imag in fft_q15(samples, window)]


def make_case(name: str, seed: int = 260914) -> list[list[int]]:
    """Build a deterministic input stimulus using only the standard library."""
    import random

    rng = random.Random(seed)
    if name == "zero":
        return [[0, 0] for _ in range(N)]
    if name == "impulse":
        return [[Q15, 0] if index == 0 else [0, 0] for index in range(N)]
    if name == "dc":
        return [[4096, -2048] for _ in range(N)]
    if name == "nyquist":
        return [[12000 if index % 2 == 0 else -12000, 0] for index in range(N)]
    if name == "tone_bin_37":
        return [[int(round(12000 * math.cos(2 * math.pi * 37 * index / N))),
                 int(round(9000 * math.sin(2 * math.pi * 37 * index / N)))] for index in range(N)]
    if name == "two_tone":
        return [[int(round(7000 * math.cos(2 * math.pi * 23 * index / N) + 5000 * math.cos(2 * math.pi * 181 * index / N))),
                 int(round(6500 * math.sin(2 * math.pi * 23 * index / N) - 4500 * math.sin(2 * math.pi * 181 * index / N)))] for index in range(N)]
    if name == "noise":
        return [[rng.randint(-12000, 12000), rng.randint(-12000, 12000)] for _ in range(N)]
    if name == "near_full_scale":
        return [[32767 if index & 1 else -32768, 32767 if index & 2 else -32768] for index in range(N)]
    raise ValueError(f"unknown test case: {name}")


def cases() -> Iterable[str]:
    return ("zero", "impulse", "dc", "nyquist", "tone_bin_37", "two_tone", "noise", "near_full_scale")
