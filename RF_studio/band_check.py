"""TX1 occupied band versus what RX1 actually delivers. Pure functions, no I/O.

Board facts (2026-10-30 measurements, firmware 19):
- AD9361 BB/RF DC tracking (0x18B=0xAD) is a ~110 Hz high-pass at the RX LO.
  A linear-modulation band that straddles the RX LO loses its centre: 200 kHz
  256QAM/PSK EVM ~5 % at offset 0/10 kHz versus 1.7 % at 150 kHz.
- The 1 MSPS path (two 5:1 FIRs) is flat to +/-400 kHz, stop band from 500 kHz.
- The 25 MSPS path is limited by the RX analog bandwidth setting.
"""
from __future__ import annotations

from dataclasses import dataclass

from ui_parameters import planner_mode
from waveform_config import occupied_band

DC_GUARD_HZ = 1_000            # ~10x the DC-tracking corner
FIR_PASS_HZ = 400_000          # 1 MSPS decimator pass band (one-sided)
FIR_STOP_HZ = 500_000          # 1 MSPS decimator stop band / Nyquist
CARRIER_MODES = ('AM-DSB-WC', 'AM-SSB-WC')


@dataclass(frozen=True)
class Finding:
    level: str      # 'warning' | 'error'
    code: str
    text: str


def tx1_band(values):
    """(low, high) of TX1 relative to the TX LO, in Hz.

    Firmware >= 23: offset = carrier, bandwidth = one-sided baseband B; the band is
    offset ± B (SSB: offset..offset+B for USB, offset-B..offset for LSB)."""
    return occupied_band(planner_mode(values['modulation']), float(values['bandwidth']) * 1e6,
                         float(values['offset']) * 1e6, 'LSB' if values.get('sideband', '').startswith('LSB') else 'USB')


def rx_window(values):
    """One-sided usable RX band in Hz around the RX LO for the selected IQ rate."""
    rx_bw = float(values['rx_bandwidth']) * 1e6
    if values['rate'].startswith('1 '):
        return min(FIR_PASS_HZ, rx_bw / 2), FIR_STOP_HZ
    return rx_bw / 2, 12_500_000


def check(values):
    """Findings for the current draft. values: the GUI StringVar snapshot."""
    try:
        tx_lo = float(values['center']) * 1e6
        rx_lo = tx_lo if values.get('rx_follow') == '1' else float(values['rx_center']) * 1e6
        low, high = tx1_band(values)
        passband, stopband = rx_window(values)
    except (KeyError, ValueError, TypeError):
        return []
    # TX1 band expressed relative to the RX LO.
    low += tx_lo - rx_lo
    high += tx_lo - rx_lo
    mode = values['modulation']
    out = []
    span = f'{low/1e3:+.1f}～{high/1e3:+.1f} kHz'
    if high <= -stopband or low >= stopband:
        out.append(Finding('error', 'band_outside',
            f'TX1 频带 {span}（相对 RX 本振）完全在 RX 可用带宽 ±{passband/1e3:g} kHz 之外，RX 收不到 TX1。'))
        return out
    if low < -passband or high > passband:
        out.append(Finding('warning', 'band_edge',
            f'TX1 频带 {span} 超出 RX 平坦带宽 ±{passband/1e3:g} kHz，带边会被滤掉或衰减。'
            + ('请改用 25 MSPS 或减小频偏/带宽。' if values['rate'].startswith('1 ') else '请加大 RX 模拟带宽或减小频偏。')))
    if low < DC_GUARD_HZ and high > -DC_GUARD_HZ:
        if mode.endswith(('ASK', 'PSK', 'QAM')):
            need = (high - low) / 2 + DC_GUARD_HZ
            out.append(Finding('warning', 'band_dc',
                f'TX1 频带 {span} 跨过 RX 本振（0 Hz）。AD9361 DC 跟踪约 110 Hz 高通会挖掉频带中心，'
                f'实测 200 kHz QAM/PSK EVM 约 5%（离开 DC 后约 1.7%）。建议 |频偏| ≥ {need/1e3:.0f} kHz，或令 RX 本振与 TX 错开。'))
        else:
            # Analog modes: offset is the carrier (or FM centre) for every modulation.
            carrier = float(values['offset']) * 1e6 + tx_lo - rx_lo
            if mode in CARRIER_MODES + ('FM',) and abs(carrier) < DC_GUARD_HZ:
                out.append(Finding('warning', 'carrier_dc',
                    f'TX1 载波落在 RX 本振 ±{DC_GUARD_HZ/1e3:g} kHz 内，会被 DC 跟踪去掉（实测约 −44 dB）。建议频偏 ≥ 1 kHz。'))
    return out
