"""Single-owner radio worker. No Tk access occurs outside the UI thread."""
from __future__ import annotations
from collections import deque
import ipaddress
import json
import math
import os
import queue
import re
import select
import socket
import struct
import sys
import threading
import time
import zlib
from dataclasses import asdict
from datetime import datetime
from pathlib import Path

BASE = Path(sys.executable).parent if getattr(sys, 'frozen', False) else Path(__file__).resolve().parent
sys.path.insert(0, str(Path(__file__).resolve().parent / 'core'))
from ku5p import Client, Recorder, RadioError, RadioTimeout, validate_rx_start
from rf_protocol import RFConfig, StreamConfig, Snapshot, fragment_window
from waveform_config import WaveformConfig, MODES
from training_capture import (configuration_snapshot, training_path, tx_signature,
                              validate_tag, verify_training_tx, verify_training_band)
from ui_parameters import EXTRA_DEFAULTS, tx_firmware_reason
from demo_signal import DemoSignal, MODEL as DEMO_MODEL
from radio_links import UARTClient, RXClient, SplitClient, unknown_tx
from ku5p import INDEX
import rx_filter


def waveform(values):
    values={**EXTRA_DEFAULTS,**values}
    reason=tx_firmware_reason(values)
    if reason:
        raise ValueError(reason)
    def number(key, scale=1, integer=False):
        v = float(values[key])
        if not math.isfinite(v):
            raise ValueError('参数必须为有限数值：' + key)
        v *= scale
        if integer:
            if abs(v - round(v)) > 1e-5:
                raise ValueError('频率精度为 1 Hz：' + key)
            return round(v)
        return v
    c = WaveformConfig(
        modulation='AM' if values['modulation']=='AM-DSB-WC' else values['modulation'], center_hz=number('center', 1e6, True),
        bandwidth_hz=number('bandwidth', 1e6, True), snr_db=number('snr'),
        tx1_attenuation_db=number('atten1'), tx2_attenuation_db=number('atten2'),
        noise_low_hz=number('noise_low', 1e6, True), noise_high_hz=number('noise_high', 1e6, True),
        seed=int(values['seed'], 0), tx1_offset_hz=number('offset', 1e6, True),
        am_depth=number('am_depth') if values['modulation'] in ('AM','AM-DSB-WC') else .5,
        sideband='LSB' if values['sideband'].startswith('LSB') else 'USB',
        carrier_ratio_db=number('carrier_ratio') if values['modulation']=='AM-SSB-WC' else 6,
        tx1_noise=values.get('tx1_noise','1')=='1')
    c.plan()
    return c


def recording_options(directory, name, seconds, rate):
    if not re.fullmatch(r'[\w\-]+', name, flags=re.UNICODE):
        raise ValueError('文件名只使用汉字、字母、数字、下划线或连字符，不含扩展名。')
    seconds = float(seconds)
    if not math.isfinite(seconds) or not 0 < seconds <= 86400:
        raise ValueError('录制时长须在 0～86400 秒之间。')
    if rate not in (1_000_000, 25_000_000):
        raise ValueError('采样率须为 1 MSPS 或 25 MSPS。')
    path = Path(directory).expanduser().resolve() / name
    if any(path.with_suffix(ext).exists() for ext in ('.iq', '.index.bin', '.json')):
        raise ValueError('同名录制文件已存在，请更换文件名。')
    return dict(path=path, seconds=seconds, fs=rate)


def training_options(directory, tag, seconds, rate, expected_config, expected_mask):
    tag = validate_tag(tag)
    options = recording_options(directory, '__training_pending__', seconds, rate)
    options.update(training=True, tag=tag, expected_config=expected_config, expected_mask=expected_mask)
    return options


def receive_health(stats, rx=None, status_age=None, last_valid_age=None):
    """Describe measured host reception separately from fresh board counters."""
    if stats.get('complete_windows',0):
        return 'IQ 数据中断 · 保留最后窗口' if last_valid_age is not None and last_valid_age>2 else '有效 IQ 正在接收'
    if stats.get('udp_datagrams',0):
        if stats.get('datagrams',0):return '已收到有效 IQ 分片 · 正在等待完整窗口'
        labels=(('wrong_peer','来源地址/端口不符'),('bad_length','报文长度不符'),
                ('old_capture','旧采集编号'),('wrong_metadata','频率/采样率等元数据不符'),
                ('bad_crc','CRC 校验失败'),('bad_header_or_old_capture','报头不符'))
        detail='、'.join(f'{label} {stats[key]}' for key,label in labels if stats.get(key))
        return 'PC 已收到 UDP，但 IQ 未通过校验'+('：'+detail if detail else '')
    if rx is not None and status_age is not None and status_age<=3:
        if rx.get('sample_count',0)==0:return '板端上报采样计数为 0 · PC 未收到 IQ UDP'
        if rx.get('tx_datagrams',0)==0:return '板端已有采样 · 尚未上报发送 IQ 报文'
        return '板端已上报发送 IQ · PC 未收到 UDP，请检查网卡/防火墙'
    return 'PC 未收到 IQ UDP · 等待更新板端状态'


class PreviewRecorder(Recorder):
    """Recorder + live preview block, with an optional PC-side RX filter.

    Without a filter, Recorder writes every accepted window itself. With a filter,
    the accepted raw windows go through the StreamFilter; only filtered windows are
    written (same index layout, file offsets of the filtered file) and previewed.
    """
    def __init__(self, *args, preview=None, filter_info=None, **kwargs):
        super().__init__(*args, **kwargs)
        self._init_preview(preview, filter_info)

    def _init_preview(self, preview, filter_info):
        self.preview = preview
        self.preview_at = 0
        self.analysis_windows=deque(maxlen=64);self.analysis_sequence=None
        self.filter=rx_filter.StreamFilter(filter_info) if filter_info else None
        if self.filter:
            # Recorder.flush writes accepted windows itself; send its writes nowhere
            # and write the filtered windows to the real files instead.
            self.filtered_iq,self.filtered_index=self.iq,self.index
            self.iq,self.index=DiscardSink(),DiscardSink()
            self.filtered_offset=0

    def accepted_window(self,seq,raw,meta):
        # Filtering runs inline: it is limited to 1 MSPS, where it costs a few % of one core.
        if not self.filter:
            return self._accepted(seq,raw)
        for item in self.filter.push(seq,raw,meta):self._write_filtered(*item)

    def _write_filtered(self,seq,raw,meta):
        self.filtered_iq.write(raw)
        self.filtered_index.write(INDEX.pack(seq,self.capture,meta[0],self.filtered_offset,self.fs,meta[5],meta[4],0,zlib.crc32(raw)))
        self.filtered_offset+=len(raw);self.count('filtered_windows')
        self._accepted(seq,raw)

    def _accepted(self,seq,raw):
        if self.analysis_sequence is not None and seq!=self.analysis_sequence+1:self.analysis_windows.clear()
        self.analysis_sequence=seq;self.analysis_windows.append(raw)
        self.fresh_preview=True

    @property
    def file_bytes(self):
        return self.filtered_offset if self.filter else self.offset

    def filter_stats(self):
        f=self.filter
        if not f:return None
        return dict(dropped_windows=f.dropped,saturated_samples=f.saturated,busy_seconds=round(f.busy_s,3),restarts=f.restarts)

    def flush(self, force=False):
        if self.filter:
            super().flush(force)
            if self.preview and getattr(self,'fresh_preview',False) and time.monotonic()>=self.preview_at:
                self.fresh_preview=False;self.preview_at=time.monotonic()+.25
                self.preview(b''.join(self.analysis_windows),self.fs)
                self.count('preview_windows')
            return
        candidate = None
        if self.preview and time.monotonic() >= self.preview_at:
            complete = [(s, e) for s, e in self.pending.items()
                        if not e[3] and all(p is not None for p in e[1])]
            if complete:
                candidate = max(complete, key=lambda item: item[0])
        super().flush(force)
        if candidate and candidate[0] < self.next:
            self.preview_at = time.monotonic() + .25
            self.preview(b''.join(self.analysis_windows) or b''.join(candidate[1][1]), self.fs)
            self.count('preview_windows')

    def close(self):
        super().flush(force=True)
        if self.filter:
            for item in self.filter.drain():self._write_filtered(*item)
            self.filter.close()
            self.iq,self.index=self.filtered_iq,self.filtered_index
        self.iq.close();self.index.close()


class DiscardSink:
    """Accept validated windows without retaining data or opening any file."""
    def write(self,data):
        return len(data)

    def close(self):
        pass


class MonitorReceiver(PreviewRecorder):
    """Reuse the recorder's CRC/reordering/gap checks with bounded RAM only."""
    def __init__(self,capture,fs,lo,preview,depth=128,filter_info=None):
        # Recorder.__init__ opens files; deliberately initialize its in-memory state here.
        self.capture,self.fs,self.lo,self.depth=capture,fs,lo,depth
        self.iq,self.index=DiscardSink(),DiscardSink()
        self.pending={};self.next=0;self.highest=-1;self.offset=0;self.stats={}
        self.last_valid_at=None
        self._init_preview(preview,filter_info)


class DemoClient:
    """Synthetic local source; never opens a socket and never controls RF."""
    def __init__(self):
        self.boot = 1
        self.config = WaveformConfig(modulation='4PSK')
        self.mask = 0
        self.capture_id = 0
        self.active_config = 0
        self.running = False
        self.fs = 1_000_000
        self.rx_center=2_400_000_000
        self.rx_rf=RFConfig(self.rx_center,25_000_000,20_000_000,10000,0,0)

    def tx_status(self):
        c = self.config
        return dict(schema=1, **{k: v for k, v in asdict(c).items() if k in ('center_hz', 'bandwidth_hz', 'snr_db', 'noise_low_hz', 'noise_high_hz', 'seed')},
                    attenuation1_db=c.tx1_attenuation_db, attenuation2_db=c.tx2_attenuation_db,
                    modulation='AM-DSB-WC' if c.plan()['modulation']=='AM' else c.plan()['modulation'], applied_mask=self.mask, requested_mask=self.mask,
                    radio_flags=3, fault_index=0, clip_count1=0, clip_count2=0,
                    registers=c.plan()['registers'], capture_high=self.capture_id, request_high=0)

    def request(self, opcode, body=b'', config=0, version=1):
        if opcode == 0x102:
            return self.tx_status()
        if opcode == 4:
            self.running = False
        return Snapshot(state=2 if self.running else 0, active_config_id=self.active_config,
                        capture_id=self.capture_id, lo_hz=self.rx_center,
                        adc_sample_rate_hz=25_000_000, fs_eff_hz=self.fs, rx_bandwidth_hz=self.rx_rf.rx_bandwidth_hz,
                        rx_gain_mdB=self.rx_rf.rx_gain_mdB if self.rx_rf.gain_mode==0 else -2147483648,
                        status_flags=7|(self.rx_rf.gain_mode<<3))

    def discover(self):
        return self.tx_status()

    def set_tx(self, config):
        self.config = config
        return self.tx_status()

    def enable(self, tx1=None, tx2=None):
        if tx1 is not None:
            self.mask = (self.mask & ~1) | int(tx1)
        if tx2 is not None:
            self.mask = (self.mask & ~2) | (int(tx2) << 1)
        return self.tx_status()

    def close(self):
        pass


class RadioWorker(threading.Thread):
    def __init__(self):
        super().__init__(name='KU5P radio worker', daemon=True)
        self.commands = queue.Queue()
        self.events = queue.Queue()
        self.stop_capture = threading.Event()
        self.stop_monitor = threading.Event()
        self.shutting_down = threading.Event()
        self.client = None
        self.tx_connected=False;self.rx_connected=False
        self.owned_capture=None
        self.demo = False
        self.recording = False
        self.monitoring = False
        self.active_metadata = None
        self.training_lock = threading.Event()
        self.training_emergency = threading.Event()
        self.emergency_pending = threading.Event()
        self.submit_lock = threading.Lock()
        self.poll_at = float('inf')
        self.last_progress = 0
        self.active_receiver=None
        self.rx_snapshot=None;self.rx_snapshot_at=None;self.rx_poll_delayed=False
        self.start()

    def submit(self, action, **data):
        with self.submit_lock:
            if self.emergency_pending.is_set() and action not in ('status','all_stop'):
                raise RadioError('正在紧急停止，暂不接受配置、发射或录制请求。')
            if self.training_lock.is_set() and action not in ('status', 'all_stop'):
                raise RadioError('训练采集已锁定参数，请先停止录制；需要关闭发射时使用“紧急停止”。')
            if action == 'capture':
                self.stop_capture.clear()
                if data.get('training'):
                    self.training_emergency.clear()
                    self.training_lock.set()
            if action == 'monitor':
                self.stop_monitor.clear()
            if action == 'all_stop':
                if self.training_lock.is_set():
                    self.training_emergency.set()
                # Cancel pending work so it cannot start or re-enable TX after stopping.
                while True:
                    try:
                        cancelled, old_data = self.commands.get_nowait()
                    except queue.Empty:
                        break
                    if cancelled=='capture':
                        self.training_lock.clear()
                    self.log('紧急停止已取消排队操作：'+cancelled)
                    self.emit('done',action=cancelled,cancelled=True)
            self.commands.put((action, data))
            if action == 'all_stop':
                self.emergency_pending.set()
                self.stop_capture.set()
                self.stop_monitor.set()

    def emit(self, kind, **data):
        self.events.put((kind, data))

    def log(self, text, level='info'):
        self.emit('log', text=text, level=level)

    def preview(self,raw,fs):
        context=DemoSignal(self.client.config,fs).context(self.client.mask) if self.demo else None
        self.emit('preview',raw=raw,fs=fs,context=context)

    def _status(self):
        rx=asdict(Snapshot())
        if self.rx_connected:
            try:rx=asdict(self._rx_status())
            except Exception as exc:
                self.rx_connected=False;self.emit('link_fault',channel='rx')
                self.stop_monitor.set();self.stop_capture.set()
                self.log('网口 RX 状态失联，已锁定接收分析：'+str(exc),'error')
        tx=self._tx_status()
        self.emit('status',rx=rx,tx=tx,boot=self.client.boot,demo=self.demo,
                  rx_firmware_version=getattr(getattr(self.client,'rx',None),'firmware_version',None),
                  rx_status_stale=self.rx_poll_delayed,
                  tx_connected=self.tx_connected,rx_connected=self.rx_connected)
        self.poll_at = time.monotonic() + 2
        return rx, tx

    def _remember_rx(self, snapshot):
        self.rx_snapshot=snapshot;self.rx_snapshot_at=time.monotonic()
        self.rx_poll_delayed=False
        return snapshot

    def _rx_status(self):
        try:result=self.client.request(5)
        except RadioTimeout:
            rec=self.active_receiver
            # Only a transport timeout may use the last snapshot. Fresh,
            # validated IQ for our capture proves the receive path is alive.
            # Training still requires a successful configuration readback.
            if (not self.training_lock.is_set() and self.rx_snapshot is not None and rec is not None
                    and rec.last_valid_at is not None and time.monotonic()-rec.last_valid_at<=2):
                rec.count('status_timeouts')
                if not self.rx_poll_delayed:
                    self.log('RX 状态查询暂时超时，但本会话有效 IQ 仍在到达，继续接收。','warning')
                self.rx_poll_delayed=True
                return self.rx_snapshot
            raise
        if self.rx_poll_delayed:self.log('RX 状态查询已恢复。')
        self.rx_poll_delayed=False
        return self._remember_rx(result)

    def _filter_plan(self,options,fs):
        """Validated filter plan for this session, or None. Raises on an invalid spec."""
        spec=options.get('filter')
        if not spec:return None
        info=rx_filter.plan(spec,fs)
        if info['load']>=.7:
            self.log(f'滤波器负载高：{spec.label()}，N={info["n"]}，实测处理负载 {info["load"]*100:.0f}%（{info["workers"]} 线程）。'
                     '接收与写盘同时进行时可能跟不上，出现丢窗会报错；可加大过渡带宽 Δf 或降低 As。','warning')
        return info

    def _check_filter(self,rec,started,state):
        """Once a second: warn when filtering approaches real time, error when windows are lost."""
        f=getattr(rec,'filter',None)
        if not f:return
        now=time.monotonic()
        if now<state.get('next',0):return
        state['next']=now+1
        elapsed=max(1e-3,now-started)
        load=f.busy_s/elapsed
        # Only judge load over at least a second: the first moments of a stream are dominated
        # by start-up work and a single batch, not by sustained throughput.
        if elapsed>=1 and load>=.8 and not state.get('warned'):
            state['warned']=True
            self.log(f'滤波处理占用 {load*100:.0f}% 实时，接近处理上限；若出现丢窗将报错。','warning')
        lost=rec.stats.get('missing_or_conflicting_windows',0)
        if lost>state.get('lost',0):
            self.log(f'接收丢失 {lost-state.get("lost",0)} 个 IQ 窗（累计 {lost}）：网络或接收循环跟不上，录制已不连续。','error')
            state['lost']=lost

    def _receive_progress(self,rec):
        now=time.monotonic()
        age=None if self.rx_snapshot_at is None else now-self.rx_snapshot_at
        valid_age=None if rec.last_valid_at is None else now-rec.last_valid_at
        return dict(receive_health=receive_health(rec.stats,
            asdict(self.rx_snapshot) if self.rx_snapshot else None,age,valid_age),
            rx_status_age_seconds=age,iq_last_valid_age_seconds=valid_age)

    def _tx_status(self):
        if not self.tx_connected:return unknown_tx()
        try:return self.client.request(0x102,version=2)
        except Exception as exc:
            self.tx_connected=False;self.emit('link_fault',channel='tx')
            self.log('UART 状态失联：'+str(exc),'error')
            return unknown_tx()

    def _close(self,channel='all'):
        for name in ('tx','rx'):
            if channel not in (name,'all'):continue
            if self.client and not self.demo:
                link=getattr(self.client,name)
                if link:link.close();setattr(self.client,name,None)
            setattr(self,name+'_connected',False)
            if name=='rx':self.rx_snapshot=None;self.rx_snapshot_at=None;self.rx_poll_delayed=False
            self.emit('disconnected',channel=name)
        if not self.tx_connected and not self.rx_connected:
            if self.client:self.client.close()
            self.client=None;self.poll_at=float('inf')

    def _stop_owned(self):
        if self.owned_capture is None:return None
        current=self.client.request(5)
        # IDLE can still contain our incomplete SET_RF/SET_STREAM sequence.
        # A failed START on older firmware can retain the previous capture ID.
        if current.state not in (0,4) and current.capture_id!=self.owned_capture:
            self.owned_capture=None
            raise RadioError('RX 已由其他控制器接管，未发送 STOP；请与悟净协调后重连。')
        result=self.client.request(4)
        if result.state==0:self.owned_capture=None
        return result

    def _idle_rx(self):
        current=self.client.request(5)
        if current.state==4:
            current=self.client.request(4)
        if current.state!=0:
            raise RadioError('RX 已被其他会话占用，未发送 STOP 抢占。')
        return current

    def _command(self, action, data, inside_capture=False):
        if inside_capture and self.training_lock.is_set() and action not in ('status', 'all_stop'):
            raise RadioError('训练采集期间配置已锁定，只能查询状态或紧急停止。')
        if inside_capture and action not in ('enable','configure','connect','disconnect','status','all_stop'):
            raise RadioError('录制期间只能查询状态、切换 TX 或停止。')
        if action in ('connect','connect_rx'):
            channel='tx' if action=='connect' else 'rx'
            demo=data.get('demo',False)
            if self.client and demo!=self.demo:raise RadioError('切换离线演示前，请先断开 UART 和网口。')
            self._close(channel)
            self.demo=demo
            if self.client is None:self.client=DemoClient() if demo else SplitClient()
            try:
                if not demo:
                    state=BASE/'state'/'request_ids.sqlite'
                    if channel=='tx':
                        link=UARTClient(data.get('port','COM3'),data.get('baud',115200),state)
                    else:
                        ipaddress.IPv4Address(data['bind']);ipaddress.IPv4Address(data['peer'])
                        link=RXClient(data['bind'],data['peer'],state,timeout=.35,retries=2)
                    setattr(self.client,channel,link)
                    if channel=='tx':link.pump=self.client.pump
                    link.discover()
                    other=getattr(self.client,'rx' if channel=='tx' else 'tx')
                    if other and other.boot!=link.boot:raise RadioError('UART 与网口 boot ID 不一致，请确认连接同一块 KU5P。')
                setattr(self,channel+'_connected',True)
                rx, tx = self._status()
                if not getattr(self,channel+'_connected'):raise RadioError('握手后的状态读回失败，连接未建立。')
            except BaseException:
                self._close(channel)
                raise
            self.emit('connected',channel=channel,demo=self.demo)
            self.log(('演示 ' if demo else '')+('UART TX' if channel=='tx' else '网口 RX')+' 协议握手成功。')
        elif action in ('disconnect','disconnect_rx'):
            self._close('tx' if action=='disconnect' else 'rx')
            self.log('连接已断开；TX 状态不因断开而改变。')
        else:
            if not self.client:
                raise RadioError('请先连接开发板或进入离线演示。')
            if action == 'status':
                self._status()
            elif action == 'configure':
                if not self.tx_connected:raise RadioError('TX 配置需要 UART 握手成功。')
                try:
                    applied=self.client.set_tx(data['config'])
                except Exception:
                    # Show the board's actual fault/readiness immediately,
                    # while preserving the original command error for the UI.
                    try:self._status()
                    except Exception:pass
                    raise
                rx,_=self._status()
                if self.active_metadata is not None:
                    self.active_metadata['tx_events'].append(dict(time_local=datetime.now().isoformat(),cause='TX_CONFIGURE',status=applied))
                if self.rx_connected and rx.get('state')==2:
                    self.log(f"TX 配置已读回确认；RX 会话继续，当前接收中心 {rx['lo_hz']/1e6:g} MHz。")
                    c=data['config']
                    span=min(rx.get('rx_bandwidth_hz',20_000_000),
                             800_000 if rx.get('fs_eff_hz')==1_000_000 else 20_000_000)
                    if abs(c.center_hz+c.tx1_offset_hz-rx['lo_hz'])>(span+c.bandwidth_hz)/2:
                        self.log('TX1 信号频段在当前 RX 有效频段之外；upload 会随后按界面 RX 参数（跟随时取 TX 本振）重启观测。','warning')
                elif self.rx_connected:
                    self.log('TX 配置已读回确认；RX 当前未采集，以板端实际状态为准。')
                else:
                    self.log('TX 配置已读回确认；本 PC 网口未连接，RX 状态由接收控制方确认。')
            elif action == 'enable':
                if not self.tx_connected:raise RadioError('TX 开关需要 UART 握手成功。')
                tx = self.client.enable(data.get('tx1'), data.get('tx2'))
                if self.active_metadata is not None:
                    self.active_metadata['tx_events'].append(dict(time_local=datetime.now().isoformat(),cause='TX_ENABLE',status=tx))
                self.emit('tx', tx=tx)
                self.log(f"TX 开关已读回确认：TX1={'开' if tx['applied_mask'] & 1 else '关'}，TX2={'开' if tx['applied_mask'] & 2 else '关'}。")
            elif action == 'all_stop':
                # Disable RF first; capture cleanup follows on this same worker.
                self.stop_capture.set()
                self.stop_monitor.set()
                errors=[];tx=None
                if self.tx_connected:
                    try:tx=self.client.enable(False,False)
                    except Exception as exc:errors.append('UART TX 停止未确认：'+str(exc))
                else:errors.append('UART 未连接，无法确认关闭 TX')
                if self.active_metadata is not None:
                    self.active_metadata['tx_events'].append(dict(time_local=datetime.now().isoformat(),cause='ALL_STOP',status=tx))
                if tx:self.emit('tx', tx=tx)
                if not inside_capture:
                    try:self._stop_owned()
                    except Exception as exc:errors.append(str(exc))
                    self._status()
                if errors:raise RadioError('；'.join(errors))
                self.log('UART 已确认两路 TX 关闭；已请求停止本 PC 的 IQ 会话。')
            elif action == 'stop_remote':
                if self.owned_capture is None:
                    current=self.client.request(5)
                    if current.state!=4:raise RadioError('本 PC 没有 RX 会话，不发送 STOP 干扰悟净。')
                    self.client.request(4)
                else:self._stop_owned()
                self._status()
                self.log('板上 IQ 采集已停止，TX 开关保持原状态。')
            elif action == 'capture':
                if not self.rx_connected:raise RadioError('网口 RX 未握手成功，禁止录制。')
                self._capture(data)
            elif action == 'monitor':
                if not self.rx_connected:raise RadioError('网口 RX 未握手成功，禁止接收分析。')
                self._monitor(data)
            else:
                raise ValueError('未知操作：' + action)

    def _pending_capture_commands(self):
        try:
            action, data = self.commands.get_nowait()
        except queue.Empty:
            return
        try:
            self._command(action, data, inside_capture=True)
        except Exception as exc:
            self.emit('error', action=action, message=str(exc), uncertain=not self.demo)
        finally:
            if action=='all_stop':
                self.emergency_pending.clear()
            self.emit('done', action=action)

    def _monitor(self,options):
        """Use the existing START/STOP protocol for live reception, with no recording outputs."""
        fs=options['fs']
        if fs not in (1_000_000,25_000_000):raise ValueError('观测采样率只支持 1 MSPS / 25 MSPS。')
        if self.stop_monitor.is_set() or self.shutting_down.is_set():
            self.emit('monitor_finished',stop_confirmed=False,error=None,stats={},started=False)
            return
        sock=None;rec=None;attempted=False;error=None;stop_confirmed=False
        started=time.monotonic()
        try:
            if not self.demo:
                sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
                sock.setsockopt(socket.SOL_SOCKET,socket.SO_RCVBUF,64*1024*1024)
                if hasattr(socket,'SO_EXCLUSIVEADDRUSE'):
                    sock.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1)
                sock.bind(self.client.sock.getsockname()[:1]+(40000,));sock.setblocking(False)
            tx=self._tx_status()
            before=self._idle_rx()
            rf=options.get('rf') or RFConfig(before.lo_hz or tx['center_hz'] or 2_400_000_000,25_000_000,20_000_000,10000,0,0)
            center=rf.lo_hz
            if self.demo:
                config=before.active_config_id+1;cid=self.client.capture_id+1
            else:
                config=self.client.ids.reserve('config',before.active_config_id)
                cid=self.client.ids.reserve('capture',max(before.capture_id,tx['capture_high']))
            filter_info=self._filter_plan(options,fs)
            rec=MonitorReceiver(cid,fs,center,self.preview,filter_info=filter_info)
            self.active_receiver=rec
            filter_state={}

            def pump():
                deadline=time.monotonic()+.002
                for _ in range(512):
                    try:packet,source=sock.recvfrom(2048)
                    except BlockingIOError:break
                    rec.feed(packet,source,self.client.peer[0])
                    if time.monotonic()>=deadline:break

            if self.stop_monitor.is_set() or self.shutting_down.is_set():
                return
            attempted=True;self.owned_capture=cid
            if self.demo:
                self.client.active_config=config;self.client.capture_id=cid
                self.client.rx_center=center;self.client.rx_rf=rf
                self.client.fs=fs;self.client.running=True
                actual=self.client.request(5)
            else:
                self.client.pump=pump
                self.client.request(1,rf.pack(),config)
                self.client.request(2,StreamConfig(1,fs,25_000_000//fs,0,1024,1024,0,0,0).pack(),config)
                actual=self.client.request(3,struct.pack('>I',cid),config)
                warning=validate_rx_start(actual,config,cid,rf,fs)
                if warning:self.log(warning,'warning')
            self._remember_rx(actual)
            self.monitoring=True
            self.emit('status',rx=asdict(actual),tx=tx,boot=self.client.boot,demo=self.demo)
            self.emit('monitor_started',fs=fs,capture_id=cid,center_hz=center,demo=self.demo,
                      filtered=bool(filter_info))
            self.log('接收观测已开启，不创建 IQ、索引或录制 JSON 文件。'+
                     (f"显示经 PC 滤波：{options['filter'].label()}，N={filter_info['n']}。" if filter_info else ''))
            seq=0
            demo_source=DemoSignal(self.client.config,fs) if self.demo else None
            next_demo=next_progress=time.monotonic();next_status=next_progress+1
            while not self.stop_monitor.is_set() and not self.shutting_down.is_set():
                if self.demo:
                    if time.monotonic()>=next_demo:
                        if demo_source.config!=self.client.config:demo_source=DemoSignal(self.client.config,fs)
                        raw=demo_source.window(self.client.mask)
                        for packet in fragment_window(raw,capture_id=cid,window_seq=seq,sample_index=seq*1024,
                                                      lo_hz=center,fs_eff_hz=fs,rx_gain_mdB=10000):
                            rec.feed(packet,('demo',40000),'demo')
                        seq+=1;next_demo=time.monotonic()+.02
                    time.sleep(.002)
                else:
                    ready,_,_=select.select([sock],[],[],.005)
                    if ready:pump()
                rec.flush()
                self._check_filter(rec,started,filter_state)
                now=time.monotonic()
                if now>=next_progress:
                    self._pending_capture_commands()
                    self.emit('monitor_progress',stats=dict(rec.stats),fs=fs,elapsed=now-started,**self._receive_progress(rec))
                    next_progress=time.monotonic()+.2
                if now>=next_status and not self.stop_monitor.is_set():
                    s=self._rx_status();t=self._tx_status()
                    if s.state!=2 or s.capture_id!=cid or any(getattr(s,k)!=getattr(actual,k) for k in
                        ('active_config_id','lo_hz','adc_sample_rate_hz','fs_eff_hz','rx_bandwidth_hz','rx_gain_mdB')):
                        raise RadioError('接收观测会话已停止或 RX 配置发生变化，请重新开启。')
                    self.emit('status',rx=asdict(s),tx=t,boot=self.client.boot,demo=self.demo,
                              rx_status_stale=self.rx_poll_delayed)
                    next_status=time.monotonic()+1
        except Exception as exc:
            error=exc
        finally:
            if self.emergency_pending.is_set():self._pending_capture_commands()
            if attempted:
                try:
                    stopped=self._stop_owned()
                    if stopped.state!=0:raise RadioError('接收观测 STOP 后板端尚未确认空闲。')
                    stop_confirmed=True
                    tx=self._tx_status()
                    self.emit('status',rx=asdict(stopped),tx=tx,boot=self.client.boot,demo=self.demo)
                except Exception as exc:error=error or exc
            if not self.demo:self.client.pump=lambda:None
            if rec:rec.close()
            if sock:sock.close()
            self.active_receiver=None
            self.monitoring=False
            self.emit('monitor_finished',stop_confirmed=stop_confirmed,error=str(error) if error else None,
                      stats=dict(rec.stats) if rec else {},started=attempted)
        if error:raise error
        self.log('接收观测已停止。')

    def _capture(self, options):
        if self.stop_capture.is_set() or self.shutting_down.is_set():
            raise ValueError('录制已在启动前取消，未创建数据文件。')
        path = Path(options['path'])
        fs, seconds = options['fs'], options['seconds']
        training = bool(options.get('training'))
        before=self._idle_rx()
        tx=self._tx_status()
        rf=options.get('rf') or RFConfig(before.lo_hz or tx['center_hz'] or 2_400_000_000,25_000_000,20_000_000,10000,0,0)
        filter_info=self._filter_plan(options,fs)
        filter_spec=options.get('filter') if filter_info else None
        locked_config = None
        if training:
            if not self.tx_connected:raise RadioError('带标签训练采集需要 UART 与网口均连接成功。')
            tx = self._tx_status()
            verify_training_tx(tx, options.get('expected_config'), options.get('expected_mask'), self.demo)
            locked_config = configuration_snapshot(tx, fs, self.demo, rf, filter_spec)
            verify_training_band(locked_config)
            path = training_path(path.parent, locked_config, options.get('tag', ''))
            if self.stop_capture.is_set() or self.shutting_down.is_set():
                raise RadioError('训练采集已在启动前取消，未创建数据文件。')
        if self.demo and not path.name.startswith('DEMO_'):
            path = path.with_name('DEMO_' + path.name)
        # Reserve all outputs, including metadata, without overwriting old captures.
        path.parent.mkdir(parents=True, exist_ok=True)
        if any(path.with_suffix(ext).exists() for ext in ('.iq', '.index.bin', '.json')):
            raise FileExistsError('录制输出已存在：' + str(path))
        metadata_file = path.with_suffix('.json').open('x', encoding='utf-8')
        self.recording = True
        rec = None
        sock = None
        attempted = False
        actual = None
        error = None
        metadata = dict(simulated=self.demo, analysis_applied_to_recording=False, source='OFFLINE_DEMO_SYNTHETIC' if self.demo else 'KU5P_RX1',
                        hardware_verified=False, created_local=datetime.now().isoformat(),
                        fs_hz=fs, requested_seconds=seconds,
                        format='little-endian interleaved int16 I,Q; original ADC scale, no normalization',
                        index_format='big-endian >IIQQIiHHI: window_seq,capture_id,sample_index,file_byte_offset,fs_hz,rx_gain_mdB,flags,reserved,window_crc32',
                        index_record_bytes=40, points_per_window=1024, absolute_power_calibrated=False,
                        rx_bandwidth_hz=rf.rx_bandwidth_hz, rx_gain_mdB=rf.rx_gain_mdB if rf.gain_mode==0 else -2147483648,
                        rx_gain_mode=rf.gain_mode, automatic_gain_varies=bool(rf.gain_mode),
                        snr_definition='TX1 internal digital SNR; RX SNR/SINR is not measured', tx_events=[])
        if self.demo:
            metadata['demo_model']=DEMO_MODEL
            metadata['demo_limitations']='rectangular digital symbols; no RRC, RF channel, attenuation calibration or band-limited TX2 model; generated at ~50 windows/s'
        if training:
            metadata.update(training_mode=True, configuration_locked=True,
                            capture_configuration=locked_config, label=locked_config['label'],
                            label_source=locked_config['label_source'],
                            configuration_consistent=True, configuration_check_interval_seconds=1,
                            termination_reason='initializing', recording_state='initializing',
                            exclude_from_automatic_labeling=True,
                            automatic_label_exclusion_reasons=['recording_not_finalized'],
                            training_review_required=['received_signal_presence_and_quality', 'received_SNR_unmeasured'])
            if options.get('campaign'):
                # Batch capture: campaign id, point index and swept values for this file.
                metadata['campaign']=dict(options['campaign'])
        else:
            metadata['training_mode'] = False
        if filter_info:
            # The files hold filtered IQ only; the raw stream is not stored.
            metadata.update(rx_filter=rx_filter.metadata(filter_spec, filter_info, fs), iq_content='pc_filtered',
                            format=metadata['format'] + '; PC FIR-filtered (see rx_filter), not raw ADC samples')
        else:
            metadata['iq_content'] = 'raw_adc'
        start = time.monotonic()
        metadata['index_record_bytes'] = struct.calcsize('>IIQQIiHHI')
        self.active_metadata = metadata
        try:
            if training:
                # A valid sidecar exists before IQ starts, even if this process is interrupted.
                json.dump(metadata, metadata_file, ensure_ascii=False, indent=2)
                metadata_file.flush()
                os.fsync(metadata_file.fileno())
            if not self.demo:
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 64 * 1024 * 1024)
                if hasattr(socket, 'SO_EXCLUSIVEADDRUSE'):
                    sock.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
                sock.bind(self.client.sock.getsockname()[:1] + (40000,))
                sock.setblocking(False)
                metadata['socket_receive_buffer_bytes'] = sock.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF)
            tx = self._tx_status()
            if training and tx_signature(tx) != locked_config['tx']:
                metadata['configuration_consistent'] = False
                raise RadioError('训练采集启动前板端配置已变化，请刷新并重试。')
            before = self.client.request(5)
            if before.state!=0:raise RadioError('RX 已被悟净或其他会话占用，未发送 STOP。')
            center=rf.lo_hz
            if not self.demo:
                config = self.client.ids.reserve('config', before.active_config_id)
                cid = self.client.ids.reserve('capture', max(before.capture_id,tx['capture_high']))
            else:
                config = before.active_config_id + 1
                cid = self.client.capture_id + 1
            rec = PreviewRecorder(path, cid, fs, center,
                                  preview=self.preview, filter_info=filter_info)
            self.active_receiver=rec
            filter_state={}

            def pump():
                deadline = time.monotonic() + .002
                for _ in range(512):
                    try:
                        packet, source = sock.recvfrom(2048)
                    except BlockingIOError:
                        break
                    rec.feed(packet, source, self.client.peer[0])
                    if time.monotonic() >= deadline:
                        break

            def discard_iq():
                while True:
                    try:
                        sock.recvfrom(2048)
                    except BlockingIOError:
                        return

            metadata.update(center_hz=center, capture_id=cid, boot_id=self.client.boot, tx=tx)
            attempted = True;self.owned_capture=cid
            if not self.demo:
                # With a dead time, everything before it ends is settling data: the START and
                # readback exchanges below pump the IQ socket, so they must not feed the recorder
                # (it would record the first windows and then see the dead time as one gap).
                self.client.pump = discard_iq if float(options.get('discard_seconds') or 0) > 0 else pump
                self.client.request(1,rf.pack(),config)
                self.client.request(2, StreamConfig(1, fs, 25_000_000 // fs, 0, 1024, 1024, 0, 0, 0).pack(), config)
                actual = self.client.request(3, struct.pack('>I', cid), config)
                metadata['start_snapshot']=asdict(actual)
                warning=validate_rx_start(actual,config,cid,rf,fs)
                if warning:
                    metadata['start_link_warning']=warning
                    self.log(warning,'warning')
            else:
                self.client.active_config = config
                self.client.capture_id = cid
                self.client.fs = fs
                self.client.rx_center=center;self.client.rx_rf=rf
                self.client.running = True
                actual = self.client.request(5)
            metadata['start_snapshot'] = asdict(actual)
            self._remember_rx(actual)
            if training:
                expected_rx=locked_config['rx']
                if (actual.lo_hz!=expected_rx['lo_hz'] or actual.fs_eff_hz!=expected_rx['fs_hz'] or
                    actual.rx_bandwidth_hz!=expected_rx['bandwidth_hz'] or actual.rx_gain_mdB!=expected_rx['gain_mdB']):
                    metadata['configuration_consistent']=False
                    raise RadioError('实际 RX 读回与训练配置不一致，禁止自动贴标签。')
                start_tx = self._tx_status()
                if tx_signature(start_tx) != locked_config['tx']:
                    metadata['configuration_consistent'] = False
                    raise RadioError('START 后板端配置与锁定配置不一致。')
                verify_training_tx(start_tx, demo=self.demo)
                metadata.update(recording_state='recording', termination_reason='recording')
                metadata_file.seek(0)
                json.dump(metadata, metadata_file, ensure_ascii=False, indent=2)
                metadata_file.truncate()
                metadata_file.flush()
            self.emit('status', rx=metadata['start_snapshot'], tx=tx,
                      boot=self.client.boot, demo=self.demo)
            dead = float(options.get('discard_seconds') or 0)
            if dead > 0:
                # Batch dead time: RX is running with the final TX/RX settings; receive and
                # drop everything until the RF chain, AGC and DC tracking have settled.
                metadata['dead_time_seconds'] = dead
                self.emit('capture_settling', seconds=dead)
                until = time.monotonic() + dead
                while time.monotonic() < until and not self.stop_capture.is_set():
                    if self.demo:
                        time.sleep(.01)
                    else:
                        ready, _, _ = select.select([sock], [], [], .005)
                        if ready:
                            for _ in range(512):
                                try:
                                    sock.recvfrom(2048)
                                except BlockingIOError:
                                    break
                if self.stop_capture.is_set():
                    raise RadioError('死区等待中已停止，未写入 IQ。')
                # The status query also pumps the IQ socket: still dead-time data.
                s_after = self._rx_status()
                if s_after.state != 2 or s_after.capture_id != cid:
                    raise RadioError('死区等待期间板端采集会话停止或发生故障。')
                # Throw away what queued in the socket during the dead time and the status
                # query, so recording starts on live packets instead of a burst of backlog.
                if not self.demo:
                    discard_iq()
                # The dead time read the stream without the recorder: start the file at the
                # next window that arrives, not at window 0, then let the pump feed it again.
                rec.join_stream = True
                if not self.demo:
                    self.client.pump = pump
            start = time.monotonic()
            self.emit('capture_started', path=str(path), demo=self.demo, seconds=seconds, fs=fs,
                      training=training, configuration=locked_config)
            self.log('录制已开始：' + str(path) + ('（演示合成数据，限速生成）' if self.demo else ''))
            seq = 0
            demo_source=DemoSignal(self.client.config,fs) if self.demo else None
            next_demo = start
            next_status = start + 1
            next_progress = start
            while time.monotonic() - start < seconds and not self.stop_capture.is_set():
                if self.demo:
                    if time.monotonic() >= next_demo:
                        if demo_source.config!=self.client.config:demo_source=DemoSignal(self.client.config,fs)
                        raw=demo_source.window(self.client.mask)
                        for p in fragment_window(raw, capture_id=cid, window_seq=seq, sample_index=seq * 1024,
                                                 lo_hz=center, fs_eff_hz=fs, rx_gain_mdB=10000):
                            rec.feed(p, ('demo', 40000), 'demo')
                        seq += 1
                        next_demo = time.monotonic() + .02
                    time.sleep(.002)
                else:
                    ready, _, _ = select.select([sock], [], [], .005)
                    if ready:
                        pump()
                rec.flush()
                self._check_filter(rec,start,filter_state)
                now = time.monotonic()
                if now >= next_status:
                    s = self._rx_status()
                    if s.state != 2 or s.capture_id != cid:
                        raise RadioError('板端采集会话停止或发生故障。')
                    t = self._tx_status()
                    if training:
                        if tx_signature(t) != locked_config['tx']:
                            metadata.update(configuration_consistent=False, termination_reason='configuration_changed')
                            raise RadioError('检测到板端配置或 TX 开关变化，已停止训练采集；该文件禁止自动贴标签。')
                        verify_training_tx(t, demo=self.demo)
                        if any(getattr(s, k) != getattr(actual, k) for k in
                               ('active_config_id', 'lo_hz', 'adc_sample_rate_hz', 'fs_eff_hz',
                                'rx_bandwidth_hz', 'rx_gain_mdB')):
                            metadata.update(configuration_consistent=False, termination_reason='configuration_changed')
                            raise RadioError('检测到 RX 配置变化，已停止训练采集。')
                    self.emit('status', rx=asdict(s), tx=t, boot=self.client.boot, demo=self.demo,
                              rx_status_stale=self.rx_poll_delayed)
                    metadata['tx_events'].append(dict(elapsed_seconds=now - start, status=t))
                    next_status = time.monotonic() + 1
                if now >= next_progress:
                    self._pending_capture_commands()
                    self.emit('progress', elapsed=now - start, seconds=seconds, bytes=rec.file_bytes,
                              stats=dict(rec.stats), path=str(path), fs=fs,**self._receive_progress(rec))
                    next_progress = time.monotonic() + .2
            metadata['stopped_by_user'] = self.stop_capture.is_set()
            if training:
                metadata['termination_reason'] = 'user_stop' if self.stop_capture.is_set() else 'duration_reached'
        except Exception as exc:
            error = exc
            metadata['error'] = str(exc)
            if training and metadata['termination_reason'] in ('initializing', 'recording'):
                metadata['termination_reason'] = 'error'
        finally:
            # Disable RF before the normal IQ STOP/drain work on emergency requests.
            if self.emergency_pending.is_set():
                self._pending_capture_commands()
            if attempted:
                try:
                    metadata['stop_snapshot'] = asdict(self._stop_owned())
                    if training and metadata['stop_snapshot']['state'] != 0:
                        raise RadioError('STOP 后板端未确认进入空闲状态。')
                    metadata['tx_at_stop'] = self._tx_status()
                    if training and tx_signature(metadata['tx_at_stop']) != locked_config['tx']:
                        metadata.update(configuration_consistent=False, termination_reason='configuration_changed')
                        if not self.training_emergency.is_set():
                            error = error or RadioError('停止时板端配置已变化，该文件禁止自动贴标签。')
                    if training and actual is not None:
                        stopped = metadata['stop_snapshot']
                        if any(stopped[k] != getattr(actual, k) for k in
                               ('active_config_id', 'lo_hz', 'adc_sample_rate_hz', 'fs_eff_hz',
                                'rx_bandwidth_hz', 'rx_gain_mdB')):
                            metadata.update(configuration_consistent=False, termination_reason='configuration_changed')
                            error = error or RadioError('停止时 RX 配置已变化，该文件禁止自动贴标签。')
                        if not self.training_emergency.is_set():
                            verify_training_tx(metadata['tx_at_stop'], demo=self.demo)
                    metadata['stop_confirmed'] = True
                    self.emit('status', rx=metadata['stop_snapshot'], tx=metadata['tx_at_stop'],
                              boot=self.client.boot, demo=self.demo)
                    if sock:
                        drain_deadline = time.monotonic() + .15
                        while time.monotonic() < drain_deadline:
                            pump()
                            time.sleep(.001)
                except Exception as exc:
                    metadata['stop_confirmed'] = False
                    metadata['stop_error'] = str(exc)
                    error = error or exc
            if not self.demo:
                self.client.pump = lambda: None
            if rec:
                try:
                    rec.close()
                except Exception as exc:
                    metadata['file_error'] = str(exc)
                    error = error or exc
                metadata['receiver_stats'] = dict(rec.stats)
                metadata['file_bytes'] = rec.file_bytes
                if rec.filter_stats():
                    metadata['rx_filter']['runtime'] = rec.filter_stats()
                if not rec.file_bytes and error is None:
                    error = RadioError('未收到完整有效 IQ 窗口，请检查网卡、防火墙和板端状态。')
                    metadata['error'] = str(error)
            if sock:
                sock.close()
            self.active_receiver=None
            metadata['elapsed_seconds'] = time.monotonic() - start
            if training:
                reasons = []
                if self.demo:
                    reasons.append('offline_demo_not_RF_training_data')
                if not metadata['configuration_consistent']:
                    reasons.append('configuration_changed')
                if self.training_emergency.is_set():
                    metadata['termination_reason'] = 'all_stop'
                    reasons.append('all_stop_requested')
                if error:
                    metadata['error'] = str(error)
                    reasons.append('recording_error')
                if not metadata.get('stop_confirmed'):
                    reasons.append('stop_not_confirmed')
                if not metadata.get('file_bytes'):
                    reasons.append('no_complete_windows')
                # Continuous-duration data only: a lost window anywhere, or a filter restart at a
                # gap, means the samples are not one contiguous stretch.
                stats = metadata.get('receiver_stats', {})
                runtime = (metadata.get('rx_filter') or {}).get('runtime') or {}
                gap = stats.get('missing_or_conflicting_windows', 0)
                filter_gaps = runtime.get('restarts', 0)
                metadata['continuous'] = not gap and not filter_gaps
                if not metadata['continuous']:
                    reasons.append('discontinuous_iq')
                metadata.update(recording_state='finalized',
                                exclude_from_automatic_labeling=bool(reasons),
                                automatic_label_exclusion_reasons=reasons)
            try:
                metadata_file.seek(0)
                json.dump(metadata, metadata_file, ensure_ascii=False, indent=2)
                metadata_file.truncate()
                metadata_file.flush()
                if training:
                    os.fsync(metadata_file.fileno())
            finally:
                metadata_file.close()
                self.recording = False
                self.active_metadata = None
                self.emit('capture_finished', path=str(path), metadata=metadata, error=str(error) if error else None)
        if error:
            raise error
        self.log('录制文件已保存。停止录制不改变 TX 开关。')

    def shutdown(self):
        self.stop_capture.set()
        self.stop_monitor.set()
        self.shutting_down.set()

    def run(self):
        try:
            while not self.shutting_down.is_set():
                try:
                    action, data = self.commands.get(timeout=.1)
                except queue.Empty:
                    if self.client and time.monotonic() >= self.poll_at:
                        try:
                            self._status()
                        except Exception as exc:
                            self.poll_at = time.monotonic()+2
                            self.emit('error', action='poll', message=str(exc), uncertain=not self.demo)
                    continue
                try:
                    self._command(action, data)
                except Exception as exc:
                    self.emit('error', action=action, message=str(exc),
                              uncertain=not self.demo and not isinstance(exc,(ValueError,FileExistsError)))
                finally:
                    if action == 'capture':
                        self.training_lock.clear()
                    if action == 'all_stop':
                        self.emergency_pending.clear()
                    self.emit('done', action=action)
        finally:
            self._close()
            self.emit('shutdown')
