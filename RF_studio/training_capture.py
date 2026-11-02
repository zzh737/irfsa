"""Read-back based labels and filenames for training captures; no RF writes."""
from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime
from pathlib import Path


def tx_signature(tx):
    """Only configuration fields: counters/high-water marks change normally."""
    return {key: tx[key] for key in (
        'center_hz', 'bandwidth_hz', 'snr_db', 'attenuation1_db', 'attenuation2_db',
        'noise_low_hz', 'noise_high_hz', 'seed', 'registers', 'applied_mask', 'requested_mask')}


def verify_training_tx(tx, expected_config=None, expected_mask=None, demo=False):
    if not tx.get('seed') or tx.get('modulation') is None:
        raise ValueError('训练采集需要已应用的波形配置，请先应用参数。')
    if not tx['applied_mask'] & 1:
        raise ValueError('训练采集需要 TX1 已开启，避免给背景数据误贴调制标签。')
    if tx['requested_mask'] != tx['applied_mask']:
        raise ValueError('TX 开关尚未读回一致，请刷新状态后重试。')
    flags = tx['radio_flags']
    # UDP handshake/START and validated IQ determine receive availability.
    # HW06's MDIO link bit can be clear even when UDP is functional.
    if not flags & 2 or flags & 24:
        raise ValueError('射频未就绪或存在数据故障，不能开始训练采集。')
    if expected_mask is not None and tx['applied_mask'] != expected_mask:
        raise ValueError('板端 TX 开关已变化，请刷新并确认后重新开始。')
    if expected_config is not None:
        c = expected_config
        wanted = dict(center_hz=c.center_hz, bandwidth_hz=c.bandwidth_hz,
                      snr_db=round(c.snr_db * 1000) / 1000,
                      attenuation1_db=c.tx1_attenuation_db, attenuation2_db=c.tx2_attenuation_db,
                      noise_low_hz=c.noise_low_hz, noise_high_hz=c.noise_high_hz,
                      seed=c.seed, registers=c.plan()['registers'])
        if wanted['registers'][0] not in (0,7,8):
            wanted['registers'][14] = tx['registers'][14]  # AM depth is inactive outside AM.
        if any(tx[k] != value for k, value in wanted.items()):
            raise ValueError('编辑参数与板端已应用配置不一致。请先应用参数并开启 TX1，'
                             '或点击“填入板上参数”后重新开始；不会自动应用或发射。')


def configuration_snapshot(tx, fs, demo, rx=None, rx_filter=None):
    # JSON round-trip detaches lists from status objects and guarantees serializability.
    signature = json.loads(json.dumps(tx_signature(tx)))
    regs = signature['registers']
    offset_word = regs[6] if regs[6] < 2**31 else regs[6] - 2**32
    # Firmware >= 23: register 6 is the carrier for every modulation.
    offset_hz = offset_word * 25_000_000 / 2**32
    if rx is None:
        if not demo:raise ValueError('训练配置缺少实际 RX 参数，请先设置接收中心。')
        rx=dict(lo_hz=tx['center_hz'],rx_bandwidth_hz=20_000_000,rx_gain_mdB=10000)
    value=lambda key:rx[key] if isinstance(rx,dict) else getattr(rx,key)
    rx_lo=value('lo_hz')
    rx_bw=value('rx_bandwidth_hz')
    rx_gain=value('rx_gain_mdB')
    gain_mode=(rx.get('gain_mode',(rx.get('status_flags',0)>>3)&3) if isinstance(rx,dict) else getattr(rx,'gain_mode',(getattr(rx,'status_flags',0)>>3)&3))
    if gain_mode:rx_gain=-2147483648
    config = dict(schema='KU5P_TRAINING_CAPTURE_1', tx=signature,
                  configured_modulation=tx['modulation'], label=tx['modulation'],
                  label_source='TX1 configuration readback; received signal not independently classified',
                  simulated=bool(demo), tx1_enabled=bool(tx['applied_mask'] & 1),
                  tx2_enabled=bool(tx['applied_mask'] & 2),
                  lo_hz=tx['center_hz'], tx1_offset_hz=offset_hz,
                  tx1_center_hz=tx['center_hz'] + offset_hz,
                  tx2_noise_low_relative_hz=tx['noise_low_hz'],
                  tx2_noise_high_relative_hz=tx['noise_high_hz'],
                  am_depth=regs[14] / 32768 if tx['modulation'] in ('AM','AM-DSB-WC') else None,
                  rx=dict(fs_hz=fs, adc_sample_rate_hz=25_000_000, decimation=25_000_000 // fs,
                          lo_hz=rx_lo, bandwidth_hz=rx_bw, gain_mdB=rx_gain,gain_mode=gain_mode,
                          automatic_gain_varies=bool(gain_mode)),
                  tx1_internal_noise=bool(regs[11]),
                  snr_definition=('TX1 internal digital SNR; received SNR/SINR is not measured' if regs[11]
                                  else 'TX1 internal noise disabled (snr_db not applied); received SNR/SINR is not measured'))
    # PC-side RX filter is part of the labelled configuration and of its hash; the key
    # is absent without a filter so unfiltered snapshots keep their previous hash.
    if rx_filter is not None:
        from dataclasses import asdict
        from rx_filter import passband_contains
        low, high = tx1_band_relative(config)
        config['rx_filter'] = dict(asdict(rx_filter), tx1_band_in_passband=passband_contains(rx_filter, low / 1e3, high / 1e3))
    # Firmware >= 23: tx1_offset_hz/tx1_center_hz are the carrier and tx.bandwidth_hz is the
    # one-sided baseband bandwidth. Files recorded before firmware 23 lack these keys.
    low_lo, high_lo = band_from_registers(regs, tx['bandwidth_hz'], offset_hz)
    config.update(baseband_bandwidth_hz=tx['bandwidth_hz'], rf_bandwidth_hz=high_lo - low_lo,
                  tx1_band_relative_lo_hz=[low_lo, high_lo],
                  bandwidth_definition='one-sided baseband bandwidth B; RF occupancy 2B, SSB B (firmware >= 23)',
                  tx1_offset_definition='carrier relative to the TX LO (firmware >= 23)')
    canonical = json.dumps(config, sort_keys=True, separators=(',', ':'), ensure_ascii=True)
    config['configuration_sha256'] = hashlib.sha256(canonical.encode('ascii')).hexdigest()
    return config


def band_from_registers(regs, baseband_hz, carrier_hz):
    """(low, high) around the carrier: ±B; SSB USB carrier..+B, LSB -B..carrier (register 15 bit 0)."""
    if regs[0] in (7, 8):
        return (carrier_hz - baseband_hz, carrier_hz) if regs[15] & 1 else (carrier_hz, carrier_hz + baseband_hz)
    return carrier_hz - baseband_hz, carrier_hz + baseband_hz


def tx1_band_relative(config):
    """TX1 occupied band (low, high) in Hz relative to the RX LO."""
    carrier = config['tx1_center_hz'] - config['rx']['lo_hz']
    return band_from_registers(config['tx']['registers'], config['tx']['bandwidth_hz'], carrier)


def verify_training_band(config):
    # The board's /25 path has a documented nominal passband of LO +/-400 kHz.
    edge=max(abs(e) for e in tx1_band_relative(config))
    limit=min(config['rx']['bandwidth_hz']/2,400_000 if config['rx']['fs_hz']==1_000_000 else 10_000_000)
    if edge>limit:
        if config['rx']['fs_hz']==1_000_000:
            raise ValueError('1 MSPS 抽取通带约为 LO ±400 kHz，当前 TX1 频段超出通带。'
                             '请选择 25 MSPS，或缩小带宽/频偏并重新应用参数。')
        raise ValueError('TX1 信号超出当前 RX 接收频段，请调整接收中心或发射频偏。')


def validate_tag(tag):
    tag = tag.strip()
    if len(tag) > 24 or (tag and not re.fullmatch(r'[\w\-]+', tag, flags=re.UNICODE)):
        raise ValueError('实验备注最多 24 字，只使用汉字、字母、数字、下划线或连字符。')
    return tag


def training_basename(config, tag='', stamp=None):
    tag = validate_tag(tag)
    tx = config['tx']
    def number(value):
        return f'{value:.6f}'.rstrip('0').rstrip('.').replace('.', 'p')
    tokens = ['DEMO_TRAIN' if config['simulated'] else 'TRAIN', config['label'],
              'F' + number(tx['center_hz'] / 1e6) + 'M',
              'BW' + number(tx['bandwidth_hz'] / 1e6) + 'M',
              'Fs' + number(config['rx']['fs_hz'] / 1e6) + 'M',
              ('SNR' + number(tx['snr_db'])) if tx['registers'][11] else 'SNRoff',
              'T1ON-A' + number(tx['attenuation1_db']),
              ('T2ON-A' if config['tx2_enabled'] else 'T2OFF-A') + number(tx['attenuation2_db']),
              'N' + number(tx['noise_low_hz'] / 1e6) + 'to' + number(tx['noise_high_hz'] / 1e6) + 'M',
              'O' + number(config['tx1_offset_hz'] / 1e6) + 'M',
              'Seed' + f"{tx['seed']:08X}"]
    if config['rx']['lo_hz']!=tx['center_hz']:
        tokens.append('RxF'+number(config['rx']['lo_hz']/1e6)+'M')
    tokens.append('AGC'+str(config['rx'].get('gain_mode',0)) if config['rx'].get('gain_mode') else 'RxG'+number(config['rx']['gain_mdB']/1000))
    if config['am_depth'] is not None:
        tokens.append('D' + number(config['am_depth']))
    if config.get('rx_filter'):
        from rx_filter import FilterSpec
        f = config['rx_filter']
        tokens.append(FilterSpec(f['kind'], f['f1_khz'], f['f2_khz'], f['ripple_db'], f['stop_db'], f['transition_khz']).token())
    tokens += ['C' + config['configuration_sha256'][:8],
               stamp or datetime.now().strftime('%Y%m%d_%H%M%S%f')]
    if tag:
        tokens.append(tag)
    return '_'.join(tokens)


def training_path(directory, config, tag=''):
    path = Path(directory) / training_basename(config, tag)
    if len(str(path.with_suffix('.index.bin'))) > 259:
        raise ValueError('自动命名后的路径过长，请选择更短的保存目录或缩短实验备注。')
    return path
