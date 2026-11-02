"""Training-mode batch panel and runner (Tk thread).

A campaign has one or more segments; the panel edits one segment at a time
(segment list + sweep editor). Each point runs through:
    configure -> set this point's parameters, upload (TX1 stays on)
    tx2       -> switch TX2 on/off for this point (readback)
    capture   -> start_training_capture(); the capture itself starts RX,
                 waits the global dead time (data dropped), then records
    finish    -> capture_finished: record files, mark done/failed, save, next
It never talks to the board directly; it uses app.upload(), the worker's
'enable' action and app.start_training_capture(), so every readback check applies.
"""
from __future__ import annotations

import shutil
import time
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

import training_campaign as T
import theme

MAX_COUNT = 64
STATE_TEXT = dict(pending='待录', recording='录制中', done='完成', failed='失败')
LEVEL_COLORS = dict(error=theme.ERROR, warning=theme.WARN, info=theme.TEXT, ok=theme.OK, muted=theme.MUTED, head=theme.ACCENT)


class DimensionRow:
    """[x] name   档位数 [n]   [v1] [v2] … — boxes appear when the count changes.

    choice dimensions get read-only comboboxes; 'mod' is a checklist.
    """
    def __init__(self, panel, parent, dim):
        self.panel, self.dim = panel, dim
        spec = T.DIMENSIONS[dim]
        self.enabled = tk.BooleanVar(value=False)
        self.count = tk.StringVar(value='1')
        self.value_vars = []
        self.frame = ttk.Frame(parent, style='White.TFrame')
        self.frame.pack(fill='x', pady=(0, 4))
        head = ttk.Frame(self.frame, style='White.TFrame')
        head.pack(fill='x')
        self.check = ttk.Checkbutton(head, text=spec['label'], variable=self.enabled, command=self._toggle)
        self.check.pack(side='left')
        self.hint = ttk.Label(head, text=self._hint(), style='Hint.TLabel')
        self.hint.pack(side='left', padx=(8, 0))
        self.body = ttk.Frame(self.frame, style='White.TFrame')
        if spec['kind'] == 'mod':
            self.all_btn = ttk.Button(head, text='全选', width=5, command=lambda: self._select_all(True))
            self.all_btn.pack(side='right')
            self.none_btn = ttk.Button(head, text='全不选', width=6, command=lambda: self._select_all(False))
            self.none_btn.pack(side='right', padx=(0, 4))
            from ui_parameters import UI_MODES
            self.mod_vars, self.mod_boxes = {}, []
            for i, mode in enumerate(UI_MODES):
                var = tk.BooleanVar(value=False)
                self.mod_vars[mode] = var
                cb = ttk.Checkbutton(self.body, text=mode, variable=var, command=panel.changed)
                cb.grid(row=i // 4, column=i % 4, sticky='w', padx=(0, 10))
                self.mod_boxes.append(cb)
        else:
            self.count_entry = ttk.Spinbox(head, from_=1, to=MAX_COUNT, width=5, textvariable=self.count,
                                           command=self._rebuild)
            self.count_entry.pack(side='right')
            self.count_entry.bind('<KeyRelease>', lambda e: self._rebuild())
            ttk.Label(head, text='档位数', style='Hint.TLabel').pack(side='right', padx=(0, 4))
            self._rebuild()
        self._toggle(notify=False)

    def _hint(self):
        spec = T.DIMENSIONS[self.dim]
        if self.dim == 'rx_lo':
            return '填 follow 或相对 TX 本振的偏移'
        if spec.get('words'):
            return '可填 ' + '/'.join(spec['words'])
        return ''

    def _select_all(self, on):
        for v in self.mod_vars.values():
            v.set(on)
        self.panel.changed()

    def _toggle(self, notify=True):
        if self.enabled.get():
            self.body.pack(fill='x', pady=(2, 2))
        else:
            self.body.pack_forget()
        if notify:
            self.panel.changed()

    def _rebuild(self, values=None):
        try:
            n = int(self.count.get())
        except ValueError:
            return
        n = max(1, min(MAX_COUNT, n))
        old = values if values is not None else [v.get() for v in self.value_vars]
        for w in self.body.winfo_children():
            w.destroy()
        self.value_vars, self.value_widgets = [], []
        spec = T.DIMENSIONS[self.dim]
        cols = 3 if spec['kind'] == 'choice' else 5
        for i in range(n):
            var = tk.StringVar(value=old[i] if i < len(old) else '')
            var.trace_add('write', lambda *_: self.panel.changed())
            cell = ttk.Frame(self.body, style='White.TFrame')
            cell.grid(row=i // cols, column=i % cols, sticky='ew', padx=(0, 6), pady=(0, 4))
            ttk.Label(cell, text=f'{i + 1}', style='Hint.TLabel').pack(side='left', padx=(0, 2))
            if spec['kind'] == 'choice':
                if not var.get():
                    var.set(spec['choices'][min(i, len(spec['choices']) - 1)])
                e = ttk.Combobox(cell, textvariable=var, values=spec['choices'], state='readonly',
                                 width=16 if self.dim == 'train_rate' else 9)
            else:
                e = ttk.Entry(cell, textvariable=var, width=8)
            e.pack(side='left')
            self.value_vars.append(var)
            self.value_widgets.append(e)
        for c in range(cols):
            self.body.columnconfigure(c, weight=1)
        self.panel.changed()

    def values(self):
        if not self.enabled.get():
            return None
        if T.DIMENSIONS[self.dim]['kind'] == 'mod':
            return [m for m, v in self.mod_vars.items() if v.get()]
        return [v.get() for v in self.value_vars]

    def load(self, values):
        self.enabled.set(values is not None)
        if values is not None:
            if T.DIMENSIONS[self.dim]['kind'] == 'mod':
                for m, v in self.mod_vars.items():
                    v.set(m in values)
            else:
                self.count.set(str(len(values)))
                self._rebuild(list(values))
        else:
            if T.DIMENSIONS[self.dim]['kind'] == 'mod':
                for v in self.mod_vars.values():
                    v.set(False)
            else:
                self.count.set('1')
                self._rebuild([])
        self._toggle(notify=False)

    def widgets(self):
        out = [self.check]
        if T.DIMENSIONS[self.dim]['kind'] == 'mod':
            out += self.mod_boxes + [self.all_btn, self.none_btn]
        else:
            out += [self.count_entry] + self.value_widgets
        return out


class SegmentEditor:
    """Segment list (name, share) + one sweep editor showing the selected segment."""
    def __init__(self, panel, parent):
        self.panel = panel
        self.segments = [dict(name='段 1', repeats='1', sweep={'modulation': ['4PSK']})]
        self.current = 0
        self.loading = False
        top = ttk.Frame(parent, style='White.TFrame')
        top.pack(fill='x', pady=(0, 6))
        self.list = ttk.Treeview(top, columns=('name', 'combos', 'repeats', 'points', 'share'), show='headings', height=3,
                                 selectmode='browse')
        for col, title, w in (('name', '段', 140), ('combos', '组合数', 60), ('repeats', '重复', 50), ('points', '点数', 60),
                              ('share', '占比', 60)):
            self.list.heading(col, text=title)
            self.list.column(col, width=w, stretch=col == 'name', anchor='w' if col == 'name' else 'center')
        self.list.pack(side='left', fill='x', expand=True)
        self.list.bind('<<TreeviewSelect>>', self._select)
        side = ttk.Frame(top, style='White.TFrame')
        side.pack(side='left', padx=(6, 0))
        self.buttons = []
        for text, cmd in (('添加', self.add), ('复制', self.copy), ('删除', self.remove), ('上移', lambda: self.move(-1)),
                          ('下移', lambda: self.move(1))):
            b = ttk.Button(side, text=text, width=5, command=cmd)
            b.pack(fill='x', pady=(0, 2))
            self.buttons.append(b)
        row = ttk.Frame(parent, style='White.TFrame')
        row.pack(fill='x', pady=(0, 6))
        self.name = tk.StringVar()
        self.repeats = tk.StringVar()
        ttk.Label(row, text='段名', style='Hint.TLabel').pack(side='left')
        self.name_entry = ttk.Entry(row, textvariable=self.name, width=16)
        self.name_entry.pack(side='left', padx=(4, 12))
        ttk.Label(row, text='每组合重复次数', style='Hint.TLabel').pack(side='left')
        self.repeat_entry = ttk.Spinbox(row, from_=1, to=1000, width=6, textvariable=self.repeats)
        self.repeat_entry.pack(side='left', padx=(4, 0))
        self.points_hint = ttk.Label(row, text='', style='Hint.TLabel')
        self.points_hint.pack(side='left', padx=(8, 0))
        self.name.trace_add('write', lambda *_: self._edited())
        self.repeats.trace_add('write', lambda *_: self._edited())
        self.sweep_box = ttk.Frame(parent, style='White.TFrame')
        self.sweep_box.pack(fill='x')
        self.rows = {dim: DimensionRow(panel, self.sweep_box, dim) for dim in T.ORDER}
        self._show(0)

    # The sweep editor always reflects segments[current]; store it back before switching.
    def store(self):
        if self.loading:
            return
        seg = self.segments[self.current]
        seg['sweep'] = {d: row.values() for d, row in self.rows.items() if row.values() is not None}
        seg['name'] = self.name.get()
        seg['repeats'] = self.repeats.get()

    def _show(self, index):
        self.loading = True
        try:
            self.current = index
            seg = self.segments[index]
            self.name.set(seg.get('name', ''))
            self.repeats.set(str(seg.get('repeats', '1')))
            for d, row in self.rows.items():
                row.load(seg['sweep'].get(d))
        finally:
            self.loading = False
        self.refresh_list()

    def _select(self, event=None):
        sel = self.list.selection()
        if not sel or int(sel[0]) == self.current:
            return
        self.store()
        self._show(int(sel[0]))
        self.panel.changed()

    def _edited(self):
        if not self.loading:
            self.store()
            self.refresh_list()
            self.panel.changed()

    def add(self):
        self.store()
        self.segments.append(dict(name=f'段 {len(self.segments) + 1}', repeats='1', sweep={}))
        self._show(len(self.segments) - 1)
        self.panel.changed()

    def copy(self):
        self.store()
        seg = self.segments[self.current]
        dup = dict(name=seg['name'] + ' 副本', repeats=seg.get('repeats', '1'),
                   sweep={k: list(v) for k, v in seg['sweep'].items()})
        self.segments.insert(self.current + 1, dup)
        self._show(self.current + 1)
        self.panel.changed()

    def remove(self):
        if len(self.segments) == 1:
            return
        del self.segments[self.current]
        self._show(min(self.current, len(self.segments) - 1))
        self.panel.changed()

    def move(self, step):
        j = self.current + step
        if not 0 <= j < len(self.segments):
            return
        self.store()
        self.segments[self.current], self.segments[j] = self.segments[j], self.segments[self.current]
        self._show(j)
        self.panel.changed()

    def refresh_list(self, built=None):
        """built: definition['segments'] of the current preview, for combos / points / share."""
        if built is not None:
            self.built = built
        built = getattr(self, 'built', None) or []
        shares = T.segment_shares(dict(segments=built)) if built else []
        self.list.delete(*self.list.get_children())
        for i, seg in enumerate(self.segments):
            if i < len(built):
                combos, points, share = built[i]['combos'], shares[i][0], f'{shares[i][1]:.1f}%'
            else:
                combos = points = share = ''
            self.list.insert('', 'end', iid=str(i),
                             values=(seg.get('name') or f'段 {i + 1}', combos, seg.get('repeats', ''), points, share))
        if self.current < len(built):
            b = built[self.current]
            self.points_hint.configure(text=f'= {b["combos"]} 个组合 × {b["repeats"]} 次 = {b["points"]} 点')
        else:
            self.points_hint.configure(text='')
        self.list.selection_set(str(self.current))
        self.list.see(str(self.current))

    def load(self, segments):
        self.segments = [dict(name=s['name'], repeats=str(s.get('repeats', 1)),
                              sweep={k: list(v) for k, v in s['sweep'].items()}) for s in segments]
        self._show(0)

    def payload(self):
        self.store()
        return [dict(name=s['name'], repeats=s.get('repeats', '1'), sweep=dict(s['sweep'])) for s in self.segments]

    def widgets(self):
        return self.buttons + [self.name_entry, self.repeat_entry] + [w for r in self.rows.values() for w in r.widgets()]


class CampaignPanel:
    def __init__(self, app, parent):
        self.app = app
        self.campaign = None
        self.stage = 'idle'   # idle | configure | uploading | tx2 | capture | stopping | stopping-pause | paused
        self.point = None
        self.point_started = None
        self.session_started = None
        self.after_id = None
        self.shown_rows, self.shown_point = {}, None   # list rows as last drawn
        self.loading = False
        self.settling = False
        # Observation is stopped for the whole batch: each restart costs four
        # board commands that sit in the RFCT replay cache for 60 s.
        self.resume_monitor = False
        box = ttk.LabelFrame(parent, text='批量采集', padding=12)
        box.pack(fill='x', pady=(12, 0))
        self.box = box
        ttk.Label(box, text='任务由若干“段”拼接而成。每段勾选要扫描的参数，各项先填档位数再逐个填值；未勾选的参数取界面当前值。'
                            '每段点数 = 该段组合数 × 该段重复次数，占比由此算出。',
                  style='Hint.TLabel', wraplength=460, justify='left').pack(anchor='w', pady=(0, 8))
        self.editor = SegmentEditor(self, box)
        self.rows = self.editor.rows
        g = ttk.Frame(box, style='White.TFrame')
        g.pack(fill='x', pady=(8, 0))
        self.dead_time = tk.StringVar(value=f'{T.DEFAULT_DEAD_S:g}')
        self.seed_inc = tk.BooleanVar(value=True)
        self.shuffle = tk.BooleanVar(value=False)
        ttk.Label(g, text='死区时间 / s', style='Hint.TLabel').grid(row=0, column=0, sticky='w')
        self.dead_entry = ttk.Entry(g, textvariable=self.dead_time, width=6)
        self.dead_entry.grid(row=0, column=1, sticky='w', padx=(4, 14))
        self.seed_check = ttk.Checkbutton(g, text='每点随机种子 +1', variable=self.seed_inc, command=self.changed)
        self.seed_check.grid(row=0, column=2, sticky='w', padx=(0, 14))
        self.shuffle_check = ttk.Checkbutton(g, text='打乱顺序', variable=self.shuffle, command=self.changed)
        self.shuffle_check.grid(row=0, column=3, sticky='w')
        self.dead_time.trace_add('write', lambda *_: self.changed())
        ttk.Label(box, text='死区：TX 参数读回确认、RX 以新参数启动后再等待这段时间，期间数据丢弃，然后开始录制。'
                            '每点时长、目录和备注取上方训练参数；失败的点重试 1 次后跳过。',
                  style='Hint.TLabel', wraplength=460, justify='left').pack(anchor='w', pady=(6, 0))
        for key in ('train_seconds', 'train_rate', 'train_directory', 'train_tag', 'rx_gain_mode', 'seed', 'center',
                    'offset', 'bandwidth', 'rx_follow', 'rx_center', 'rx_bandwidth', 'modulation',
                    'rx_filter', 'filter_type', 'filter_f1', 'filter_f2', 'filter_ripple', 'filter_stop', 'filter_transition'):
            app.v[key].trace_add('write', lambda *_: self.changed())
        self.plan_label = ttk.Label(box, text='', style='White.TLabel', wraplength=460, justify='left')
        self.plan_label.pack(anchor='w', pady=(8, 6))
        buttons = ttk.Frame(box, style='White.TFrame')
        buttons.pack(fill='x')
        self.start_btn = ttk.Button(buttons, text='开始批量', style='Primary.TButton', command=self.start)
        self.start_btn.pack(side='left')
        self.check_btn = ttk.Button(buttons, text='检查', command=self.check)
        self.check_btn.pack(side='left', padx=(6, 0))
        self.pause_btn = ttk.Button(buttons, text='暂停', command=self.pause)
        self.pause_btn.pack(side='left', padx=(6, 0))
        self.stop_btn = ttk.Button(buttons, text='停止', command=self.stop)
        self.stop_btn.pack(side='left', padx=(6, 0))
        self.export_btn = ttk.Button(buttons, text='导出任务', command=self.export)
        self.export_btn.pack(side='right')
        self.import_btn = ttk.Button(buttons, text='导入任务', command=self.import_)
        self.import_btn.pack(side='right', padx=(0, 6))
        self.total_bar = ttk.Progressbar(box, maximum=100)
        self.total_bar.pack(fill='x', pady=(10, 4))
        self.status = ttk.Label(box, text='未开始', style='White.TLabel', wraplength=460, justify='left')
        self.status.pack(anchor='w')
        lst = ttk.Frame(box, style='White.TFrame')
        lst.pack(fill='both', expand=True, pady=(8, 0))
        self.tree = ttk.Treeview(lst, columns=('n', 'seg', 'point', 'state'), show='headings', height=7)
        for col, title, w in (('n', '#', 50), ('seg', '段', 80), ('point', '参数', 260), ('state', '状态', 80)):
            self.tree.heading(col, text=title)
            self.tree.column(col, width=w, stretch=col == 'point', anchor='w' if col in ('point', 'seg') else 'center')
        bar = ttk.Scrollbar(lst, orient='vertical', command=self.tree.yview)
        self.tree.configure(yscrollcommand=bar.set)
        self.tree.pack(side='left', fill='both', expand=True)
        bar.pack(side='right', fill='y')
        for state, color in (('done', theme.OK), ('failed', theme.ERROR), ('recording', theme.ACCENT)):
            self.tree.tag_configure(state, foreground=color)
        self.changed()

    # ---- definition ----------------------------------------------------
    def tx2_default(self):
        tx = self.app.last_tx
        return bool(tx and tx['applied_mask'] & 2)

    def preview(self):
        """Campaign built from the current panel + GUI draft (not started, not saved)."""
        return T.Campaign.create(self.editor.payload(), self.app.values(), seconds=self.app.v['train_seconds'].get(),
                                 dead_time=self.dead_time.get(), seed_mode='increment' if self.seed_inc.get() else 'fixed',
                                 shuffle=self.shuffle.get(), tag=self.app.v['train_tag'].get().strip(),
                                 tx2_default=self.tx2_default(), directory=self.app.v['train_directory'].get())

    def changed(self):
        if self.loading or self.editor_loading() or not hasattr(self, 'plan_label') or self.running() or self.stage == 'paused':
            return
        try:
            c = self.preview()
            self.editor.refresh_list(c.definition['segments'])
            self.plan_label.configure(text=f'共 {len(c.points)} 点 · {len(c.definition["segments"])} 段 · 每点 {c.definition["seconds"]:g} s'
                                           f' + 死区 {c.definition["dead_time"]:g} s · 预计 {T.format_duration(c.total_seconds())}'
                                           f' · 约 {c.bytes_needed() / 1e9:.2f} GB', foreground=theme.TEXT)
        except (T.CampaignError, ValueError, KeyError) as exc:
            self.editor.refresh_list([])
            self.plan_label.configure(text='待修正：' + str(exc), foreground=theme.ERROR)

    def editor_loading(self):
        return getattr(self, 'editor', None) is not None and self.editor.loading

    def free_bytes(self, campaign):
        ancestor = Path(campaign.directory)
        while not ancestor.exists():
            ancestor = ancestor.parent
        return None if self.app.demo else shutil.disk_usage(ancestor).free

    # ---- check / overview ----------------------------------------------
    def check(self):
        """Run every check on the current definition and show grouped results."""
        try:
            c = self.campaign if self.stage == 'paused' and self.campaign else self.preview()
        except (T.CampaignError, ValueError, KeyError) as exc:
            self.app.log('批量检查：' + str(exc), 'error')
            return messagebox.showerror('批量检查', str(exc), parent=self.app)
        issues = T.check(c, self.free_bytes(c))
        self.app.log(f'批量检查：{len(c.points)} 点，' + ('未发现问题。' if not issues else f'{len(issues)} 类问题。'),
                     'error' if any(i.level == 'error' for i in issues) else 'warning' if any(i.level == 'warning' for i in issues) else 'ok')
        for it in issues:
            self.app.log('  ' + it.text(), it.level)
        self.show_overview(c, issues, confirm=False)
        return issues

    def show_overview(self, campaign, issues, confirm):
        """Modal overview. confirm=True: buttons 确认开始 / 取消; returns True to start."""
        win = tk.Toplevel(self.app)
        win.title('批量采集总览' if confirm else '批量检查结果')
        win.transient(self.app)
        win.configure(bg=theme.SURFACE)
        theme.dark_titlebar(win)
        text = tk.Text(win, width=96, height=30, wrap='word', bg=theme.SURFACE, fg=theme.TEXT, relief='flat', padx=14, pady=12,
                       font=('Microsoft YaHei UI', 10))
        bar = ttk.Scrollbar(win, orient='vertical', command=text.yview)
        text.configure(yscrollcommand=bar.set)
        for tag, color in LEVEL_COLORS.items():
            text.tag_configure(tag, foreground=color)
        text.tag_configure('head', font=('Microsoft YaHei UI', 11, 'bold'), spacing1=10, spacing3=4)
        for tag, line in T.overview_lines(campaign, issues):
            text.insert('end', line + '\n', tag)
        text.configure(state='disabled')
        foot = ttk.Frame(win, padding=10)
        foot.pack(side='bottom', fill='x')
        bar.pack(side='right', fill='y')
        text.pack(side='left', fill='both', expand=True)
        result = dict(ok=False)
        errors = any(i.level == 'error' for i in issues)

        def done(ok):
            result['ok'] = ok
            win.destroy()
        if confirm:
            label = '存在 error，不能开始' if errors else ('有 warning，仍然开始' if issues else '确认开始')
            b = ttk.Button(foot, text=label, style='Primary.TButton', command=lambda: done(True))
            b.pack(side='right')
            if errors:
                b.configure(state='disabled')
            ttk.Button(foot, text='取消', command=lambda: done(False)).pack(side='right', padx=(0, 8))
        else:
            ttk.Button(foot, text='关闭', command=lambda: done(False)).pack(side='right')
        ttk.Button(foot, text='导出总览…', command=lambda: self._save_overview(campaign, issues, win)).pack(side='left')
        win.protocol('WM_DELETE_WINDOW', lambda: done(False))
        self.overview_window = win
        win.grab_set()
        self.app.wait_window(win)
        self.overview_window = None
        return result['ok']

    def _save_overview(self, campaign, issues, parent):
        path = filedialog.asksaveasfilename(parent=parent, title='导出总览', defaultextension='.txt',
                                            initialfile=f'overview_{campaign.id}.txt', filetypes=[('文本', '*.txt')])
        if path:
            Path(path).write_text('\n'.join(t for _, t in T.overview_lines(campaign, issues)) + '\n', encoding='utf-8')

    # ---- run control ---------------------------------------------------
    def running(self):
        return self.stage not in ('idle', 'paused')

    def start(self, confirm=True):
        """Build the campaign, show the overview, start only after confirmation."""
        if self.running():
            return False
        app = self.app
        if not (app.tx_connected and app.rx_connected):
            return self._refuse('批量采集需要 UART 与网口 RX 都已连接。')
        if not app.last_tx or not app.last_tx['applied_mask'] & 1:
            return self._refuse('请先开启 TX1（批量采集保持 TX1 开启，逐点上传参数）。')
        resuming = self.stage == 'paused' and self.campaign is not None
        try:
            campaign = self.campaign if resuming else self.preview()
        except (T.CampaignError, ValueError, KeyError) as exc:
            return self._refuse(str(exc))
        issues = T.check(campaign, self.free_bytes(campaign))
        if confirm:
            if not self.show_overview(campaign, issues, confirm=True):
                self.app.log('批量采集未开始：总览中取消。', 'info')
                return False
        elif any(i.level == 'error' for i in issues):
            return self._refuse('；'.join(i.text() for i in issues if i.level == 'error'))
        for it in issues:
            self.app.log('批量：' + it.text(), it.level)
        self.campaign = campaign
        campaign.save()
        if resuming:
            self.app.log(f'批量采集继续：{campaign.id}，待录 {campaign.counts()["pending"]} 点。', 'info')
        else:
            self.app.log(f'批量采集开始：{len(campaign.points)} 点，任务文件 {campaign.path}', 'info')
            self._fill_tree()
        self.session_started = time.monotonic()
        self._stop_observation()
        self.stage = 'configure'
        self._schedule(10)
        self.refresh()
        return True

    def _stop_observation(self):
        """Stop the observation once for the batch; points then upload and record without RX restarts."""
        app = self.app
        if app.monitoring or app.monitor_pending or app.monitor_requested:
            self.resume_monitor = True
            app.monitor_requested = False
            if app.monitoring or app.monitor_pending:
                app.monitor_stopping = True
                app.worker.stop_monitor.set()
            self.app.log('批量期间暂停接收观测（逐点重启会占满板端命令缓存），结束后恢复。', 'info')

    def _restore_observation(self):
        """Reopen the observation that ran before the batch, once the board is idle."""
        app = self.app
        if not self.resume_monitor or self.running():
            return
        if app.closing or not app.rx_connected or app.emergency_waiting or app.emergency_failed:
            self.resume_monitor = False
            return
        if app.monitoring or app.monitor_pending:
            self.resume_monitor = False
            return
        if app.pending or app.recording or app.capture_pending or app.monitor_stopping or app.upload_job:
            app.after(200, self._restore_observation)
            return
        self.resume_monitor = False
        app.monitor_requested = True
        app.start_monitor()

    def pause(self):
        if not self.running():
            return
        self.stage = 'stopping-pause'
        self.app.log('批量采集将在当前点完成后暂停。', 'info')
        self.refresh()

    def stop(self):
        if self.stage == 'paused':
            self._finish('已停止')
            return
        if not self.running():
            return
        self.stage = 'stopping'
        if self.app.recording or self.app.capture_pending:
            self.app.stop_recording()
        self.app.log('批量采集停止：当前点中止，下次续录时重录该点。', 'warning')
        self.refresh()
        self._schedule(50)

    def abort(self, reason):
        """Emergency stop / disconnect: stop sequencing immediately, keep the file for resume."""
        if self.campaign and self.stage != 'idle':
            if self.point and self.point.state == 'recording':
                self.point.state = 'pending'
            self._account()
            self._save()
            self.stage = 'idle'
            self.point = None
            self.app.log(f'批量采集中止：{reason}。可导入任务文件继续。', 'error')
            self.refresh()
            self._restore_observation()

    def _refuse(self, text):
        self.app.log('无法开始批量采集：' + text.replace('\n', '；'), 'error')
        messagebox.showerror('无法开始批量采集', text, parent=self.app)
        return False

    # ---- state machine -------------------------------------------------
    def _schedule(self, ms):
        if self.after_id:
            try:
                self.app.after_cancel(self.after_id)
            except Exception:
                pass
        self.after_id = self.app.after(ms, self._step)

    def _busy(self):
        app = self.app
        return bool(app.upload_job or app.pending - {'monitor'} or app.recording or app.capture_pending
                    or app.monitor_pending or app.monitor_stopping)

    def _step(self):
        self.after_id = None
        app = self.app
        if self.stage in ('idle', 'paused') or app.closing:
            return
        if self.stage in ('stopping', 'stopping-pause'):
            if self._busy():
                return self._schedule(100)
            if self.point and self.point.state == 'recording':
                self.point.state = 'pending'
            self.point = None
            self._account()
            self._save()
            if self.stage == 'stopping-pause':
                self.stage = 'paused'
                self.app.log('批量采集已暂停；点“继续批量”继续。', 'info')
                self.refresh()
                self._restore_observation()
            else:
                self._finish('已停止')
            return
        if self.stage == 'configure':
            if self._busy():
                return self._schedule(100)
            point = self.campaign.next_point()
            if point is None:
                return self._finish('完成')
            self.point = point
            self.point_started = time.monotonic()
            point.state = 'recording'
            point.attempts += 1
            point.started = time.strftime('%Y-%m-%dT%H:%M:%S')
            values = T.point_values(point, self.campaign.base)
            # GUI traces react to each write: while rx_follow is still '1' a center change
            # copies TX LO into rx_center. Set follow first, the RX center last.
            order = ['rx_follow', 'center'] + [k for k in values if k not in ('rx_follow', 'center', 'rx_center')] + ['rx_center']
            for key in order:
                value = values.get(key)
                if value is not None and key in app.v and app.v[key].get() != value:
                    app.v[key].set(value)
            self.refresh()
            app.log(f'批量 #{point.index + 1}/{len(self.campaign.points)}（{self.campaign.segment_name(point)}）：{point.label()}', 'info')
            if app.upload_dirty():
                app.upload()
                if not app.upload_job:
                    return self._point_failed('upload 未提交')
                self.stage = 'uploading'
                return self._schedule(100)
            self.stage = 'tx2'
            return self._schedule(10)
        if self.stage == 'uploading':
            if app.upload_job:
                return self._schedule(100)
            if app.upload_failed:
                return self._point_failed('upload 失败')
            self.stage = 'tx2'
            return self._schedule(10)
        if self.stage == 'tx2':
            if self._busy():
                return self._schedule(100)
            tx = app.last_tx
            if not tx or not tx['applied_mask'] & 1:
                return self._point_failed('TX1 未开启')
            want = T.point_tx2(self.point, self.campaign.definition)
            if want is not None and bool(tx['applied_mask'] & 2) != want:
                # The TX2 switch stays locked for the user; the runner sends the same
                # 'enable' action directly and waits for the board readback.
                if getattr(self, 'tx2_requested', None) == want:
                    return self._schedule(100)
                self.tx2_requested = want
                app.log(f'批量：TX2 {"开启" if want else "关闭"}', 'info')
                if not app.send('enable', tx2=want):
                    self.tx2_requested = None
                    return self._point_failed('TX2 开关未能提交')
                return self._schedule(200)
            self.tx2_requested = None
            self.stage = 'capture'
            p = self.point
            d = self.campaign.definition
            info = dict(id=self.campaign.id, point=p.index, total=len(self.campaign.points), segment=p.segment,
                        segment_name=self.campaign.segment_name(p), values=p.values, repeat=p.repeat, seed=p.seed,
                        attempt=p.attempts, dead_time_seconds=d['dead_time'], file=str(self.campaign.path))
            fs = T.point_fs(T.point_values(p, self.campaign.base))
            if not app.start_training_capture(campaign=info, discard_seconds=d['dead_time'], rate=fs):
                return self._point_failed(getattr(app, 'last_training_refusal', '') or '训练采集未能开始')
            return
        # 'capture': completion arrives through on_capture_finished().

    def on_capture_settling(self, seconds):
        if self.stage == 'capture':
            self.settling = True
            self.refresh()

    def on_capture_started(self):
        self.settling = False

    def on_capture_finished(self, path, metadata, error):
        self.settling = False
        if self.stage not in ('capture', 'stopping', 'stopping-pause') or not self.point:
            return
        p = self.point
        if self.stage in ('stopping', 'stopping-pause'):
            p.state, p.error = 'pending', '用户停止'
            self._schedule(10)
            return
        reasons = [r for r in metadata.get('automatic_label_exclusion_reasons', []) if r != 'offline_demo_not_RF_training_data']
        if error or reasons:
            return self._point_failed(error or '已被排除：' + ','.join(reasons))
        p.files = (p.files or []) + [str(Path(path).with_suffix(''))]
        p.state, p.error = 'done', ''
        p.finished = time.strftime('%Y-%m-%dT%H:%M:%S')
        overhead = time.monotonic() - self.point_started - self.campaign.definition['seconds']
        if 0 <= overhead < 600:
            self.campaign.overheads.append(round(overhead, 2))
        self._account()
        self._save()
        self.point = None
        self.stage = 'configure'
        self.refresh()
        self._schedule(10)

    def on_capture_error(self, message):
        if self.stage == 'capture' and self.point and not self.app.recording:
            self._point_failed(message)

    def _point_failed(self, reason):
        p = self.point
        if p is None:
            return
        self.settling = False
        retries = int(self.campaign.definition.get('retries', 1))
        p.error = reason
        if p.attempts <= retries:
            p.state = 'pending'
            self.app.log(f'批量 #{p.index + 1} 失败（{reason}），重试第 {p.attempts} 次。', 'warning')
        else:
            p.state = 'failed'
            p.finished = time.strftime('%Y-%m-%dT%H:%M:%S')
            self.app.log(f'批量 #{p.index + 1} 失败（{reason}），已跳过。', 'error')
        self.point = None
        self._account()
        self._save()
        if self.stage not in ('stopping', 'stopping-pause'):
            self.stage = 'configure'
        self.refresh()
        self._schedule(500)

    def _account(self):
        if self.session_started is not None and self.campaign:
            now = time.monotonic()
            self.campaign.elapsed += now - self.session_started
            self.session_started = now

    def _save(self):
        if self.campaign:
            try:
                self.campaign.save()
            except OSError as exc:
                self.app.log('任务文件保存失败：' + str(exc), 'error')

    def _finish(self, how):
        c = self.campaign
        self._account()
        self.session_started = None
        self._save()
        self.stage = 'idle'
        self.point = None
        if c:
            n = c.counts()
            failed = c.failed_points()
            self.app.log(f'批量采集{how}：完成 {n["done"]}，失败 {n["failed"]}，未录 {n["pending"]}；任务文件 {c.path}',
                         'error' if failed else 'ok')
            for p in failed[:10]:
                self.app.log(f'  失败 #{p.index + 1} {p.label()}：{p.error}', 'error')
        self.refresh()
        self._restore_observation()

    # ---- export / import ----------------------------------------------
    def export(self):
        c = self.campaign
        if c is None:
            try:
                c = self.preview()
            except (T.CampaignError, ValueError, KeyError) as exc:
                return self._refuse(str(exc))
        path = filedialog.asksaveasfilename(parent=self.app, title='导出批量任务', defaultextension='.json',
                                            initialfile=c.path.name, filetypes=[('批量任务', '*.json')])
        if path:
            self.export_to(path, c)

    def export_to(self, path, campaign=None):
        c = campaign or self.campaign
        c.save(path)
        self.app.log(f'批量任务已导出：{path}（{c.counts()["done"]}/{len(c.points)} 点完成）', 'ok')

    def import_(self):
        if self.running():
            return
        path = filedialog.askopenfilename(parent=self.app, title='导入批量任务', filetypes=[('批量任务', '*.json')])
        if path:
            self.import_from(path, ask=True)

    def import_from(self, path, ask=False):
        if self.running():
            raise T.CampaignError('批量采集进行中，不能导入。')
        c = T.Campaign.load(path)
        reset = c.verify()
        current = self.app.values()
        differences = [(k, current.get(k), v) for k, v in c.base.items()
                       if k in self.app.v and current.get(k) != v and k not in ('directory', 'filename')]
        n = c.counts()
        text = (f'任务 {c.id}：{len(c.definition["segments"])} 段，共 {len(c.points)} 点，已完成 {n["done"]}，'
                f'失败 {n["failed"]}，待录 {n["pending"]}。\n'
                + (f'核对后改回待录 {len(reset)} 点（首个：#{reset[0][0] + 1} {reset[0][1]}）。\n' if reset else '')
                + (f'将用任务中的 {len(differences)} 项参数覆盖界面（如 {differences[0][0]}：{differences[0][1]} → {differences[0][2]}）。\n' if differences else '')
                + '失败的点会重新尝试。')
        if ask and not messagebox.askokcancel('导入批量任务', text + '\n\n继续？', parent=self.app):
            return None
        for p in c.points:
            if p.state == 'failed':
                p.state, p.attempts = 'pending', 0
        d = c.definition
        self.loading = True
        try:
            for key, value in c.base.items():
                if key in self.app.v:
                    self.app.v[key].set(value)
            self.editor.load(d['segments'])
            self.dead_time.set(f'{d["dead_time"]:g}')
            self.seed_inc.set(bool(d.get('seed_step')))
            self.shuffle.set(bool(d.get('shuffle')))
        finally:
            self.loading = False
        self.campaign = c
        self.stage = 'paused'
        self.editor.refresh_list(d['segments'])
        c.save()
        self._fill_tree()
        self.app.log('已导入批量任务：' + text.replace('\n', ' '), 'info')
        for idx, why in reset[:10]:
            self.app.log(f'  #{idx + 1} 改回待录：{why}', 'warning')
        self.refresh()
        return c

    # ---- display -------------------------------------------------------
    def _row(self, p):
        state = STATE_TEXT[p.state] + (f'（{p.error}）' if p.state == 'failed' and p.error else '')
        return (p.index + 1, self.campaign.segment_name(p), p.label(), state)

    def _fill_tree(self):
        self.tree.delete(*self.tree.get_children())
        self.shown_rows, self.shown_point = {}, None
        for p in self.campaign.points:
            row = (self._row(p), p.state)
            self.tree.insert('', 'end', iid=str(p.index), values=row[0], tags=(row[1],))
            self.shown_rows[str(p.index)] = row

    def refresh(self):
        c = self.campaign
        if c is None:
            self.total_bar['value'] = 0
            self.status.configure(text='未开始')
        else:
            n = c.counts()
            total = len(c.points)
            finished = n['done'] + n['failed']
            frac = finished / total if total else 0
            if self.point and self.app.recording and not self.settling:
                frac += min(1, self.app.training_progress['value'] / 100) / total
            self.total_bar['value'] = 100 * frac
            elapsed = c.elapsed + (time.monotonic() - self.session_started if self.session_started else 0)
            if self.point:
                phase = ' · 死区等待' if self.settling else ' · 上传参数' if self.stage in ('configure', 'uploading', 'tx2') else ''
                current = f'第 {self.point.index + 1} / {total} 点（{c.segment_name(self.point)}）· {self.point.label()}{phase}'
            else:
                current = f'{finished} / {total} 点'
            state = dict(idle='已结束' if finished == total else '未运行', paused='已暂停', stopping='正在停止…',
                         **{'stopping-pause': '当前点完成后暂停…'}).get(self.stage, '运行中')
            self.status.configure(text=f'{state} · {current}\n完成 {n["done"]} · 失败 {n["failed"]} · 待录 {n["pending"] + n["recording"]}'
                                       f' · 已用 {T.format_duration(elapsed)} · 预计剩余 {T.format_duration(c.remaining_seconds())}')
            # Rewrite only rows whose text/state changed; touching every row each
            # second costs O(points) Tk calls.
            shown = self.shown_rows
            for p in c.points:
                iid = str(p.index)
                row = (self._row(p), p.state)
                if shown.get(iid) != row and self.tree.exists(iid):
                    self.tree.item(iid, values=row[0], tags=(row[1],))
                    shown[iid] = row
            # Scroll to the current point once when it changes, so the user can
            # browse the list while a point records.
            current = self.point.index if self.point else None
            if current is not None and current != self.shown_point and self.tree.exists(str(current)):
                self.tree.see(str(current))
            self.shown_point = current
        self.update_controls()

    def update_controls(self):
        app = self.app
        running = self.running()
        editable = not running and self.stage != 'paused'
        connected = app.tx_connected and app.rx_connected
        busy = bool(app.pending - {'monitor'}) or app.recording or app.capture_pending
        enable = lambda w, yes: w.configure(state='normal' if yes else 'disabled')
        enable(self.start_btn, not running and connected and not busy and not app.emergency_waiting)
        self.start_btn.configure(text='继续批量' if self.stage == 'paused' else '开始批量')
        enable(self.check_btn, not running)
        enable(self.pause_btn, self.stage in ('configure', 'uploading', 'tx2', 'capture'))
        enable(self.stop_btn, self.stage != 'idle')
        enable(self.import_btn, not running)
        enable(self.export_btn, True)
        for w in self.editor.widgets() + [self.dead_entry, self.seed_check, self.shuffle_check]:
            try:
                if isinstance(w, ttk.Combobox):
                    w.configure(state='readonly' if editable else 'disabled')
                else:
                    w.configure(state='normal' if editable else 'disabled')
            except tk.TclError:
                pass

    def tick(self):
        if self.campaign and self.running():
            self.refresh()
