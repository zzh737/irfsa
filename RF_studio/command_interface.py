"""Text command interface for the GUI (console line and optional local TCP port).

Every command runs on the Tk thread and goes through the same widgets/actions
as a mouse click: it sets the GUI parameter variables, then `upload`,
`tx1 on`, `monitor on` etc. call the existing handlers. Nothing here talks to
the board directly, so the GUI's busy/lock/validation rules stay in force.

TCP: `serve <port>` listens on 127.0.0.1 only (never on the board network).
Protocol: one UTF-8 command per line; each reply line is "<level> <text>",
terminated by a line "." . Example:  printf 'set center 2420\\nupload\\n' | nc 127.0.0.1 47100
"""
from __future__ import annotations

import json
import queue
import shlex
import socket
import threading

from band_check import check as band_check

# Friendly name -> (GUI variable, help). Values are given in the GUI's own units.
PARAMS = {
    'mod': ('modulation', '调制方式，如 4PSK / 64QAM / AM-DSB-WC'),
    'center': ('center', 'TX 本振 / MHz'),
    'bw': ('bandwidth', 'TX1 基带带宽 / MHz'),
    'offset': ('offset', 'TX1 频偏 / MHz'),
    'snr': ('snr', 'TX1 内部 SNR / dB'),
    'noise': ('tx1_noise', 'TX1 内部噪声 on/off'),
    'att1': ('atten1', 'TX1 衰减 / dB'),
    'att2': ('atten2', 'TX2 衰减 / dB'),
    'noise_low': ('noise_low', 'TX2 噪声频段起点 / MHz'),
    'noise_high': ('noise_high', 'TX2 噪声频段终点 / MHz'),
    'seed': ('seed', '随机种子'),
    'sideband': ('sideband', 'SSB 边带 usb/lsb'),
    'carrier_ratio': ('carrier_ratio', 'SSB-WC 载波/边带功率比 / dB'),
    'am_depth': ('am_depth', 'AM 调制度'),
    'follow': ('rx_follow', 'RX 跟随 TX 本振 on/off'),
    'rx_center': ('rx_center', 'RX 中心 / MHz（跟随关闭时）'),
    'rx_bw': ('rx_bandwidth', 'RX 模拟带宽 / MHz：0.2 0.5 1 2 5 10 15 20'),
    'gain_mode': ('rx_gain_mode', 'RX 增益模式 manual/slow/fast'),
    'gain': ('rx_gain', 'RX 手动增益 / dB'),
    'rate': ('rate', '观测采样率 1 / 25（MSPS）'),
    'filter': ('rx_filter', 'RX 滤波器 on/off（作用于观测、录制、训练）'),
    'filter_type': ('filter_type', '滤波器类型 lpf / hpf / bpf / bsf'),
    'f1': ('filter_f1', 'LPF/HPF 截止频率 fc（单边：LPF 保留 f≤fc，HPF 保留 f≥fc），BPF/BSF 下边沿 f1 / kHz（相对 RX 本振，可为负）'),
    'f2': ('filter_f2', 'BPF/BSF 上边沿 f2 / kHz（相对 RX 本振）'),
    'ap': ('filter_ripple', '通带纹波 Ap / dB（0.01～3，分辨率 0.01）'),
    'as': ('filter_stop', '阻带衰减 As / dB（20～120）'),
    'tw': ('filter_transition', '过渡带宽 Δf / kHz'),
}
FILTER_TYPES = {'lpf': 'LPF · 低通', 'hpf': 'HPF · 高通', 'bpf': 'BPF · 带通', 'bsf': 'BSF · 带阻'}
ALIASES = {'modulation': 'mod', 'bandwidth': 'bw', 'atten1': 'att1', 'atten2': 'att2', 'tx1_noise': 'noise',
           'rx_follow': 'follow', 'rx_bandwidth': 'rx_bw', 'rx_gain': 'gain', 'rx_gain_mode': 'gain_mode'}
ONOFF = {'on': '1', 'off': '0', '1': '1', '0': '0', 'true': '1', 'false': '0', 'yes': '1', 'no': '0'}
GAIN_MODES = {'manual': '手动增益', 'mgc': '手动增益', 'slow': '慢速 AGC', 'fast': '快速 AGC'}
RATES = {'1': '1 MSPS · FIR 抽取', '1m': '1 MSPS · FIR 抽取', '25': '25 MSPS · 原始采样', '25m': '25 MSPS · 原始采样'}
SIDEBANDS = {'usb': 'USB / 上边带', 'lsb': 'LSB / 下边带'}

HELP = """指令（参数单位与界面一致，MHz / dB）：
  help                         本说明
  get [名称…]                  查看界面参数（不写名称则全部）
  set 名称 值 [名称 值 …]       修改界面参数，不下发；例：set mod 256QAM offset 0.15 gain 20
  upload                       下发参数（与右上角 upload 相同）
  tx1 on|off / tx2 on|off      TX 开关
  monitor on|off               RX 观测
  record start [秒] [文件名]     普通录制（录制页目录与采样率；省略则用界面时长/自动文件名）
  record stop|status           停止录制 / 录制状态与最近一次结果
  record wait [秒]             等待当前录制收尾（默认 时长+60 s）
  stop                         紧急停止 TX1 + TX2 + IQ
  status [refresh]             板端状态摘要（refresh：立即向板端查询）
  check                        检查频带是否会缺失
  wait [秒]                    等待当前操作完成（脚本用，默认 60 s）
  connect uart|rx|demo          连接；disconnect uart|rx 断开
  serve [端口] / serve off      开关本机 TCP 指令口（仅 127.0.0.1，默认 47100）
  train check                  批量检查（逐点检查，按问题汇总）
  train start [-y]             生成总览并确认后开始；-y 跳过确认（有 error 仍拒绝）
  train pause|stop|status      批量采集（参数在训练模式页设置）
  train load 文件 / train save 文件   导入任务（续录）/ 导出任务
参数名：""" + ', '.join(PARAMS)


class CommandInterface:
    def __init__(self, app):
        self.app = app
        self.server = None
        self.port = None
        self.requests = queue.Queue()
        self.waiters = []

    # ---- parsing -------------------------------------------------------
    def execute(self, line):
        """Run one command line on the Tk thread. Returns [(level, text), ...]."""
        try:
            words = shlex.split(line, posix=True)
        except ValueError as exc:
            return [('error', f'无法解析指令：{exc}')]
        if not words:
            return []
        verb, args = words[0].lower(), words[1:]
        handler = getattr(self, 'cmd_' + verb, None)
        if handler is None:
            return [('error', f'未知指令 “{verb}”，输入 help 查看。')]
        try:
            return handler(args) or []
        except (ValueError, KeyError, IndexError) as exc:
            return [('error', str(exc) or exc.__class__.__name__)]

    def cmd_help(self, args):
        return [('info', line) for line in HELP.splitlines()]

    def _key(self, name):
        name = ALIASES.get(name.lower(), name.lower())
        if name not in PARAMS:
            raise ValueError(f'未知参数 “{name}”。可用：' + ', '.join(PARAMS))
        return name

    def _normalize(self, name, value):
        var = PARAMS[name][0]
        low = value.lower()
        if var == 'filter_type':
            if low not in FILTER_TYPES:
                raise ValueError('filter_type 只接受 lpf / hpf / bpf / bsf')
            return FILTER_TYPES[low]
        if var in ('tx1_noise', 'rx_follow', 'rx_filter'):
            if low not in ONOFF:
                raise ValueError(f'{name} 只接受 on/off')
            return ONOFF[low]
        if var == 'rx_gain_mode':
            if low not in GAIN_MODES:
                raise ValueError('gain_mode 只接受 manual / slow / fast')
            return GAIN_MODES[low]
        if var == 'rate':
            if low not in RATES:
                raise ValueError('rate 只接受 1 或 25（MSPS）')
            return RATES[low]
        if var == 'sideband':
            if low not in SIDEBANDS:
                raise ValueError('sideband 只接受 usb / lsb')
            return SIDEBANDS[low]
        if var == 'modulation':
            from ui_parameters import UI_MODES, display_mode
            mode = display_mode(value.upper().replace('AM-', 'AM-'))
            match = next((m for m in UI_MODES if m.upper() == value.upper()), None) or (mode if mode in UI_MODES else None)
            if match is None:
                raise ValueError('未知调制方式。可用：' + ' '.join(UI_MODES))
            return match
        if var == 'seed':
            int(value, 0)
            return value
        float(value)
        return value

    def cmd_get(self, args):
        names = [self._key(n) for n in args] or list(PARAMS)
        return [('info', f'{n} = {self.app.v[PARAMS[n][0]].get()}') for n in names]

    def cmd_set(self, args):
        if not args or len(args) % 2:
            raise ValueError('用法：set 名称 值 [名称 值 …]')
        if self.app._training_active() or self.app.recording or self.app.capture_pending:
            raise ValueError('录制或训练采集中，参数已锁定。')
        pairs = [(self._key(args[i]), args[i + 1]) for i in range(0, len(args), 2)]
        changes = [(n, self._normalize(n, v)) for n, v in pairs]
        rx_keys = {'rx_follow', 'rx_center', 'rx_bandwidth', 'rx_gain_mode', 'rx_gain', 'rate'}
        if not self.app.rx_connected and any(PARAMS[n][0] in rx_keys for n, _ in changes):
            raise ValueError('网口 RX 未连接，RX 参数不可修改。')
        out = []
        filter_was = self.app.v['rx_filter'].get()
        for n, value in changes:
            self.app.v[PARAMS[n][0]].set(value)
            out.append(('info', f'{n} = {self.app.v[PARAMS[n][0]].get()}'))
        if filter_was == '1' and self.app.v['rx_filter'].get() != '1' and 'filter' not in dict(changes):
            out.append(('warning', 'RX 滤波器已自动关闭：25 MSPS 下不支持 PC 端滤波。'))
        if any(PARAMS[n][0].startswith(('rx_filter', 'filter_')) for n, _ in changes):
            # The filter is PC-side: no upload. A running observation restarts with it.
            self.app.filter_edited()
            note = self.app.filter_note.cget('text').replace('\n', ' · ')
            refused = dict(changes).get('filter') == '1' and self.app.v['rx_filter'].get() != '1'   # 25 MSPS
            out.append(('error' if refused or note.startswith(('待修正', '关闭 · 参数待修正')) else 'info', 'RX 滤波器：' + note))
        if any(not PARAMS[n][0].startswith(('rx_filter', 'filter_')) for n, _ in changes):
            out.append(('info', '参数已改，尚未下发；输入 upload 生效。'))
        return out

    def cmd_check(self, args):
        findings = band_check(self.app.values())
        if not findings:
            return [('ok', 'TX1 频带完整落在 RX 可用带宽内，未跨 RX 本振。')]
        return [(f.level, f.text) for f in findings]

    def cmd_upload(self, args):
        state = str(self.app.upload_btn.cget('state'))
        if state == 'disabled' or self.app.upload_job:
            raise ValueError('当前不能 upload：' + (self._busy_reason() or self.app.upload_hint.cget('text') or '有操作进行中') + '。')
        self.app.upload()
        return [('info', 'upload 已提交。')] if self.app.upload_job else []

    def _switch(self, channel, args):
        if not args or args[0].lower() not in ('on', 'off'):
            raise ValueError(f'用法：{channel} on|off')
        want = args[0].lower() == 'on'
        tx = self.app.last_tx
        if tx is None:
            raise ValueError('TX 状态未读回，请先连接 UART。')
        bit = 1 if channel == 'tx1' else 2
        if bool(tx['applied_mask'] & bit) == want:
            return [('info', f'{channel.upper()} 已经是{"开" if want else "关"}。')]
        widget = self.app.tx1_switch if channel == 'tx1' else self.app.tx2_switch
        if str(widget.cget('state')) == 'disabled':
            raise ValueError(f'{channel.upper()} 开关当前不可用：' + (self._busy_reason() or '已锁定') + '。')
        self.app.toggle_tx(1 if channel == 'tx1' else 2)
        return [('info', f'{channel.upper()} {"开启" if want else "关闭"}已提交。')]

    def cmd_tx1(self, args):
        return self._switch('tx1', args)

    def cmd_tx2(self, args):
        return self._switch('tx2', args)

    def cmd_monitor(self, args):
        if not args or args[0].lower() not in ('on', 'off'):
            raise ValueError('用法：monitor on|off')
        want = args[0].lower() == 'on'
        active = self.app.monitoring or self.app.monitor_pending
        if active == want:
            return [('info', '接收观测已经' + ('开启' if want else '关闭') + '。')]
        if str(self.app.monitor_switch.cget('state')) == 'disabled':
            if not self.app.rx_connected:
                raise ValueError('网口 RX 未连接。')
            raise ValueError('接收观测开关当前不可用：' + (self._busy_reason() or '已锁定或射频忙') + '。')
        self.app.toggle_monitor()
        return [('info', '接收观测' + ('开启' if want else '停止') + '已提交。')]

    def cmd_record(self, args):
        """Normal (non-training) capture through the record switch of the capture tab."""
        app = self.app
        what = (args[0] if args else 'status').lower()
        if what == 'status':
            return self.record_summary()
        if what == 'stop':
            if not (app.recording or app.capture_pending) or app.capture_mode != 'normal':
                raise ValueError('当前没有普通录制。')
            app.toggle_capture('normal')
            return [('info', '停止录制已提交；可用 record wait 等待收尾。')]
        if what == 'wait':
            raise ValueError('record wait 只在 TCP 指令口中可用。')
        if what != 'start':
            raise ValueError('用法：record start [秒] [文件名] | record stop | record status | record wait [秒]')
        if app.recording or app.capture_pending:
            raise ValueError('已有录制在进行。')
        if str(app.record_switch.cget('state')) == 'disabled':
            if not app.rx_connected:
                raise ValueError('网口 RX 未连接。')
            raise ValueError('录制开关当前不可用：' + (self._busy_reason() or app.upload_hint.cget('text') or '已锁定') + '。')
        if len(args) > 3:
            raise ValueError('用法：record start [秒] [文件名]')
        seconds = args[1] if len(args) > 1 else app.v['seconds'].get()
        name = args[2] if len(args) > 2 else app.v['filename'].get().strip()
        # Validate here: start_capture reports problems in a modal dialog, which
        # would block the Tk thread that serves this TCP request.
        import shutil
        from pathlib import Path
        from backend import recording_options
        fs = 25_000_000 if app.v['rate'].get().startswith('25') else 1_000_000
        opts = recording_options(app.v['directory'].get(), name, seconds, fs)
        ancestor = opts['path'].parent
        while not ancestor.exists():
            ancestor = ancestor.parent
        required = fs * 4 * opts['seconds'] * 1.02
        if not app.demo and shutil.disk_usage(ancestor).free < required:
            raise ValueError(f'磁盘剩余空间不足，预计需要约 {required/1e9:.2f} GB。')
        app.require_rx_supported()
        app.v['seconds'].set(str(seconds))
        app.v['filename'].set(name)
        app.toggle_capture('normal')
        if not app.capture_pending:
            raise ValueError('录制未能提交，详见日志。')
        return [('info', f'录制已提交：{fs/1e6:g} MSPS · {opts["seconds"]:g} s · {Path(opts["path"])}'),
                ('info', '可用 record wait 等待收尾，再用 record status 查看结果。')]

    def recording_busy(self):
        app = self.app
        return bool(app.recording or app.capture_pending or app.capture_stopping)

    def record_summary(self):
        app = self.app
        if app.recording or app.capture_pending:
            state = ('停止中' if app.capture_stopping else '启动中' if app.capture_pending else '录制中') + \
                    ('（训练采集）' if app.capture_mode == 'training' else '')
        else:
            state = '未录制'
        out = [('info', '录制：' + state)]
        out += [('info', line) for line in app.capture_summary.cget('text').splitlines() if line]
        if app.last_capture_path:
            out.append(('info', f'最近文件：{app.last_capture_path}'))
        return out

    def cmd_stop(self, args):
        self.app.all_stop()
        return [('warning', '紧急停止已提交：TX1 + TX2 + IQ。')]

    def cmd_status(self, args):
        """Cached read-back (the worker polls the board). `status refresh` asks the board now."""
        out = self.summary()
        if args and args[0].lower() == 'refresh':
            if not self.app.connected:
                raise ValueError('未连接，无法刷新。')
            self.app.send('status')
            out.append(('info', '已请求板端刷新；可用 wait 等待结果。'))
        return out

    def _busy_reason(self):
        app = self.app
        if app.upload_job or (app.pending - {'monitor'}):
            return '有操作进行中，可先 wait 再重试'
        if app.monitor_pending or app.monitor_stopping:
            return '接收观测正在切换，可先 wait 再重试'
        if app.recording or app.capture_pending or app._training_active():
            return '录制或训练采集中'
        return ''

    def summary(self):
        """Last read-back state, without sending anything to the board."""
        app = self.app
        out = []
        tx = app.last_tx
        if tx:
            flags = tx.get('radio_flags', 0)
            out.append(('info', f"TX：{tx.get('modulation')} · {tx['center_hz']/1e6:g} MHz · 基带带宽 {tx['bandwidth_hz']/1e6:g} MHz · "
                                f"TX1 {'开' if tx['applied_mask'] & 1 else '关'} / TX2 {'开' if tx['applied_mask'] & 2 else '关'} · "
                                f"衰减 {tx['attenuation1_db']:g}/{tx['attenuation2_db']:g} dB · 固件 {tx.get('firmware_version')}"))
            if flags & 24:
                out.append(('error', '射频 / 数据故障；upload 会重新初始化射频。'))
            elif flags & 64:
                out.append(('warning', '上次 TX 正交校准未收敛（非致命）。'))
        else:
            out.append(('info', 'TX：UART 未连接或状态未读回。'))
        rx = app.last_rx
        if rx:
            out.append(('info', f"RX：状态 {rx.get('state')} · {rx.get('lo_hz', 0)/1e6:g} MHz · 模拟带宽 {rx.get('rx_bandwidth_hz', 0)/1e6:g} MHz · "
                                f"IQ {rx.get('fs_eff_hz', 0)/1e6:g} MSPS · 观测{'中' if app.monitoring else '未开'}"))
        else:
            out.append(('info', 'RX：网口未连接。'))
        out.append(('info', 'upload：' + (app.upload_hint.cget('text') or '—')))
        return out

    def cmd_wait(self, args):
        """Only meaningful over TCP: the reply is deferred until the GUI is idle."""
        return [('info', '控制台中无需 wait；TCP 指令口会在操作完成后再回复。')]

    def cmd_train(self, args):
        import training_campaign as T
        panel = self.app.campaign
        what = (args[0] if args else 'status').lower()
        if what == 'status':
            c = panel.campaign
            if c is None:
                try:
                    preview = panel.preview()
                    return [('info', f'未开始；按当前设置共 {len(preview.points)} 点，预计 {T.format_duration(preview.total_seconds())}。')]
                except (T.CampaignError, ValueError, KeyError) as exc:
                    return [('warning', '未开始；当前设置有误：' + str(exc))]
            return [('info', line) for line in panel.status.cget('text').splitlines()] + [('info', f'任务文件：{c.path}')]
        if what == 'check':
            try:
                c = panel.campaign if panel.stage == 'paused' and panel.campaign else panel.preview()
            except (T.CampaignError, ValueError, KeyError) as exc:
                return [('error', str(exc))]
            issues = T.check(c, panel.free_bytes(c))
            head = [('info', f'{len(c.points)} 点 · {len(c.definition["segments"])} 段 · 预计 {T.format_duration(c.remaining_seconds())}')]
            return head + ([(i.level, i.text()) for i in issues] or [('ok', '未发现问题。')])
        if what == 'start':
            if panel.running():
                raise ValueError('批量采集已在运行。')
            confirm = '-y' not in args[1:]
            ok = panel.start(confirm=confirm)
            return [('info', '批量采集已开始。')] if ok else [('error', '批量采集未开始，详见上方日志。')]
        if what == 'pause':
            if not panel.running():
                raise ValueError('批量采集未在运行。')
            panel.pause()
            return [('info', '将在当前点完成后暂停。')]
        if what == 'stop':
            if panel.stage == 'idle':
                raise ValueError('批量采集未在运行。')
            panel.stop()
            return [('warning', '批量采集停止中；当前点下次续录时重录。')]
        if what == 'load':
            if len(args) < 2:
                raise ValueError('用法：train load 任务文件.json')
            c = panel.import_from(' '.join(args[1:]))
            n = c.counts()
            return [('ok', f'已导入 {c.id}：完成 {n["done"]} / {len(c.points)}；train start 继续。')]
        if what == 'save':
            if len(args) < 2:
                raise ValueError('用法：train save 导出路径.json')
            if panel.campaign is None:
                raise ValueError('还没有批量任务。')
            panel.export_to(' '.join(args[1:]))
            return [('ok', '已导出。')]
        raise ValueError('用法：train start|pause|stop|status|load 文件|save 文件')

    def cmd_connect(self, args):
        what = (args[0] if args else '').lower()
        if what == 'demo':
            self.app.demo_choice.set(True)
            self.app.connect()
            return [('info', '正在以离线演示连接 UART。')]
        if what == 'uart':
            self.app.demo_choice.set(False)
            self.app.connect()
            return [('info', f"正在连接 UART {self.app.v['serial_port'].get()}。")]
        if what == 'rx':
            self.app.connect_rx()
            return [('info', f"正在连接网口 RX {self.app.v['peer'].get()}。")]
        raise ValueError('用法：connect uart|rx|demo')

    def cmd_disconnect(self, args):
        what = (args[0] if args else '').lower()
        if what in ('uart', 'tx'):
            self.app.send('disconnect')
        elif what == 'rx':
            self.app.send('disconnect_rx')
        else:
            raise ValueError('用法：disconnect uart|rx')
        return [('info', f'正在断开 {what.upper()}。')]

    def cmd_serve(self, args):
        if args and args[0].lower() == 'off':
            self.stop_server()
            return [('info', 'TCP 指令口已关闭。')]
        port = int(args[0]) if args else 47100
        if self.server:
            return [('info', f'TCP 指令口已在 127.0.0.1:{self.port}。')]
        self.start_server(port)
        return [('ok', f'TCP 指令口已开启：127.0.0.1:{port}（仅本机）。')]

    # ---- idle tracking for TCP `wait` ----------------------------------
    def busy(self):
        app = self.app
        return bool(app.upload_job or (app.pending - {'monitor'}) or app.monitor_pending or app.monitor_stopping
                    or app.capture_pending or app.emergency_waiting
                    or (hasattr(app, 'campaign') and app.campaign.stage not in ('idle', 'paused')))

    # ---- TCP -----------------------------------------------------------
    def start_server(self, port):
        srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind(('127.0.0.1', port))
        srv.listen(4)
        self.server, self.port = srv, port
        threading.Thread(target=self._accept, args=(srv,), daemon=True).start()
        self.app.after(30, self._drain)

    def stop_server(self):
        if self.server:
            try:
                self.server.close()
            except OSError:
                pass
        self.server = self.port = None

    def _accept(self, srv):
        while True:
            try:
                conn, _ = srv.accept()
            except OSError:
                return
            threading.Thread(target=self._client, args=(conn,), daemon=True).start()

    def _client(self, conn):
        with conn:
            f = conn.makefile('rwb')
            for raw in f:
                line = raw.decode('utf-8', 'replace').strip()
                if not line:
                    continue
                done = threading.Event()
                box = {}
                self.requests.put((line, box, done))
                done.wait(600)
                try:
                    for level, text in box.get('lines', [('error', '指令超时')]):
                        f.write(f'{level} {text}\n'.encode('utf-8'))
                    f.write(b'.\n')
                    f.flush()
                except OSError:
                    return

    def _drain(self):
        """Tk-thread pump for TCP requests and deferred `wait` replies."""
        if self.server is None and self.requests.empty() and not self.waiters:
            return
        while not self.requests.empty():
            line, box, done = self.requests.get()
            self.app.console.write('cmd', 'tcp: ' + line)
            words = line.split()
            verb = [w.lower() for w in words[:2]]
            if verb[:1] == ['wait'] or verb == ['record', 'wait']:
                record = verb[0] == 'record'
                arg = words[2 if record else 1:][:1]
                try:
                    if arg:
                        timeout = float(arg[0])
                    elif record:
                        timeout = float(self.app.v['seconds'].get()) + 60
                    else:
                        timeout = 60.0
                except ValueError:
                    box['lines'] = [('error', '等待时间须为秒数')]
                    done.set()
                    continue
                self.waiters.append((box, done, self.app.tk.call('clock', 'milliseconds') + timeout * 1000, record))
                continue
            lines = self.execute(line)
            for level, text in lines:
                self.app.console.write(level, text)
            box['lines'] = lines or [('ok', '完成')]
            done.set()
        now = self.app.tk.call('clock', 'milliseconds')
        keep = []
        for box, done, deadline, record in self.waiters:
            if record and not self.recording_busy():
                box['lines'] = [('ok', 'record idle')] + self.record_summary()
                done.set()
            elif not record and not self.busy():
                box['lines'] = [('ok', 'idle')] + self.summary()
                done.set()
            elif now >= deadline:
                box['lines'] = [('error', ('record wait' if record else 'wait') + ' 超时，操作仍在进行')]
                done.set()
            else:
                keep.append((box, done, deadline, record))
        self.waiters = keep
        self.app.after(30, self._drain)

    def close(self):
        self.stop_server()
        for box, done, *_ in self.waiters:
            box['lines'] = [('error', '界面正在关闭')]
            done.set()
        self.waiters = []
