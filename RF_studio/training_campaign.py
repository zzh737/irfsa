"""Batch training capture ("campaign"): segments, sweeps, point list, checks, progress, resume.

No GUI and no hardware. A campaign is a list of segments. Each segment is a
sweep: dimensions with one or more values (one value = fixed for that
segment), plus its own repeat count. Points of a segment = its value
combinations x its repeats; its share of the campaign is only displayed. The GUI turns each point into parameter
values, uploads them, waits the dead time and runs the existing training capture.

The campaign file (schema KU5P_TRAINING_CAMPAIGN_2) is rewritten atomically
after every point, so an interruption loses at most the point in progress.
"""
from __future__ import annotations

import itertools
import json
import math
import os
import random
import uuid
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

SCHEMA = 'KU5P_TRAINING_CAMPAIGN_2'
OLD_SCHEMA = 'KU5P_TRAINING_CAMPAIGN_1'
FILE_NAME = 'campaign_{id}.json'
# Per point, before anything is measured: upload, RX restart, START/STOP, finalisation.
DEFAULT_SWITCH_S = 6.0
DEFAULT_DEAD_S = 1.0
# Heuristic, not measured on this board: AGC needs time to settle after a retune.
AGC_MIN_DEAD_S = 1.0
MAX_POINTS = 100_000
MANUAL = '手动增益'
GAIN_MODES = {'manual': MANUAL, 'mgc': MANUAL, 'slow': '慢速 AGC', 'fast': '快速 AGC'}
RATE_1M, RATE_25M = '1 MSPS · FIR 抽取', '25 MSPS · 原始采样'
RATES = {'1': RATE_1M, '1m': RATE_1M, '25': RATE_25M, '25m': RATE_25M}
RX_BWS = ('0.2', '0.5', '1', '2', '5', '10', '15', '20')
FILTER_OFF, FILTER_ON = '关闭', '开启'

# kind: 'mod' checklist, 'num' numeric (+ special words), 'choice' fixed list.
DIMENSIONS = {
    'modulation': dict(label='调制方式', short='调制', kind='mod'),
    'snr': dict(label='内部 SNR / dB', short='SNR', kind='num', low=-10, high=20, words=('off',)),
    'bandwidth': dict(label='基带带宽 / MHz', short='基带带宽', kind='num', low=.005, high=10),
    'offset': dict(label='频偏 / MHz', short='频偏', kind='num', low=-10, high=10),
    'atten1': dict(label='TX1 衰减 / dB', short='TX1 衰减', kind='num', low=0, high=89.75, step=.25),
    'atten2': dict(label='TX2 衰减 / dB', short='TX2', kind='num', low=0, high=89.75, step=.25, words=('off',)),
    'center': dict(label='TX 本振 / MHz', short='TX 本振', kind='num', low=300, high=6000),
    'rx_lo': dict(label='RX 本振 − TX 本振 / MHz', short='RX 本振', kind='num', low=-100, high=100, words=('follow',)),
    'rx_bandwidth': dict(label='RX 模拟带宽 / MHz', short='RX 带宽', kind='choice', choices=RX_BWS),
    'rx_gain_mode': dict(label='RX 增益模式', short='增益模式', kind='choice', choices=(MANUAL, '慢速 AGC', '快速 AGC'),
                         aliases=GAIN_MODES),
    'rx_gain': dict(label='RX 手动增益 / dB', short='手动增益', kind='num', low=-10, high=73, step=1),
    'train_rate': dict(label='采样率', short='采样率', kind='choice', choices=(RATE_1M, RATE_25M), aliases=RATES),
    # PC-side RX filter on/off; its type and edges are the training-page settings.
    'rx_filter': dict(label='RX 滤波器（参数取观测区设置）', short='滤波', kind='choice', choices=(FILTER_OFF, FILTER_ON),
                      aliases={'off': FILTER_OFF, '0': FILTER_OFF, 'on': FILTER_ON, '1': FILTER_ON}),
}
ORDER = tuple(DIMENSIONS)          # outer → inner loop order inside a segment
LEVELS = ('error', 'warning', 'info')


class CampaignError(ValueError):
    pass


def fmt(v):
    """Numeric value as a GUI string with up to 6 decimals (1 Hz at MHz units)."""
    s = f'{float(v):.6f}'.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def parse_value(dim, text):
    """One sweep value from user text, returned in GUI units (or a special word)."""
    spec = DIMENSIONS[dim]
    text = str(text).strip()
    if not text:
        raise CampaignError(f'{spec["label"]}：有档位未填写。')
    if spec['kind'] == 'mod':
        from ui_parameters import UI_MODES
        match = next((m for m in UI_MODES if m.upper() == text.upper()), None)
        if match is None:
            raise CampaignError(f'未知调制方式“{text}”。')
        return match
    if spec['kind'] == 'choice':
        if text in spec['choices']:
            return text
        alias = spec.get('aliases', {}).get(text.lower())
        if alias:
            return alias
        raise CampaignError(f'{spec["label"]}：“{text}”不是可选值（{" / ".join(spec["choices"])}）。')
    if text.lower() in spec.get('words', ()):
        return text.lower()
    try:
        v = float(text)
    except ValueError:
        extra = '（或 ' + '/'.join(spec['words']) + '）' if spec.get('words') else ''
        raise CampaignError(f'{spec["label"]}：“{text}”不是数值{extra}。') from None
    if not math.isfinite(v) or not spec['low'] <= v <= spec['high']:
        raise CampaignError(f'{spec["label"]}：{text} 超出 {spec["low"]:g}～{spec["high"]:g}。')
    step = spec.get('step')
    if step and abs(v / step - round(v / step)) > 1e-9:
        raise CampaignError(f'{spec["label"]}：{text} 须为 {step:g} 的整数倍。')
    return fmt(v)


def short(dim, v):
    if dim == 'modulation':
        return v
    if dim == 'snr':
        return 'SNR ' + v
    if dim == 'bandwidth':
        return f'BW {v}M'
    if dim == 'offset':
        return f'频偏 {v}M'
    if dim == 'atten1':
        return f'TX1 {v}dB'
    if dim == 'atten2':
        return 'TX2 off' if v == 'off' else f'TX2 {v}dB'
    if dim == 'center':
        return f'LO {v}M'
    if dim == 'rx_lo':
        return 'RX 跟随' if v == 'follow' else f'RX {float(v):+g}M'
    if dim == 'rx_bandwidth':
        return f'RXBW {v}M'
    if dim == 'rx_gain_mode':
        return {MANUAL: '手动'}.get(v, v.replace('速 AGC', 'AGC'))
    if dim == 'rx_gain':
        return f'G {v}dB'
    if dim == 'train_rate':
        return '25M' if v.startswith('25') else '1M'
    if dim == 'rx_filter':
        return '滤波开' if v == FILTER_ON else '滤波关'
    return v


@dataclass
class Point:
    index: int
    segment: int
    values: dict          # dimension -> value for the swept dimensions of its segment
    repeat: int
    seed: int
    state: str = 'pending'    # pending | recording | done | failed
    attempts: int = 0
    files: list = None
    error: str = ''
    started: str = ''
    finished: str = ''

    def label(self):
        parts = [short(d, self.values[d]) for d in ORDER if d in self.values]
        if self.repeat:
            parts.append(f'#{self.repeat + 1}')
        return ' · '.join(parts) or '（全部取固定参数）'

    def as_dict(self):
        return dict(index=self.index, segment=self.segment, values=self.values, repeat=self.repeat, seed=self.seed,
                    state=self.state, attempts=self.attempts, files=self.files or [], error=self.error,
                    started=self.started, finished=self.finished)


def combos(sweep, base):
    """Unique value combinations of one segment, outer dimension first.

    Under AGC the manual gain is not used, so combinations that differ only in
    rx_gain collapse into one. Returns (combinations, number merged).
    """
    dims = [d for d in ORDER if d in sweep]
    for d in dims:
        if not sweep[d]:
            raise CampaignError(f'{DIMENSIONS[d]["label"]}：至少需要一个档位。')
        if len(set(sweep[d])) != len(sweep[d]):
            raise CampaignError(f'{DIMENSIONS[d]["label"]}：档位有重复值。')
    out, seen, merged = [], set(), 0
    for vals in itertools.product(*(sweep[d] for d in dims)):
        v = dict(zip(dims, vals))
        if v.get('rx_gain_mode', base.get('rx_gain_mode')) != MANUAL:
            v.pop('rx_gain', None)
        key = tuple(sorted(v.items()))
        if key in seen:
            merged += 1
            continue
        seen.add(key)
        out.append(v)
    return out, merged


def point_values(point, base):
    """GUI parameter values for one point: the locked base draft plus this point's values."""
    v = dict(base)
    pv = point.values
    for dim, val in pv.items():
        if dim == 'rx_lo':
            continue
        if dim == 'snr':
            if val == 'off':
                v['tx1_noise'] = '0'
            else:
                v['snr'], v['tx1_noise'] = val, '1'
        elif dim == 'atten2':
            if val != 'off':
                v['atten2'] = val
        elif dim == 'rx_filter':
            v['rx_filter'] = '1' if val == FILTER_ON else '0'
        else:
            v[dim] = val
    if 'rx_lo' in pv:
        if pv['rx_lo'] == 'follow':
            v['rx_follow'] = '1'
        else:
            v['rx_follow'] = '0'
            v['rx_center'] = fmt(float(v['center']) + float(pv['rx_lo']))
    if v.get('rx_follow') == '1':
        v['rx_center'] = v['center']
    v['seed'] = f'0x{point.seed:08X}'
    return v


def point_tx2(point, definition):
    """TX2 on/off for this point; None = leave it as it is (campaign files from schema 1)."""
    if 'atten2' in point.values:
        return point.values['atten2'] != 'off'
    return definition.get('tx2_default')


def point_fs(values):
    return 25_000_000 if values['train_rate'].startswith('25') else 1_000_000


class Campaign:
    def __init__(self, definition, base, points, directory, campaign_id=None, created=None, path=None):
        self.definition = definition
        self.base = base                  # locked GUI draft (all parameters not swept)
        self.points = points
        self.directory = Path(directory)
        self.id = campaign_id or datetime.now().strftime('%Y%m%d_%H%M%S_') + uuid.uuid4().hex[:6]
        self.created = created or datetime.now().isoformat(timespec='seconds')
        self.path = Path(path) if path else self.directory / FILE_NAME.format(id=self.id)
        self.overheads = []               # measured seconds per point beyond the capture length
        self.elapsed = 0.0                # active seconds across sessions

    # ---- construction --------------------------------------------------
    @classmethod
    def create(cls, segments, base, *, seconds, dead_time=DEFAULT_DEAD_S, seed_mode='increment', seed_step=1,
               shuffle=False, tag='', retries=1, tx2_default=False, directory):
        """segments: [{name, repeats, sweep}]. Points of a segment = its combinations x its repeats."""
        if not segments:
            raise CampaignError('至少需要一个段。')
        parsed = []
        for i, seg in enumerate(segments):
            name = (seg.get('name') or '').strip() or f'段 {i + 1}'
            try:
                sweep = {d: [parse_value(d, t) for t in vals] for d, vals in (seg.get('sweep') or {}).items() if vals is not None}
                cs, merged = combos(sweep, base)
            except CampaignError as exc:
                raise CampaignError(f'{name}：{exc}') from None
            text = str(seg.get('repeats', '1')).strip()
            try:
                repeats = int(text)
            except ValueError:
                raise CampaignError(f'{name}：重复次数“{text}”不是整数。') from None
            if not 1 <= repeats <= 1000:
                raise CampaignError(f'{name}：重复次数须在 1～1000。')
            parsed.append(dict(name=name, sweep=sweep, combos=cs, merged=merged, repeats=repeats))
        try:
            seconds = float(seconds)
            dead_time = float(dead_time)
        except (TypeError, ValueError):
            raise CampaignError('每点时长和死区时间须为数值。') from None
        if not math.isfinite(seconds) or not 0 < seconds <= 86400:
            raise CampaignError('每点时长须在 0～86400 秒之间。')
        if not math.isfinite(dead_time) or not 0 <= dead_time <= 600:
            raise CampaignError('死区时间须在 0～600 秒之间。')
        total = sum(len(p['combos']) * p['repeats'] for p in parsed)
        if total > MAX_POINTS:
            raise CampaignError(f'总点数 {total} 超过上限 {MAX_POINTS}。')
        try:
            base_seed = int(base['seed'], 0)
        except (KeyError, ValueError):
            raise CampaignError('随机种子无效。') from None
        if not 0 < base_seed < 2**32:
            raise CampaignError('随机种子须为非零 u32。')
        notes, points = [], []
        for s, p in enumerate(parsed):
            if p['merged']:
                notes.append(('info', 'merged', f'{p["name"]}：AGC 下手动增益无效，合并了 {p["merged"]} 个重复组合'))
            for combo in p['combos']:
                for r in range(p['repeats']):
                    points.append(Point(0, s, dict(combo), r, 0))
        shuffle_seed = base_seed if shuffle else None
        if shuffle:
            random.Random(shuffle_seed).shuffle(points)
        step = int(seed_step) if seed_mode == 'increment' else 0
        for k, pt in enumerate(points):
            pt.index = k
            pt.seed = base_seed if not step else (base_seed - 1 + k * step) % 0xFFFFFFFF + 1
        definition = dict(
            segments=[dict(name=p['name'], repeats=p['repeats'], sweep=p['sweep'], combos=len(p['combos']),
                           points=len(p['combos']) * p['repeats'], merged=p['merged']) for p in parsed],
            seconds=seconds, dead_time=dead_time, seed_mode=seed_mode, seed_step=step, base_seed=base_seed,
            shuffle=bool(shuffle), shuffle_seed=shuffle_seed, tag=tag, retries=int(retries),
            tx2_default=bool(tx2_default), notes=notes)
        return cls(definition, dict(base), points, directory)

    # ---- persistence ---------------------------------------------------
    def to_dict(self):
        return dict(schema=SCHEMA, id=self.id, created=self.created, saved=datetime.now().isoformat(timespec='seconds'),
                    directory=str(self.directory), definition=self.definition, base=self.base,
                    overheads=self.overheads[-50:], elapsed_seconds=round(self.elapsed, 1),
                    summary=self.summary(), points=[p.as_dict() for p in self.points])

    def save(self, path=None):
        """Atomic: write <name>.tmp, fsync, rename over the target."""
        path = Path(path) if path else self.path
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_name(path.name + '.tmp')
        with tmp.open('w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, ensure_ascii=False, indent=1)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
        return path

    @classmethod
    def load(cls, path):
        path = Path(path)
        try:
            doc = json.loads(path.read_text(encoding='utf-8'))
        except (OSError, ValueError) as exc:
            raise CampaignError(f'无法读取任务文件：{exc}') from None
        if doc.get('schema') == OLD_SCHEMA:
            doc = _upgrade(doc)
        elif doc.get('schema') != SCHEMA:
            raise CampaignError('不是 KU5P 训练批量任务文件。')
        doc = _normalize(doc)
        points = [Point(p['index'], p.get('segment', 0), p['values'], p['repeat'], p['seed'], p['state'],
                        p.get('attempts', 0), p.get('files') or [], p.get('error', ''), p.get('started', ''),
                        p.get('finished', '')) for p in doc['points']]
        c = cls(doc['definition'], doc['base'], points, doc['directory'], doc['id'], doc['created'], path)
        c.overheads = list(doc.get('overheads', []))
        c.elapsed = float(doc.get('elapsed_seconds', 0))
        return c

    # ---- resume verification ------------------------------------------
    def verify(self):
        """Re-check every 'done' point on disk. Returns list of (index, reason) reset to pending.

        A point stays done only if each listed capture has its .iq, .index.bin and a
        finalised, not-excluded .json. 'recording' (interrupted) always goes back to pending.
        """
        reset = []
        for p in self.points:
            if p.state == 'recording':
                p.state = 'pending'
                reset.append((p.index, '上次中断时正在录制'))
                continue
            if p.state != 'done':
                continue
            reason = '' if p.files else '没有记录文件'
            for stem in p.files or []:
                base = Path(stem)
                missing = [ext for ext in ('.iq', '.index.bin', '.json') if not base.with_suffix(ext).exists()]
                if missing:
                    reason = '缺少文件 ' + ','.join(missing)
                    break
                try:
                    meta = json.loads(base.with_suffix('.json').read_text(encoding='utf-8'))
                except (OSError, ValueError):
                    reason = 'JSON 无法读取'
                    break
                if meta.get('recording_state') != 'finalized':
                    reason = '录制未正常收尾'
                    break
                excluded = [r for r in meta.get('automatic_label_exclusion_reasons', []) if r != 'offline_demo_not_RF_training_data']
                if excluded:
                    reason = '已被排除：' + ','.join(excluded)
                    break
            if reason:
                p.state = 'pending'
                reset.append((p.index, reason))
        return reset

    # ---- progress ------------------------------------------------------
    def counts(self):
        out = dict(pending=0, recording=0, done=0, failed=0)
        for p in self.points:
            out[p.state] = out.get(p.state, 0) + 1
        return out

    def overhead(self):
        recent = self.overheads[-20:]
        return sum(recent) / len(recent) if recent else DEFAULT_SWITCH_S + float(self.definition.get('dead_time', 0))

    def remaining_seconds(self):
        left = sum(1 for p in self.points if p.state in ('pending', 'recording'))
        return left * (self.definition['seconds'] + self.overhead())

    def total_seconds(self):
        return len(self.points) * (self.definition['seconds'] + self.overhead())

    def bytes_needed(self):
        """Disk for every point not yet done (IQ + index, 2 % margin)."""
        seconds = self.definition['seconds']
        return sum(point_fs(point_values(p, self.base)) * 4 * seconds * 1.02 for p in self.points if p.state != 'done')

    def summary(self):
        return dict(total=len(self.points), **self.counts(), remaining_seconds=round(self.remaining_seconds()))

    def next_point(self):
        return next((p for p in self.points if p.state == 'pending'), None)

    def failed_points(self):
        return [p for p in self.points if p.state == 'failed']

    def segment_name(self, point):
        segs = self.definition['segments']
        return segs[point.segment]['name'] if point.segment < len(segs) else f'段 {point.segment + 1}'


def segment_shares(definition):
    """[(points, percent of all points)] per segment."""
    pts = [s['points'] for s in definition['segments']]
    total = sum(pts)
    return [(n, 100 * n / total if total else 0) for n in pts]


def _upgrade(doc):
    """Schema 1 (single sweep, repeats) → schema 2 (one segment, repeat mode)."""
    d = doc['definition']
    repeats = int(d.get('repeats', 1))
    seg = dict(name='段 1', repeats=repeats, sweep=d['sweep'], combos=max(1, len(doc['points']) // repeats),
               points=len(doc['points']), merged=0)
    doc['definition'] = dict(segments=[seg], seconds=d['seconds'],
                             dead_time=DEFAULT_DEAD_S, seed_mode=d.get('seed_mode', 'increment'),
                             seed_step=d.get('seed_step', 1), base_seed=d.get('base_seed', 1), shuffle=False,
                             shuffle_seed=None, tag=d.get('tag', ''), retries=d.get('retries', 1),
                             tx2_default=None, notes=[])
    doc['base'].setdefault('train_rate', RATE_25M if d.get('fs') == 25_000_000 else RATE_1M)
    doc['schema'] = SCHEMA
    return doc


def _normalize(doc):
    """Files from the earlier percent-based layout: keep their point list, record a repeat count."""
    for seg in doc['definition']['segments']:
        if 'repeats' not in seg:
            combos_n = max(1, seg.get('combos', 1))
            seg['repeats'] = max(1, round(seg.get('points', combos_n) / combos_n))
        seg.pop('percent', None)
    for key in ('total_mode', 'total_value'):
        doc['definition'].pop(key, None)
    return doc


# ---- checks ------------------------------------------------------------
TITLES = dict(
    band_reject='TX1 频带超出 RX 带宽，录制时会被拒绝',
    band_dc='TX1 频带跨过 RX 本振，DC 跟踪会挖掉频带中心',
    carrier_dc='载波落在 RX 本振 ±1 kHz 内，会被 DC 跟踪去掉',
    agc_dead=f'AGC 模式下死区时间短于 {AGC_MIN_DEAD_S:g} s，增益可能尚未收敛（经验值，未实测）',
    disk='磁盘剩余空间不足',
    filter_invalid='RX 滤波器参数在该点采样率下无效',
    filter_cuts='TX1 频带不完全在 RX 滤波器通带内，标签信号会被部分滤除',
    filter_load='RX 滤波器处理负载高，录制时可能丢窗（丢窗会在控制台报 error）',
)


@dataclass
class Issue:
    level: str
    code: str
    title: str
    indices: list
    example: str = ''

    def text(self):
        n = len(self.indices)
        if not n:
            return self.title + (f'：{self.example}' if self.example else '')
        ex = '、'.join(f'#{i + 1}' for i in self.indices[:8]) + ('…' if n > 8 else '')
        tail = f'。例：{self.example}' if self.example and self.example != self.title else ''
        return f'{self.title}：{n} 点（{ex}）{tail}'


def check(campaign, free_bytes=None):
    """Every point through the same rules the capture applies, grouped by problem.

    error: the point cannot be recorded (invalid parameters, band rejected, disk).
    warning: it can be recorded but the data is degraded (DC notch, AGC settling).
    info: notes from building the point list (merged combinations).
    """
    from backend import waveform
    from band_check import check as band_check
    from training_capture import verify_training_band
    from ui_parameters import rx_firmware_reason, validate_rx
    groups = {}

    def add(level, code, title, index=None, example=''):
        g = groups.setdefault((level, code, title), Issue(level, code, title, [], example))
        if index is not None:
            g.indices.append(index)

    dead = float(campaign.definition.get('dead_time', 0))
    for p in campaign.points:
        v = point_values(p, campaign.base)
        try:
            config = waveform(v)
            validate_rx(v)
            reason = rx_firmware_reason(v)
            if reason:
                raise ValueError(reason)
        except (ValueError, OverflowError) as exc:
            add('error', 'invalid', '参数无效：' + str(exc), p.index)
            continue
        regs = config.plan()['registers']
        word = regs[6] if regs[6] < 2**31 else regs[6] - 2**32
        offset = word * 25_000_000 / 2**32   # carrier for every modulation (firmware >= 23)
        rx_lo = config.center_hz if v['rx_follow'] == '1' else round(float(v['rx_center']) * 1e6)
        fs = point_fs(v)
        try:
            verify_training_band(dict(tx=dict(registers=regs, bandwidth_hz=config.bandwidth_hz),
                                      tx1_center_hz=config.center_hz + offset,
                                      rx=dict(lo_hz=rx_lo, bandwidth_hz=float(v['rx_bandwidth']) * 1e6, fs_hz=fs)))
        except ValueError as exc:
            add('error', 'band_reject', TITLES['band_reject'], p.index, str(exc))
        # band_check looks at the observation rate; a capture uses the training rate.
        for f in band_check(dict(v, rate=v['train_rate'])):
            if f.code in ('band_dc', 'carrier_dc'):
                add('warning', f.code, TITLES[f.code], p.index, f.text)
        if v['rx_gain_mode'] != MANUAL and dead < AGC_MIN_DEAD_S:
            add('warning', 'agc_dead', TITLES['agc_dead'], p.index)
        if v.get('rx_filter') == '1':
            import rx_filter
            from ui_parameters import filter_spec
            try:
                spec = filter_spec(v, fs)
                info = rx_filter.plan(spec, fs)
            except rx_filter.FilterError as exc:
                add('error', 'filter_invalid', TITLES['filter_invalid'], p.index, str(exc))
                continue
            from training_capture import band_from_registers
            low, high = band_from_registers(regs, config.bandwidth_hz, config.center_hz + offset - rx_lo)
            if not rx_filter.passband_contains(spec, low / 1e3, high / 1e3):
                add('warning', 'filter_cuts', TITLES['filter_cuts'], p.index,
                    f'TX1 {low / 1e3:g}～{high / 1e3:g} kHz，{spec.label()}')
            if info['load'] >= .7:
                add('warning', 'filter_load', TITLES['filter_load'], p.index,
                    f"{fs / 1e6:g} MSPS · N={info['n']} · 实测负载 {info['load'] * 100:.0f}%")
    for level, code, text in campaign.definition.get('notes', []):
        add(level, code, text)
    if free_bytes is not None:
        need = campaign.bytes_needed()
        if need > free_bytes:
            add('error', 'disk', TITLES['disk'], None, f'需要约 {need / 1e9:.2f} GB，剩余 {free_bytes / 1e9:.2f} GB')
    return sorted(groups.values(), key=lambda g: LEVELS.index(g.level))


# ---- overview ----------------------------------------------------------
def sweep_summary(sweep):
    if not sweep:
        return '（不扫描，全部取固定参数）'
    return ' · '.join(f'{DIMENSIONS[d]["short"]} ' + ','.join(_brief(d, v) for v in sweep[d]) for d in ORDER if d in sweep)


def _brief(dim, v):
    if dim == 'rx_gain_mode':
        return short(dim, v)
    if dim == 'train_rate':
        return short(dim, v)
    if dim == 'rx_lo' and v != 'follow':
        return f'{float(v):+g}'
    return v


def describe_fixed(campaign):
    """Parameters no segment sweeps, as recorded in the campaign base."""
    b, d = campaign.base, campaign.definition
    swept = {k for s in d['segments'] for k in s['sweep']}
    parts = []
    if 'modulation' not in swept:
        parts.append('调制 ' + b['modulation'])
    if 'center' not in swept:
        parts.append(f'TX 本振 {b["center"]} MHz')
    if 'bandwidth' not in swept:
        parts.append(f'基带带宽 {b["bandwidth"]} MHz')
    if 'offset' not in swept:
        parts.append(f'频偏 {b["offset"]} MHz')
    if 'snr' not in swept:
        parts.append('SNR off' if b.get('tx1_noise') == '0' else f'SNR {b["snr"]} dB')
    if 'atten1' not in swept:
        parts.append(f'TX1 衰减 {b["atten1"]} dB')
    if 'atten2' not in swept:
        tx2 = d.get('tx2_default')
        parts.append('TX2 保持原状' if tx2 is None else (f'TX2 开 · {b["atten2"]} dB' if tx2 else 'TX2 关'))
    if 'rx_lo' not in swept:
        parts.append('RX 跟随 TX 本振' if b.get('rx_follow') == '1' else f'RX 本振 {b["rx_center"]} MHz')
    if 'rx_bandwidth' not in swept:
        parts.append(f'RX 带宽 {b["rx_bandwidth"]} MHz')
    if 'rx_gain_mode' not in swept:
        mode = b['rx_gain_mode']
        parts.append(mode + (f' {b["rx_gain"]} dB' if mode == MANUAL and 'rx_gain' not in swept else ''))
    elif 'rx_gain' not in swept:
        parts.append(f'手动增益 {b["rx_gain"]} dB（手动模式时）')
    if 'train_rate' not in swept:
        parts.append('采样率 ' + short('train_rate', b['train_rate']).replace('M', ' MSPS'))
    if 'rx_filter' not in swept:
        parts.append(filter_text(b) if b.get('rx_filter') == '1' else 'RX 滤波关')
    elif any(s['sweep'].get('rx_filter') for s in d['segments']):
        parts.append('滤波参数 ' + filter_text(b, prefix=False))
    return ' · '.join(parts) or '（全部参数都在扫描）'


def filter_text(values, prefix=True):
    t = values.get('filter_type', 'BPF')[:3]
    band = (f"fc {values.get('filter_f1')} kHz" if t in ('LPF', 'HPF')
            else f"{values.get('filter_f1')}～{values.get('filter_f2')} kHz")
    text = f"{t} {band} · Ap {values.get('filter_ripple')} dB · As {values.get('filter_stop')} dB · Δf {values.get('filter_transition')} kHz"
    return ('RX 滤波 ' if prefix else '') + text


def overview_lines(campaign, issues):
    """(tag, text) lines for the pre-start overview. tag: head/info/muted/ok/warning/error."""
    d = campaign.definition
    n = len(campaign.points)
    left = sum(1 for p in campaign.points if p.state != 'done')
    out = [('head', '批量采集总览')]
    out.append(('info', f'总点数 {n}' + (f'（待录 {left}）' if left != n else '')
                + f' · 预计 {format_duration(campaign.remaining_seconds())} · 磁盘约 {campaign.bytes_needed() / 1e9:.2f} GB'))
    seed = f'每点 +1（起始 0x{d["base_seed"]:08X}）' if d.get('seed_step') else f'固定 0x{d["base_seed"]:08X}'
    out.append(('info', f'每点 {d["seconds"]:g} s · 死区 {d["dead_time"]:g} s'
                + f' · 顺序 {"打乱" if d.get("shuffle") else "按段、按调制分组"} · 种子 {seed}'))
    out.append(('head', '分段（点数 = 组合数 × 重复次数）'))
    for s, (pts, share) in zip(d['segments'], segment_shares(d)):
        out.append(('info', f'{s["name"]} · {s["combos"]} 个组合 × {s.get("repeats", "?")} 次 = {pts} 点 · 占 {share:.1f}%'))
        out.append(('muted', '    ' + sweep_summary(s['sweep'])))
    out.append(('head', '固定参数（各段都未扫描的项）'))
    out.append(('info', describe_fixed(campaign)))
    out.append(('head', '检查'))
    if not issues:
        out.append(('ok', '未发现问题。'))
    for it in issues:
        out.append((it.level, f'[{it.level}] ' + it.text()))
    out.append(('head', '前 20 点'))
    for p in campaign.points[:20]:
        out.append(('muted', f'#{p.index + 1:<5}{campaign.segment_name(p)} · {p.label()}'))
    if n > 20:
        out.append(('muted', f'…… 共 {n} 点'))
    return out


def format_duration(seconds):
    seconds = max(0, int(round(seconds)))
    h, rest = divmod(seconds, 3600)
    m, s = divmod(rest, 60)
    return f'{h}:{m:02d}:{s:02d}' if h else f'{m:02d}:{s:02d}'
