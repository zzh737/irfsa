"""PC-side RX channel filter: linear-phase FIR on the complex baseband (NumPy only).

Specification, all frequencies in kHz relative to the RX LO (complex baseband):
    LPF / HPF   signed cutoff fc: passband f <= fc (LPF) or f >= fc (HPF), one-sided
    BPF / BSF   signed edges f1 < f2: passband f1..f2 (BPF) or stopband f1..f2 (BSF)
    Ap          passband ripple, peak-to-peak dB, 0.01 dB resolution
    As          minimum stopband attenuation, dB
    Δf          transition bandwidth; the stopband starts Δf outside (LPF/BPF) or inside
                (HPF/BSF) each edge, so the stated edges are true passband edges

The complex spectrum wraps at ±fs/2, so LPF/HPF are bands that end at fs/2 and
have a second transition, Δf wide and centred on ±fs/2, excluded from both bands.

Design: Kaiser-window method on the ideal complex response, sized for min(δp, δs)
so that Ap and As are both met. BSF is δ[n] − BPF of the same odd length:
one linear-phase FIR whose group delay (N−1)/2 is an integer number of samples.

Streaming: FFT overlap-save. Several blocks are batched and transformed in a thread
pool (NumPy FFTs release the GIL), which is the multi-core path. Group delay is
removed, so filtered window k lines up with received window k (same sample_index).
A window is only emitted when every tap of every output sample saw real received
samples; windows within N−1 samples of the start, the end or a gap are dropped.
"""
from __future__ import annotations

import hashlib
import math
import os
import time
from collections import deque
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass

import numpy as np

TYPES = {'LPF': '低通 LPF', 'HPF': '高通 HPF', 'BPF': '带通 BPF', 'BSF': '带阻 BSF'}
MAX_TAPS = 65535
# At 25 MSPS PC filtering starved UDP reception on the board (2026-10-31: ~1000 lost
# windows/s for any filter length, 39 per 5 s without), so it is limited to 1 MSPS.
MAX_FS = 1_000_000
RATE_LIMIT_TEXT = '25 MSPS 下不支持 PC 端 RX 滤波（实板接收会丢窗），请改用 1 MSPS 或关闭滤波。'
WINDOW_POINTS = 1024
FULL_SCALE = 2047


class FilterError(ValueError):
    pass


@dataclass(frozen=True)
class FilterSpec:
    kind: str              # LPF / HPF / BPF / BSF
    f1_khz: float          # LPF/HPF: cutoff fc (signed); BPF/BSF: lower edge (signed)
    f2_khz: float          # BPF/BSF: upper edge (signed); 0 for LPF/HPF
    ripple_db: float       # Ap, peak-to-peak
    stop_db: float         # As
    transition_khz: float  # Δf

    def band_text(self):
        if self.kind in ('LPF', 'HPF'):
            return f'fc = {self.f1_khz:g} kHz'
        return f'{self.f1_khz:g}～{self.f2_khz:g} kHz'

    def label(self):
        return f'{TYPES[self.kind]} {self.band_text()} · Ap {self.ripple_db:.2f} dB · As {self.stop_db:g} dB · Δf {self.transition_khz:g} kHz'

    def token(self):
        """Filename token, e.g. FiltBPF-0to300k-Ap0p01-As60-Tw20k ('m' = minus)."""
        def n(v):
            return f'{v:.3f}'.rstrip('0').rstrip('.').replace('-', 'm').replace('.', 'p')
        band = n(self.f1_khz) + ('' if self.kind in ('LPF', 'HPF') else 'to' + n(self.f2_khz)) + 'k'
        return f'Filt{self.kind}-{band}-Ap{n(self.ripple_db)}-As{n(self.stop_db)}-Tw{n(self.transition_khz)}k'


def parse_spec(kind, f1, f2, ripple, stop, transition, fs):
    """Validate GUI strings against the sample rate; returns a FilterSpec."""
    kind = str(kind).strip().upper()[:3]
    if kind not in TYPES:
        raise FilterError('滤波器类型须为 LPF / HPF / BPF / BSF。')
    try:
        f1, ripple, stop, transition = (float(x) for x in (f1, ripple, stop, transition))
        f2 = float(f2) if kind in ('BPF', 'BSF') else 0.
    except (TypeError, ValueError):
        raise FilterError('滤波器参数须为数值。') from None
    if not all(math.isfinite(x) for x in (f1, f2, ripple, stop, transition)):
        raise FilterError('滤波器参数须为有限数值。')
    if abs(ripple * 100 - round(ripple * 100)) > 1e-6 or not .01 <= ripple <= 3:
        raise FilterError('通带纹波 Ap 须在 0.01～3 dB，分辨率 0.01 dB。')
    ripple = round(ripple, 2)
    if not 20 <= stop <= 120:
        raise FilterError('阻带衰减 As 须在 20～120 dB。')
    if fs > MAX_FS:
        raise FilterError(RATE_LIMIT_TEXT)
    nyq = fs / 2e3
    if not 0 < transition < nyq:
        raise FilterError(f'过渡带宽 Δf 须大于 0 且小于 {nyq:g} kHz（fs/2）。')
    if kind in ('LPF', 'HPF'):
        # ±fs/2 is a second edge with a Δf transition centred on it.
        low, high = -nyq + transition / 2, nyq - transition / 2
        if kind == 'LPF' and not (low < f1 and f1 + transition < high):
            raise FilterError(f'低通：须 {low:g} < fc 且 fc + Δf < {high:g} kHz（相对本振，±fs/2 处另有 Δf/2 过渡带）。')
        if kind == 'HPF' and not (low < f1 - transition and f1 < high):
            raise FilterError(f'高通：须 fc − Δf > {low:g} 且 fc < {high:g} kHz（相对本振，±fs/2 处另有 Δf/2 过渡带）。')
    else:
        if not -nyq <= f1 < f2 <= nyq:
            raise FilterError(f'边沿须满足 −{nyq:g} ≤ f1 < f2 ≤ {nyq:g} kHz（相对本振）。')
        if kind == 'BSF' and f2 - f1 <= 2 * transition:
            raise FilterError('带阻：阻带宽度 f2 − f1 须大于 2Δf。')
    return FilterSpec(kind, f1, f2, ripple, stop, transition)


def _kaiser_beta(a):
    if a > 50:
        return .1102 * (a - 8.7)
    if a >= 21:
        return .5842 * (a - 21) ** .4 + .07886 * (a - 21)
    return 0.


def required_taps(spec, fs):
    """Kaiser order estimate (odd) before designing; used for a fast pre-check."""
    dp = (10 ** (spec.ripple_db / 20) - 1) / (10 ** (spec.ripple_db / 20) + 1)
    a = -20 * math.log10(min(dp, 10 ** (-spec.stop_db / 20)))
    dw = 2 * math.pi * spec.transition_khz * 1e3 / fs
    n = math.ceil((a - 8) / (2.285 * dw)) + 1
    return n + 1 - n % 2, a


def design(spec, fs, extra=0):
    """Complex linear-phase FIR taps (complex128)."""
    n, a = required_taps(spec, fs)
    n += 2 * extra
    if n > MAX_TAPS:
        raise FilterError(f'所需阶数 N={n} 超过上限 {MAX_TAPS}；请加大过渡带宽 Δf，或放宽通带纹波 Ap / 阻带衰减 As。')
    m = np.arange(n) - (n - 1) / 2
    window = np.kaiser(n, _kaiser_beta(a))
    df = spec.transition_khz * 1e3

    def band(lo, hi):
        """Ideal complex band lo..hi Hz, cut at the transition centres, windowed."""
        centre, width = (lo + hi) / 2, hi - lo
        return width / fs * np.sinc(width / fs * m) * np.exp(2j * math.pi * centre / fs * m) * window

    impulse = np.zeros(n, complex)
    impulse[(n - 1) // 2] = 1
    f1, f2 = spec.f1_khz * 1e3, spec.f2_khz * 1e3
    if spec.kind == 'LPF':
        return band(-fs / 2, f1 + df / 2)
    if spec.kind == 'HPF':
        return band(f1 - df / 2, fs / 2)
    if spec.kind == 'BPF':
        return band(f1 - df / 2, f2 + df / 2)
    return impulse - band(f1 + df / 2, f2 - df / 2)


def measured_response(h, spec, fs):
    """Achieved passband ripple (pk-pk dB) and minimum stopband attenuation (dB)."""
    size = 1 << max(16, int(math.ceil(math.log2(len(h) * 16))))
    f = np.fft.fftshift(np.fft.fftfreq(size, 1 / fs))
    mag = np.abs(np.fft.fftshift(np.fft.fft(h, size)))
    f1, f2, df = spec.f1_khz * 1e3, spec.f2_khz * 1e3, spec.transition_khz * 1e3
    inner = np.abs(f) <= fs / 2 - df / 2       # outside the transition centred on ±fs/2
    if spec.kind == 'LPF':
        passband, stopband = inner & (f <= f1), inner & (f >= f1 + df)
    elif spec.kind == 'HPF':
        passband, stopband = inner & (f >= f1), inner & (f <= f1 - df)
    elif spec.kind == 'BPF':
        passband, stopband = (f >= f1) & (f <= f2), (f <= f1 - df) | (f >= f2 + df)
    else:
        passband, stopband = (f <= f1) | (f >= f2), (f >= f1 + df) & (f <= f2 - df)
    p = mag[passband]
    ripple = 20 * math.log10(p.max() / p.min()) if p.size and p.min() > 0 else float('inf')
    stop = -20 * math.log10(max(float(mag[stopband].max()), 1e-15)) if stopband.any() else float('inf')
    return ripple, stop


_PLAN_CACHE = {}


def measure_load(info, fs):
    """Run the real streaming filter on ~3 batches of noise; seconds used per second of IQ."""
    samples = max(3 * info['batch'] * info['block'], WINDOW_POINTS * 64)
    windows = -(-samples // WINDOW_POINTS)
    raw = np.random.default_rng(0).integers(-300, 300, 2 * WINDOW_POINTS, dtype=np.int16).tobytes()
    f = StreamFilter(info)
    try:
        f.push(0, raw, None)                       # warm up threads and FFT plans
        f.busy_s = 0.
        for s in range(1, windows + 1):
            f.push(s, raw, None)
        return f.busy_s / (windows * WINDOW_POINTS / fs)
    finally:
        f.close()


def default_workers():
    """Leave cores for the GUI, the receive loop, analysis and model processes."""
    return max(1, min(8, (os.cpu_count() or 2) - 4))


def plan(spec, fs, workers=None):
    """Taps, achieved response and processing load (fraction of real time, 1.0 = saturated)."""
    workers = workers or default_workers()
    key = (spec, fs, workers)
    if key in _PLAN_CACHE:
        return _PLAN_CACHE[key]
    h = design(spec, fs)
    ripple, stop = measured_response(h, spec, fs)
    # The Kaiser estimate can miss Ap/As by a little; grow the filter until it meets both.
    for extra in (4, 16, 64, 256):
        if ripple <= spec.ripple_db + 1e-9 and stop >= spec.stop_db - 1e-9:
            break
        try:
            h = design(spec, fs, extra)
        except FilterError:
            break
        ripple, stop = measured_response(h, spec, fs)
    n = len(h)
    # Large blocks amortise the per-call cost (~20 ms of IQ per block, at least 4N).
    fft = 1 << int(min(18, max(13, math.ceil(math.log2(max(4 * n, fs * .02))))))
    fft = max(fft, 1 << int(math.ceil(math.log2(2 * n))))
    block = fft - (n - 1)
    # Batch blocks across threads, but keep added latency near 100 ms for the display.
    batch = max(1, min(workers, int(fs * .1 // block)))
    # complex64 keeps a numerical floor near −130 dB; use double precision for As > 90 dB.
    dtype = np.complex128 if spec.stop_db > 90 else np.complex64
    info = dict(taps=h, n=n, fft=fft, block=block, batch=batch, group_delay=(n - 1) // 2, dtype=dtype,
                ripple_db=ripple, stop_db=stop, workers=workers,
                meets=ripple <= spec.ripple_db + 1e-9 and stop >= spec.stop_db - 1e-9,
                latency_s=((n - 1) / 2 + batch * block) / fs)
    info['load'] = measure_load(info, fs)
    if len(_PLAN_CACHE) > 32:
        _PLAN_CACHE.clear()
    _PLAN_CACHE[key] = info
    return info


def describe(info, fs):
    """One-line design summary for the GUI."""
    text = (f"N = {info['n']} 阶线性相位 FIR · 实测通带纹波 {info['ripple_db']:.3f} dB · 阻带衰减 {info['stop_db']:.1f} dB · "
            f"群时延 {info['group_delay'] / fs * 1e3:.3g} ms（已补偿）· 实测处理负载 {info['load'] * 100:.0f}%（{info['workers']} 线程）")
    return text if info['meets'] else text + ' · 未完全达到指标'


def metadata(spec, info, fs):
    digest = hashlib.sha256(np.ascontiguousarray(info['taps'].astype(np.complex128)).tobytes()).hexdigest()
    return dict(schema='KU5P_RX_FILTER_1', name=TYPES[spec.kind], **asdict(spec), fs_hz=fs,
                design='Kaiser-window linear-phase complex FIR, odd length', taps=info['n'],
                group_delay_samples=info['group_delay'], group_delay_compensated=True,
                measured_passband_ripple_db=round(info['ripple_db'], 4),
                measured_stopband_attenuation_db=round(info['stop_db'], 2),
                specification_met=bool(info['meets']), taps_sha256=digest,
                frequency_reference='kHz relative to the RX LO (complex baseband)',
                output_scale='int16 at the raw ADC code scale (unity passband gain), saturated to -2048..2047',
                dropped_windows='windows whose filter span is not fully covered by received samples '
                                '(start, end, both sides of a gap) are not written; sample_index keeps the gap')


def passband_contains(spec, low_khz, high_khz):
    """True if low..high (kHz relative to the RX LO) lies entirely in the passband."""
    if spec.kind == 'LPF':
        return high_khz <= spec.f1_khz
    if spec.kind == 'HPF':
        return low_khz >= spec.f1_khz
    if spec.kind == 'BPF':
        return spec.f1_khz <= low_khz and high_khz <= spec.f2_khz
    return high_khz <= spec.f1_khz or low_khz >= spec.f2_khz


class StreamFilter:
    """Overlap-save FIR over consecutive 1024-point windows, group delay removed.

    push() returns [(seq, filtered_raw, meta)] in order. Output window w (the w-th
    since the last reset) is input window w filtered; it is emitted only when all of
    its taps saw real input. Blocks are batched so several FFTs run in parallel.
    """

    def __init__(self, info, workers=None):
        self.n, self.fft, self.block, self.delay = info['n'], info['fft'], info['block'], info['group_delay']
        self.dtype = info['dtype']
        self.taps = info['taps']
        self.H = np.fft.fft(self.taps, self.fft).astype(self.dtype)
        self.H_small = {}
        self.workers = workers or info['workers']
        self.pool = ThreadPoolExecutor(self.workers, thread_name_prefix='rxfilter') if self.workers > 1 else None
        self.batch = info['batch'] * self.block
        self.busy_s = 0.
        self.dropped = 0          # windows not written: start/end/gap transients
        self.saturated = 0        # output samples clipped to the ADC code range
        self.restarts = 0         # resets at a sequence gap inside the stream
        self.reset()

    def reset(self):
        self.tail = np.zeros(self.n - 1, self.dtype)   # last n−1 inputs already transformed
        self.raw = []                                  # received window bytes, not yet converted
        self.rest = np.zeros(0, self.dtype)            # converted, not yet transformed
        self.data_len = 0                              # samples in raw + rest
        self.conv = np.zeros(0, self.dtype)            # convolution output from conv_base on
        self.conv_base = 0
        self.real = 0                                  # real samples received since reset
        self.next_window = 0
        self.windows = deque()                         # (seq, meta) not yet emitted
        self.last = None

    def close(self):
        if self.pool:
            self.pool.shutdown(wait=False, cancel_futures=True)

    def push(self, seq, raw, meta):
        started = time.perf_counter()
        out = []
        if self.last is not None and seq != self.last + 1:
            out = self._drain()
            self.reset()
            self.restarts += 1
        self.last = seq
        # Per-window work is kept to list appends; conversion and output are per batch.
        self.raw.append(raw)
        self.data_len += len(raw) // 4
        self.real += len(raw) // 4
        self.windows.append((seq, meta))
        if self.data_len >= self.batch:
            self._transform_blocks(pad=False)
            out += self._emit()
        self.busy_s += time.perf_counter() - started
        return out

    def drain(self):
        """End of stream: emit what is complete, count the rest as dropped."""
        started = time.perf_counter()
        out = self._drain()
        self.busy_s += time.perf_counter() - started
        return out

    def _drain(self):
        self._transform_blocks(pad=True)
        out = self._emit()
        self.dropped += len(self.windows)
        self.windows = deque()
        return out

    def _one(self, x):
        return np.fft.ifft(np.fft.fft(x, self.fft) * self.H)[self.n - 1:]

    def _samples(self):
        """All received samples not yet transformed, converted in one step."""
        if self.raw:
            x = np.frombuffer(b''.join(self.raw), '<i2').astype(np.float32).view(np.complex64)
            x = x.astype(self.dtype, copy=False)
            self.raw = []
            self.rest = np.concatenate([self.rest, x]) if len(self.rest) else x
        return self.rest

    def _spectrum(self, size):
        if size not in self.H_small:
            self.H_small[size] = np.fft.fft(self.taps, size).astype(self.dtype)
        return self.H_small[size]

    def _transform_blocks(self, pad):
        blocks = self.data_len // self.block
        partial = pad and self.data_len % self.block
        if not blocks and not partial:
            return
        data = self._samples()
        take = blocks * self.block
        outs = []
        if blocks:
            full = np.concatenate([self.tail, data[:take]])
            jobs = [full[i * self.block:i * self.block + self.fft] for i in range(blocks)]
            outs = list(self.pool.map(self._one, jobs)) if self.pool and blocks > 1 else [self._one(j) for j in jobs]
            self.tail = full[len(full) - (self.n - 1):].copy()
        rest = data[take:]
        if partial:
            # End of a segment (gap or stop): a FFT sized to what is left, not a padded full block,
            # so frequent gaps cost little. Only outputs covered by real input are computed.
            x = np.concatenate([self.tail, rest])
            size = 1 << int(math.ceil(math.log2(len(x))))
            outs.append(np.fft.ifft(np.fft.fft(x, size) * self._spectrum(size))[self.n - 1:len(x)])
            self.tail = x[len(x) - (self.n - 1):].copy()
            rest = rest[:0]
        self.conv = np.concatenate([self.conv] + outs)
        self.rest = rest.copy() if len(rest) else np.zeros(0, self.dtype)
        self.data_len = len(self.rest)

    def _emit(self):
        # Aligned output k = conv[k + delay]; conv[j] uses inputs j−n+1 .. j.
        while self.windows and self.next_window * WINDOW_POINTS < self.delay:
            # Its first samples need inputs from before the stream started.
            self.windows.popleft()
            self.next_window += 1
            self.dropped += 1
        # Window w is complete once (w + 1)·1024 + delay outputs exist and saw real input.
        limit = min(self.conv_base + len(self.conv), self.real) - self.delay
        k = min(len(self.windows), max(0, limit // WINDOW_POINTS - self.next_window))
        if not k:
            return []
        start = self.next_window * WINDOW_POINTS + self.delay - self.conv_base
        y = self.conv[start:start + k * WINDOW_POINTS]
        self.conv = self.conv[start + k * WINDOW_POINTS:]
        self.next_window += k
        self.conv_base = self.next_window * WINDOW_POINTS + self.delay
        r = y.astype(np.complex64, copy=False).view(np.float32)
        np.rint(r, out=r)                      # in place: conv before this point is not used again
        if r.min() < -FULL_SCALE - 1 or r.max() > FULL_SCALE:
            self.saturated += int(np.count_nonzero((r < -FULL_SCALE - 1) | (r > FULL_SCALE)))
            np.clip(r, -FULL_SCALE - 1, FULL_SCALE, out=r)
        data = r.astype('<i2').tobytes()
        size = 4 * WINDOW_POINTS
        out = []
        for i in range(k):
            seq, meta = self.windows.popleft()
            out.append((seq, data[i * size:(i + 1) * size], meta))
        return out
