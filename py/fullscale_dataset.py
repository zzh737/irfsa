"""读取 KU5P 实采 IQ；以采集记录为单位隔离数据，禁止相邻帧跨集合。"""
from __future__ import annotations

import collections
import hashlib
import json
from pathlib import Path
import zlib

import numpy as np

INDEX_DTYPE = np.dtype([('seq', '>u4'), ('capture', '>u4'), ('sample', '>u8'),
                        ('offset', '>u8'), ('fs', '>u4'), ('gain', '>i4'),
                        ('flags', '>u2'), ('reserved', '>u2'), ('crc', '>u4')])


def digest(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def write_json(path, value):
    path = Path(path)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False), encoding='utf-8')
    temporary.replace(path)


def scan_recordings(root, minimum_bandwidth=60000):
    records, excluded = [], []
    for path in sorted(Path(root).glob('TRAIN*.json')):
        d = json.loads(path.read_text(encoding='utf-8-sig'))
        config = d['capture_configuration']
        tx = config['tx']
        reason = None
        if tx['bandwidth_hz'] < minimum_bandwidth:
            reason = 'bandwidth_below_threshold'
        elif (d.get('exclude_from_automatic_labeling', True)
              or not d.get('configuration_consistent', False)
              or d.get('recording_state') != 'finalized'):
            reason = 'invalid_recording_metadata'
        if reason:
            excluded.append({'metadata': str(path), 'reason': reason})
            continue
        expected_format = 'little-endian interleaved int16 I,Q; original ADC scale, no normalization'
        # v3 同时提供接收端原始记录和 PC FIR 滤波记录；二者仍是相同的
        # int16 IQ 窗口格式，滤波说明只出现在 metadata 的附加后缀中。
        if (d['fs_hz'] != 1000000 or d['points_per_window'] != 1024
                or d['index_record_bytes'] != INDEX_DTYPE.itemsize
                or not d['format'].startswith(expected_format)):
            raise ValueError(f'Unsupported format: {path}')
        if not (d['label'] == config['label'] == config['configured_modulation'] == d['tx']['modulation']):
            raise ValueError(f'Conflicting labels: {path}')
        iq, index = path.with_suffix('.iq'), path.with_suffix('.index.bin')
        if iq.stat().st_size != d['file_bytes'] or index.stat().st_size % INDEX_DTYPE.itemsize:
            raise ValueError(f'Truncated recording: {path}')
        entries = np.fromfile(index, dtype=INDEX_DTYPE)
        if (not len(entries) or len(entries) * 4096 != iq.stat().st_size
                or not np.array_equal(entries['offset'], np.arange(len(entries), dtype=np.uint64) * 4096)
                or not np.all(entries['fs'] == d['fs_hz'])
                or not np.all(entries['capture'] == d['capture_id'])
                or len(np.unique(entries['sample'])) != len(entries)):
            raise ValueError(f'Invalid index: {path}')
        valid = np.flatnonzero(entries['flags'] == 0)
        if len(valid) < 256:
            raise ValueError(f'Too few unflagged frames: {path}')
        # 抽检首、中、末有效帧的 CRC；其余帧保留索引校验，报告抽检范围。
        raw = np.memmap(iq, mode='r', dtype=np.uint8, shape=(len(entries), 4096))
        for row in valid[np.linspace(0, len(valid) - 1, 3, dtype=int)]:
            if zlib.crc32(raw[row].tobytes()) != int(entries['crc'][row]):
                raise ValueError(f'CRC mismatch: {iq}, row={row}')
        del raw
        records.append({'metadata': str(path.resolve()), 'iq': str(iq.resolve()),
                        'metadata_sha256': digest(path), 'index_sha256': digest(index),
                        'iq_bytes': iq.stat().st_size, 'iq_mtime_ns': iq.stat().st_mtime_ns,
                        'label': d['label'], 'bandwidth_hz': tx['bandwidth_hz'],
                        'snr_setting': str(d['campaign']['values']['snr']),
                        'tx_snr_db': float(tx['snr_db']), 'rx_gain_mdB': d['rx_gain_mdB'],
                        'attenuation1_db': tx['attenuation1_db'], 'seed': int(tx['seed']),
                        'campaign_id': d['campaign']['id'], 'capture_id': d['capture_id'],
                        'boot_id': d['boot_id'], 'frames': len(entries),
                        'valid_frames': len(valid), 'flagged_frames': len(entries) - len(valid)})
    if not records:
        raise ValueError('No eligible recordings')
    return records, excluded


def split_recordings(records, seed):
    """每个类别/带宽/TX SNR 设置的四段记录，分成 2/1/1 段。"""
    groups = collections.defaultdict(list)
    for i, record in enumerate(records):
        groups[(record['label'], record['bandwidth_hz'], record['snr_setting'])].append(i)
    rng = np.random.default_rng(seed)
    for key in sorted(groups):
        group = groups[key]
        if len(group) < 4:
            raise ValueError(f'Need >=4 independent recordings per stratum: {key}')
        order = rng.permutation(group)
        for position, i in enumerate(order):
            records[int(i)]['split'] = 'validation' if position == 0 else 'test' if position == 1 else 'train'
    # 同一个波形随机种子或同一采集 ID 不可出现在不同集合。
    for key_fn in (lambda r: r['seed'], lambda r: (r['boot_id'], r['capture_id'])):
        seen = {}
        for r in records:
            key = key_fn(r)
            if key in seen and seen[key] != r['split']:
                raise ValueError(f'Duplicate source across splits: {key}')
            seen[key] = r['split']
    return records


def read_frames(record, rows):
    path = Path(record['iq'])
    if path.stat().st_size != record['iq_bytes'] or path.stat().st_mtime_ns != record['iq_mtime_ns']:
        raise ValueError(f'Source changed: {path}')
    raw = np.memmap(path, mode='r', dtype='<i2', shape=(record['frames'], 1024, 2))
    return np.ascontiguousarray(raw[rows].transpose(0, 2, 1))


def valid_rows(record):
    entries = np.fromfile(Path(record['metadata']).with_suffix('.index.bin'), dtype=INDEX_DTYPE)
    return np.flatnonzero(entries['flags'] == 0)


def sample_split(records, split, count, seed):
    """每轮训练重新抽帧；验证抽样固定；count=0 表示全部有效帧。"""
    rng = np.random.default_rng(seed)
    members = [(i, r) for i, r in enumerate(records) if r['split'] == split]
    total = sum(min(count, r['valid_frames']) if count else r['valid_frames'] for _, r in members)
    signals = np.empty((total, 2, 1024), dtype=np.int16)
    labels = np.empty(total, dtype=np.int64)
    record_ids = np.empty(total, dtype=np.int32)
    source_rows = np.empty(total, dtype=np.int32)
    classes = sorted({r['label'] for r in records})
    cursor = 0
    for i, r in members:
        valid = valid_rows(r)
        rows = np.sort(rng.choice(valid, min(count, len(valid)), replace=False)) if count else valid
        end = cursor + len(rows)
        signals[cursor:end] = read_frames(r, rows)
        labels[cursor:end] = classes.index(r['label'])
        record_ids[cursor:end], source_rows[cursor:end] = i, rows
        cursor = end
    return signals, labels, record_ids, source_rows
