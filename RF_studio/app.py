"""KU5P desktop control panel. Python 3.10+ / Tk, standard library only."""
from __future__ import annotations
import ctypes
import json
import math
import os
import queue
import shutil
import sys
import time
import tkinter as tk
import tkinter.font as tkfont
from datetime import datetime
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

from backend import BASE, RadioWorker, waveform, recording_options, training_options, MODES
from training_capture import configuration_snapshot, training_basename, verify_training_tx, verify_training_band
from signal_view import SignalView
from controls import SlideSwitch, UploadButton
from console import Console
from command_interface import CommandInterface
from band_check import check as band_check, tx1_band
from campaign_view import CampaignPanel
from analysis_view import AnalysisDashboard
from model_view import ModelTester
from ui_parameters import (UI_MODES, EXTRA_DEFAULTS, SPECIAL_FIELDS, mode_fields, display_mode,
                           validate_draft, validate_tx, validate_rx, active_parameters, tx_firmware_reason, rx_firmware_reason,
                           HW06_FIXED_RX, normalize_hw06_draft, FILTER_TYPES, FILTER_KEYS, filter_spec,
                           rf_occupancy, baseband_firmware_warning)
import rx_filter
from radio_links import serial_ports
from rf_protocol import RFConfig
import theme
from theme import BG, TEXT, MUTED, SURFACE, FIELD, RAISED, BORDER, HEADER, DISABLED, OK, WARN, CRITICAL, ERROR, ACCENT

DEFAULTS = dict(bind='192.168.10.1', peer='192.168.10.2', modulation='4PSK', center='2400',
                serial_port='COM3',baud='115200',
                bandwidth='1', offset='0', snr='10', atten1='20', atten2='30',
                noise_low='-0.5', noise_high='0.5', seed='0x12345678', am_depth='0.5',
                seconds='10', rate='1 MSPS · FIR 抽取', directory=str(BASE/'captures'),
                train_seconds='2', train_rate='1 MSPS · FIR 抽取', train_tag='',
                train_directory=str(BASE/'captures'/'training'))
DEFAULTS.update(EXTRA_DEFAULTS)
BLUE = theme.BLUE
STATES = {0:'空闲', 1:'配置中', 2:'采集中', 3:'停止中', 4:'故障'}


class ScrollPage(ttk.Frame):
    def __init__(self,parent):
        super().__init__(parent,style='White.TFrame')
        self.canvas=tk.Canvas(self,bg=SURFACE,highlightthickness=0,width=440)
        bar=ttk.Scrollbar(self,orient='vertical',command=self.canvas.yview)
        bar.pack(side='right',fill='y')
        self.canvas.pack(side='left',fill='both',expand=True)
        self.canvas.configure(yscrollcommand=bar.set)
        self.content=ttk.Frame(self.canvas,style='White.TFrame',padding=16)
        window=self.canvas.create_window(0,0,window=self.content,anchor='nw')
        self.canvas.bind('<Configure>',lambda e:self.canvas.itemconfigure(window,width=e.width))
        self.content.bind('<Configure>',self.reflow)
        self.bind_all('<MouseWheel>',self.wheel,add='+')

    def reflow(self,event=None):
        self.canvas.configure(scrollregion=self.canvas.bbox('all'))
        # A hidden page has no real width (canvas 1 px); its labels' masters then size
        # to the labels themselves and wraplength chases its own result forever.
        if self.canvas.winfo_width()<=120:return
        def visit(parent):
            for widget in parent.winfo_children():
                if isinstance(widget,ttk.Label) and widget.cget('wraplength'):
                    width=widget.master.winfo_width()-12
                    if width>120 and int(float(widget.cget('wraplength')))!=width:
                        widget.configure(wraplength=width)
                visit(widget)
        visit(self.content)

    def wheel(self,event):
        widget=event.widget
        if isinstance(widget,(tk.Text,ttk.Combobox)):
            return
        while widget is not None:
            if widget==self:
                self.canvas.yview_scroll(-int(event.delta/120),'units')
                return
            widget=getattr(widget,'master',None)


class Application(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('KU5P Radio Studio')
        icon_path=Path(__file__).resolve().parent/'assets'/'radio.png'
        if icon_path.exists():
            self.window_icon=tk.PhotoImage(file=str(icon_path))
            self.iconphoto(True,self.window_icon)
        scale=max(1,float(self.tk.call('tk','scaling'))/(96/72))
        sw,sh=self.winfo_screenwidth(),self.winfo_screenheight()
        width,height=min(int(1720*scale),sw-100),min(int(1050*scale),sh-100)
        self.geometry(f'{width}x{height}+{max(20,(sw-width)//2)}+{max(20,(sh-height)//2)}')
        self.minsize(min(int(1160*scale),sw-100),min(int(780*scale),sh-100))
        self.configure(bg=BG)
        theme.dark_titlebar(self)
        self.protocol('WM_DELETE_WINDOW', self.close)
        self.settings = BASE/'settings.json'
        defaults = dict(DEFAULTS)
        try:
            saved = json.loads(self.settings.read_text(encoding='utf-8'))
            defaults.update({k:str(v) for k,v in saved.items() if k in defaults})
        except (OSError, ValueError, AttributeError):
            pass
        normalized=normalize_hw06_draft(defaults)
        self.v = {k:tk.StringVar(value=value) for k,value in defaults.items()}
        self.v['filename'] = tk.StringVar(value=self.new_name())
        self.v['modulation'].set(display_mode(self.v['modulation'].get()))
        self.demo_choice = tk.BooleanVar(value=False)
        self.connected = False
        self.tx_connected=False;self.rx_connected=False
        self.demo = False
        self.recording = False
        self.capture_pending = False
        self.capture_mode = None
        self.capture_stopping = False
        self.monitor_requested = False
        self.monitoring = False
        self.monitor_pending = False
        self.monitor_stopping = False
        self.monitor_unknown = False
        self.after_monitor_action = None
        self.emergency_waiting = False
        self.emergency_failed = False
        self.closing = False
        self.pending = set()
        self.last_tx = None
        self.last_rx = None
        self.last_capture_path = None
        self.status_document = {}
        self.status_at = None
        # Upload state: parameters reach the board only through the header button.
        self.upload_job = None
        self.upload_failed = False
        self.uploaded_snapshot = None
        self.uploaded_links = frozenset()
        self.band_findings = ()
        self.commands = CommandInterface(self)
        self.worker = RadioWorker()
        self.edit_fields=[]
        self.parameter_frames={}
        self.parameter_widgets={}
        self._styles()
        self._build()
        self._refresh_controls()
        for key in ('center','bandwidth','offset','snr','tx1_noise','atten1','atten2','noise_low','noise_high','seed','am_depth','modulation',
                    'sideband','carrier_ratio','fm_index','rolloff'):
            self.v[key].trace_add('write', lambda *_: self.update_plan())
        for key in ('rx_center','rx_bandwidth','rx_gain_mode','rx_gain','rx_follow'):
            self.v[key].trace_add('write',lambda *_:self.update_rx_plan())
        for key in ('seconds','rate'):
            self.v[key].trace_add('write', lambda *_: self.update_estimate())
        for key in ('train_seconds','train_rate','train_tag')+FILTER_KEYS:
            self.v[key].trace_add('write', lambda *_: self.update_training_preview())
        for key in FILTER_KEYS+('rate',):
            self.v[key].trace_add('write', lambda *_: self.update_filter_note())
        self.v['rate'].trace_add('write', lambda *_: self._refresh_controls())
        self.update_plan()
        self.update_rx_plan()
        self.update_estimate()
        self.update_training_preview()
        self.log('界面已就绪。先连接开发板；无硬件可勾选“离线演示”。')
        if normalized:self.log('已将旧草稿的固定项恢复为 当前参数值：'+', '.join(normalized)+'；未发送到硬件。')
        self.after(60, self.events)
        self.after(1000, self.clock)

    @staticmethod
    def new_name():
        return datetime.now().strftime('RX1_%Y%m%d_%H%M%S_%f')

    def _styles(self):
        s = ttk.Style(self)
        s.theme_use('clam')
        self.option_add('*Font', ('Microsoft YaHei UI',10))
        # Combobox drop-down lists are plain Tk listboxes: colour them via the option database.
        for key,value in (('*TCombobox*Listbox.background',FIELD),('*TCombobox*Listbox.foreground',TEXT),
                          ('*TCombobox*Listbox.selectBackground',BLUE),('*TCombobox*Listbox.selectForeground','white'),
                          ('*Menu.background',SURFACE),('*Menu.foreground',TEXT)):
            self.option_add(key,value)
        s.configure('.', font=('Microsoft YaHei UI',10), foreground=TEXT, background=BG, fieldbackground=FIELD,
                    bordercolor=BORDER, lightcolor=BORDER, darkcolor=BORDER, troughcolor=BG,
                    selectbackground=BLUE, selectforeground='white', insertcolor=TEXT)
        s.map('.', foreground=[('disabled',DISABLED)])
        s.configure('TFrame', background=BG)
        s.configure('White.TFrame', background=SURFACE)
        s.configure('TLabel', background=BG, foreground=TEXT)
        s.configure('White.TLabel', background=SURFACE, foreground=TEXT)
        s.configure('Muted.TLabel', foreground=MUTED)
        s.configure('Hint.TLabel', foreground=MUTED, background=SURFACE, font=('Microsoft YaHei UI',9))
        s.configure('Title.TLabel', foreground=TEXT, background=SURFACE, font=('Microsoft YaHei UI',13,'bold'))
        s.configure('TButton', padding=(12,7), background=RAISED, foreground=TEXT, borderwidth=0)
        s.map('TButton', background=[('active','#2d4166'),('disabled','#1a2639')], foreground=[('disabled',DISABLED)])
        s.configure('Primary.TButton', background=BLUE, foreground='white', font=('Microsoft YaHei UI',10,'bold'))
        s.map('Primary.TButton', background=[('active','#5a8fff'),('disabled','#22365c')], foreground=[('disabled','#7b8eb0')])
        s.configure('Danger.TButton', background='#3a1d26', foreground='#ff8c99')
        s.map('Danger.TButton', background=[('active','#4d2431'),('disabled','#241a20')],foreground=[('disabled','#6e5860')])
        s.configure('Emergency.TButton',background='#c4263d',foreground='white',padding=(20,12),font=('Microsoft YaHei UI',11,'bold'))
        s.map('Emergency.TButton',background=[('active','#dc3a52'),('disabled','#4a2530')],foreground=[('disabled','#9a7a82')])
        s.configure('TEntry', padding=(8,7), fieldbackground=FIELD, foreground=TEXT, insertcolor=TEXT, bordercolor=BORDER, lightcolor=BORDER, darkcolor=BORDER)
        s.map('TEntry', fieldbackground=[('readonly',SURFACE),('disabled',SURFACE)], foreground=[('disabled',DISABLED)],
              bordercolor=[('focus',BLUE)], lightcolor=[('focus',BLUE)])
        for name in ('TCombobox','TSpinbox'):
            s.configure(name, padding=(6,7), fieldbackground=FIELD, background=RAISED, foreground=TEXT, arrowcolor=TEXT,
                        insertcolor=TEXT, bordercolor=BORDER, lightcolor=BORDER, darkcolor=BORDER)
            s.map(name, fieldbackground=[('readonly',FIELD),('disabled',SURFACE)], foreground=[('disabled',DISABLED)],
                  selectbackground=[('readonly',FIELD)], selectforeground=[('readonly',TEXT)],
                  background=[('active','#2d4166')], arrowcolor=[('disabled',DISABLED)], bordercolor=[('focus',BLUE)])
        s.configure('TNotebook', background=BG, borderwidth=0)
        s.configure('TNotebook.Tab', padding=(10,10), background='#1a2740', foreground=MUTED, bordercolor=BG, lightcolor=BG)
        s.map('TNotebook.Tab', background=[('selected',SURFACE),('active','#1f2e4a')], foreground=[('selected',ACCENT),('active',TEXT)])
        # The only checkbutton on BG is 离线演示; every other one sits on a panel.
        s.configure('TCheckbutton', background=SURFACE, foreground=TEXT, indicatorbackground=FIELD, indicatorforeground=TEXT)
        s.configure('Body.TCheckbutton', background=BG)
        s.map('TCheckbutton', background=[('active',SURFACE)], indicatorbackground=[('selected',BLUE),('disabled',SURFACE)],
              indicatorforeground=[('selected','white')])
        s.map('Body.TCheckbutton', background=[('active',BG)])
        s.configure('Horizontal.TProgressbar', background=BLUE, troughcolor=RAISED, borderwidth=0, lightcolor=BLUE, darkcolor=BLUE)
        s.configure('Vertical.TScrollbar', background=RAISED, troughcolor=SURFACE, arrowcolor=MUTED, bordercolor=SURFACE)
        s.map('Vertical.TScrollbar', background=[('active','#2d4166')])
        s.configure('TSeparator', background=BORDER)
        s.configure('TPanedwindow', background=BG)
        s.configure('Sash', sashthickness=6, gripcount=0, background=BG, lightcolor=BG, bordercolor=BG)
        s.configure('TLabelframe', background=SURFACE, bordercolor=BORDER, lightcolor=BORDER, darkcolor=BORDER)
        s.configure('TLabelframe.Label', background=SURFACE, foreground=TEXT, font=('Microsoft YaHei UI',10,'bold'))
        s.configure('Treeview', background=FIELD, fieldbackground=FIELD, foreground=TEXT, bordercolor=BORDER, rowheight=24)
        s.map('Treeview', background=[('selected','#24406e')], foreground=[('selected','white')])
        s.configure('Treeview.Heading', background=RAISED, foreground=TEXT, bordercolor=BORDER, lightcolor=RAISED, darkcolor=RAISED)
        s.map('Treeview.Heading', background=[('active','#2d4166')])

    def _build(self):
        header = tk.Frame(self,bg=HEADER,height=82)
        header.pack(fill='x')
        header.pack_propagate(False)
        tk.Label(header,text='KU5P  /  RADIO STUDIO',bg=HEADER,fg='white',font=('Segoe UI',19,'bold')).pack(side='left',padx=24)
        self.header_mode = tk.Label(header,text='TX 串口控制 · RX 网口接收',bg=HEADER,fg='#a9c0df',font=('Microsoft YaHei UI',11))
        self.header_mode.pack(side='right',padx=24)
        self.version_label=tk.Label(header,text='版本信息：上位机 12.1 · 固件待读取 · 控制协议 RX v1 / TX v2',bg=HEADER,fg='#7f97b6',font=('Microsoft YaHei UI',9))
        self.version_label.pack(side='right',padx=(0,8))
        body=ttk.Frame(self,padding=(20,14,20,10))
        body.pack(fill='both',expand=True)
        network=ttk.Frame(body)
        network.pack(fill='x',pady=(0,12))
        # Shared columns keep both connection rows aligned at every DPI setting.
        network.columnconfigure(8,weight=1)
        uart_tools=ttk.Frame(network)
        uart_tools.grid(row=0,column=9,sticky='e',pady=(0,7))
        rx_tools=ttk.Frame(network)
        rx_tools.grid(row=1,column=9,sticky='e')
        ttk.Label(network,text='UART · 发射控制').grid(row=0,column=0,sticky='w',padx=(0,12),pady=(0,7))
        ttk.Label(network,text='串口').grid(row=0,column=1,sticky='w',padx=(0,8),pady=(0,7))
        self.port_entry=ttk.Combobox(network,textvariable=self.v['serial_port'],values=serial_ports(),width=16)
        self.port_entry.grid(row=0,column=2,sticky='ew',padx=(0,16),pady=(0,7))
        self.port_refresh_btn=ttk.Button(uart_tools,text='刷新串口',command=lambda:self.port_entry.configure(values=serial_ports()))
        self.port_refresh_btn.pack(side='left',padx=(8,8))
        ttk.Label(network,text='波特率').grid(row=0,column=3,sticky='w',padx=(0,8),pady=(0,7))
        self.baud_entry=ttk.Combobox(network,textvariable=self.v['baud'],values=['115200'],state='readonly',width=16)
        self.baud_entry.grid(row=0,column=4,sticky='ew',padx=(0,16),pady=(0,7))
        self.connect_btn=ttk.Button(network,text='连接 UART',style='Primary.TButton',command=self.connect)
        self.connect_btn.grid(row=0,column=5,sticky='ew',padx=(0,8),pady=(0,7))
        self.disconnect_btn=ttk.Button(network,text='断开 UART',command=lambda:self.send('disconnect'))
        self.disconnect_btn.grid(row=0,column=6,sticky='ew',pady=(0,7))
        self.uart_state=ttk.Label(network,text='UART 未连接',style='Muted.TLabel')
        self.uart_state.grid(row=0,column=7,sticky='w',padx=10,pady=(0,7))
        self.demo_check=ttk.Checkbutton(uart_tools,text='离线演示',variable=self.demo_choice,style='Body.TCheckbutton')
        self.demo_check.pack(side='left')
        ttk.Label(network,text='网口 · RX / IQ').grid(row=1,column=0,sticky='w',padx=(0,12))
        ttk.Label(network,text='本机 IP').grid(row=1,column=1,sticky='w',padx=(0,8))
        self.bind_entry=ttk.Entry(network,textvariable=self.v['bind'],width=16)
        self.bind_entry.grid(row=1,column=2,sticky='ew',padx=(0,16))
        ttk.Label(network,text='KU5P IP').grid(row=1,column=3,sticky='w',padx=(0,8))
        self.peer_entry=ttk.Entry(network,textvariable=self.v['peer'],width=16)
        self.peer_entry.grid(row=1,column=4,sticky='ew',padx=(0,16))
        self.rx_connect_btn=ttk.Button(network,text='连接网口 RX',style='Primary.TButton',command=self.connect_rx)
        self.rx_connect_btn.grid(row=1,column=5,sticky='ew',padx=(0,8))
        self.rx_disconnect_btn=ttk.Button(network,text='断开网口',command=lambda:self.send('disconnect_rx'))
        self.rx_disconnect_btn.grid(row=1,column=6,sticky='ew')
        self.net_state=ttk.Label(network,text='RX 未连接',style='Muted.TLabel')
        self.net_state.grid(row=1,column=7,sticky='w',padx=10)
        self.training_mode_btn=ttk.Button(rx_tools,text='训练模式',style='Primary.TButton',command=self.open_training_mode)
        self.training_mode_btn.pack(side='left',padx=(8,8))
        self.refresh_btn=ttk.Button(rx_tools,text='刷新状态',command=lambda:self.send('status'))
        self.refresh_btn.pack(side='left')

        cards=ttk.Frame(body)
        cards.pack(fill='x',pady=(0,12))
        self.card_values={}
        for i,(key,title) in enumerate((('link','控制连接 / 射频'),('tx1','TX1 · 调制信号'),('tx2','TX2 · 噪声干扰'),('rx','RX1 · 接收状态'))):
            cards.columnconfigure(i,weight=1,uniform='status')
            f=ttk.Frame(cards,style='White.TFrame',padding=(16,12))
            f.grid(row=0,column=i,sticky='nsew',padx=(0,10 if i<3 else 0))
            ttk.Label(f,text=title,style='Hint.TLabel').pack(anchor='w')
            label=tk.Label(f,text='未连接' if key=='link' else '未知',font=('Microsoft YaHei UI',16,'bold'),bg=SURFACE,fg=MUTED,anchor='w')
            label.pack(anchor='w',pady=(4,0))
            self.card_values[key]=label
            if key=='link':
                self.rf_state_label=ttk.Label(f,text='射频状态未读回',style='Hint.TLabel',wraplength=350)
                self.rf_state_label.pack(anchor='w',pady=(4,0))
        self.notice=tk.Label(body,text='TX 通过 UART 控制；RX 配置与 IQ 通过网口传输。参数修改后点参数页右上角 upload 生效。',bg='#132a4a',fg='#9cc0f0',anchor='w',padx=12,pady=8,font=('Microsoft YaHei UI',9))
        self.notice.pack(fill='x',pady=(0,12))

        panes=ttk.Panedwindow(body,orient='horizontal')
        panes.pack(fill='both',expand=True)
        left=ttk.Frame(panes)
        right=ttk.Frame(panes,style='White.TFrame')
        panes.add(left,weight=1)
        panes.add(right,weight=2)
        self.analysis_panes,self.parameter_pane=panes,left
        self.parameter_sash=None
        self.after_idle(lambda:panes.sashpos(0,round(self.winfo_width()*.34)))
        left_split=ttk.Panedwindow(left,orient='vertical')
        left_split.pack(fill='both',expand=True,padx=(0,12))
        tabs_holder=ttk.Frame(left_split)
        self.console=Console(left_split,self.commands.execute)
        left_split.add(tabs_holder,weight=4)
        left_split.add(self.console,weight=1)
        self.tabs=ttk.Notebook(tabs_holder)
        self.tabs.pack(fill='both',expand=True)
        # Upload shares the tab strip: same top, same height as the TX1… tabs.
        upload_bar=tk.Frame(tabs_holder,bg=BG)
        upload_bar.place(relx=1,x=0,y=0,anchor='ne')
        self.upload_btn=UploadButton(upload_bar,command=self.upload,bg=BG)
        def align_upload(event=None):
            self.update_idletasks()
            try:height=self.tabs.winfo_children()[0].winfo_y()
            except IndexError:return
            if height>8 and height!=self.upload_btn.box[1]:
                font=('Segoe UI',max(9,round(height*.30)),'bold')
                self.upload_btn.font=font
                width=tkfont.Font(font=font).measure(self.upload_btn.text)+2*round(height*.9)
                self.upload_btn.box=(width,height)
                self.upload_btn.configure(width=width,height=height)
        self.tabs.bind('<Map>',align_upload,add='+')
        self.upload_btn.pack(side='right')
        self.upload_hint=tk.Label(upload_bar,text='',bg=BG,fg=MUTED,font=('Microsoft YaHei UI',10,'bold'))
        self.upload_hint.pack(side='right',padx=(0,10))
        upload_bar.lift()
        tx_tab=ScrollPage(self.tabs)
        tx2_tab=ScrollPage(self.tabs)
        rx_tab=ScrollPage(self.tabs)
        cap_tab=ScrollPage(self.tabs)
        training_tab=ScrollPage(self.tabs)
        model_tab=ScrollPage(self.tabs)
        log_tab=ttk.Frame(self.tabs,style='White.TFrame',padding=16)
        self.tabs.add(tx_tab,text='TX1')
        self.tabs.add(tx2_tab,text='TX2')
        self.tabs.add(rx_tab,text='RX1')
        self.tabs.add(cap_tab,text='实采录制')
        self.tabs.add(training_tab,text='训练模式')
        self.tabs.add(model_tab,text='模型测试')
        self.tabs.add(log_tab,text='状态与日志')
        self.cap_tab=cap_tab
        self.training_tab=training_tab
        self.tx_tab,self.tx2_tab,self.rx_tab=tx_tab,tx2_tab,rx_tab
        self._tx_tab(tx_tab.content)
        self._tx2_tab(tx2_tab.content)
        self._rx_tab(rx_tab.content)
        self._capture_tab(cap_tab.content)
        self._training_tab(training_tab.content)
        self.model_tester=ModelTester(self,model_tab.content,BASE)
        self._log_tab(log_tab)
        preview_head=ttk.Frame(right,style='White.TFrame',padding=(15,13))
        preview_head.pack(fill='x')
        ttk.Label(preview_head,text='RX1 同窗观测',style='Title.TLabel').pack(side='left')
        self.monitor_switch=SlideSwitch(preview_head,command=self.toggle_monitor)
        self.monitor_switch.pack(side='left',padx=(14,0))
        self.preview_note=ttk.Label(preview_head,text='未开启接收观测',style='Hint.TLabel')
        self.preview_note.pack(side='right')
        self.plot=AnalysisDashboard(right,emergency=self.all_stop,layout_changed=self.analysis_layout,
                                    filter_panel=self._filter_panel)
        self.plot.pack(fill='both',expand=True,padx=1)
        desc=ttk.Frame(right,style='White.TFrame',padding=(15,12))
        desc.pack(fill='x')
        ttk.Label(desc,text='同窗、独占、弹出共用 IQ。AUTO 仅调显示；同步仅调星座。RX 滤波开启时观测与录制均为滤波后 IQ。',style='Hint.TLabel',wraplength=900,justify='left').pack(anchor='w')
        self.meter_label=ttk.Label(desc,text='0 个完整窗口  ·  0.00 MB',style='White.TLabel')
        self.meter_label.pack(anchor='w',pady=(8,0))
        foot=ttk.Frame(body,padding=(0,12,0,0))
        foot.pack(fill='x')
        self.activity=ttk.Label(foot,text='就绪',style='Muted.TLabel')
        self.activity.pack(side='left',fill='x',expand=True)
        self.all_stop_btn=ttk.Button(foot,text='■ 紧急停止 · TX1 + TX2 + IQ',style='Emergency.TButton',command=self.all_stop)
        self.all_stop_btn.pack(side='right')

    def analysis_layout(self,focused):
        panes,left=self.analysis_panes,self.parameter_pane
        present=str(left) in tuple(map(str,panes.panes()))
        if focused and present:
            self.parameter_sash=panes.sashpos(0)
            panes.forget(left)
        elif not focused and not present:
            panes.insert(0,left,weight=1)
            position=self.parameter_sash
            if position is not None:
                self.after_idle(lambda:panes.sashpos(0,position) if len(panes.panes())>1 else None)

    def _field(self,parent,row,column,label,key,width=16,values=None):
        f=ttk.Frame(parent,style='White.TFrame')
        f.grid(row=row,column=column,sticky='ew',padx=(0,14 if column==0 else 0),pady=(0,10))
        ttk.Label(f,text=label,style='Hint.TLabel',wraplength=230).pack(anchor='w',pady=(0,4))
        if values:
            e=ttk.Combobox(f,textvariable=self.v[key],values=values,state='readonly',width=width)
        else:
            e=ttk.Entry(f,textvariable=self.v[key],width=width)
        e.pack(fill='x')
        self.edit_fields.append(e)
        self.parameter_frames[key]=f
        self.parameter_widgets[key]=e
        return e

    def _tx_tab(self,parent):
        head=ttk.Frame(parent,style='White.TFrame')
        head.pack(fill='x')
        ttk.Label(head,text='发射公共参数',style='Title.TLabel').pack(side='left')
        self.save_profile_btn=ttk.Button(head,text='保存参数',command=self.save_profile)
        self.save_profile_btn.pack(side='right')
        self.load_profile_btn=ttk.Button(head,text='载入参数',command=self.load_profile)
        self.load_profile_btn.pack(side='right',padx=6)
        grid=ttk.Frame(parent,style='White.TFrame')
        grid.pack(fill='x',pady=(12,2))
        grid.columnconfigure((0,1),weight=1)
        self._field(grid,0,0,'TX1 / TX2 共用发射本振 / MHz','center')
        self._field(grid,0,1,'随机种子 / 非零 u32','seed')
        ttk.Separator(parent).pack(fill='x',pady=(0,12))
        title=ttk.Frame(parent,style='White.TFrame')
        title.pack(fill='x')
        ttk.Label(title,text='TX1  调制信号 + 内部噪声',style='Title.TLabel').pack(side='left')
        self.tx1_switch=SlideSwitch(title,command=lambda:self.toggle_tx(1))
        self.tx1_switch.pack(side='right')
        grid=ttk.Frame(parent,style='White.TFrame')
        grid.pack(fill='x',pady=(12,0))
        grid.columnconfigure((0,1),weight=1)
        self._field(grid,0,0,'调制方式','modulation',values=list(UI_MODES))
        self._field(grid,0,1,'基带带宽 / MHz · 0.005～10','bandwidth')
        self._field(grid,1,0,'内部数字 SNR / dB · −10～20','snr')
        self._field(grid,1,1,'TX1 衰减 / dB · 0～89.75','atten1')
        self._field(grid,2,0,'相对共同本振的频偏 / MHz','offset')
        noise_box=ttk.Frame(grid,style='White.TFrame')
        noise_box.grid(row=2,column=1,sticky='ew',pady=(0,10))
        ttk.Label(noise_box,text='TX1 内部 SNR 失真器 · 需固件 ≥ 18',style='Hint.TLabel',wraplength=230).pack(anchor='w',pady=(0,4))
        self.tx1_noise_check=ttk.Checkbutton(noise_box,text='叠加内部噪声（关闭后忽略 SNR）',variable=self.v['tx1_noise'],onvalue='1',offvalue='0')
        self.tx1_noise_check.pack(anchor='w')
        self.special_grid=ttk.Frame(parent,style='White.TFrame')
        self.special_grid.pack(fill='x')
        self.special_grid.columnconfigure((0,1),weight=1)
        self.special_frames={}
        for index,(key,(label,variable,values)) in enumerate(SPECIAL_FIELDS.items()):
            self._field(self.special_grid,index//2,index%2,label,variable,values=values)
            self.special_frames[key]=self.parameter_frames[key]
        self.am_depth_entry=self.parameter_widgets['am_depth']
        self.modulation_hint=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480,justify='left')
        self.modulation_hint.pack(anchor='w',pady=(3,9))
        self.plan_label=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480,justify='left')
        self.plan_label.pack(anchor='w',pady=(0,9))
        actions=ttk.Frame(parent,style='White.TFrame')
        actions.pack(fill='x',pady=(4,0))
        self.readback_btn=ttk.Button(actions,text='填入板上参数',command=self.readback)
        self.readback_btn.pack(side='right')
        self.tx_capability=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480,justify='left')
        self.tx_capability.pack(anchor='w',pady=(12,0))
        ttk.Label(parent,text='修改后点参数页右上角 upload 生效，以板端读回为准。upload 保留 TX 开关；故障恢复关闭两路。\nSNR 为 TX1 内部数字 SNR，不是 RX1 实测值。',style='Hint.TLabel',wraplength=480).pack(anchor='w',pady=(9,0))

    def _tx2_tab(self,parent):
        title=ttk.Frame(parent,style='White.TFrame');title.pack(fill='x')
        ttk.Label(title,text='TX2  带限高斯噪声',style='Title.TLabel').pack(side='left')
        self.tx2_switch=SlideSwitch(title,command=lambda:self.toggle_tx(2));self.tx2_switch.pack(side='right')
        grid=ttk.Frame(parent,style='White.TFrame');grid.pack(fill='x',pady=(18,0))
        grid.columnconfigure((0,1),weight=1)
        # Same variable: AD9361 has one shared TX synthesizer.
        self.tx2_lo_entry=self._field(grid,0,0,'TX1 / TX2 共用发射本振 / MHz','center')
        self._field(grid,0,1,'TX2 衰减 / dB · 步进 0.25','atten2')
        self._field(grid,1,0,'有噪声频段起点 / MHz · 相对 LO','noise_low')
        self._field(grid,1,1,'有噪声频段终点 / MHz · 相对 LO','noise_high')
        self.tx2_plan=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480)
        self.tx2_plan.pack(anchor='w',pady=10)
        ttk.Label(parent,text='TX2 独立开关与衰减；频段表示有噪声的范围。\nTX1 / TX2 共用发射本振，修改本振会同时影响两路。\n修改后点参数页右上角 upload 生效；编辑框不会自动改变板端。',style='Hint.TLabel',wraplength=480).pack(anchor='w',pady=12)

    def _rx_tab(self,parent):
        title=ttk.Frame(parent,style='White.TFrame');title.pack(fill='x')
        ttk.Label(title,text='RX1  独立接收配置',style='Title.TLabel').pack(side='left')
        self.rx_monitor_switch=SlideSwitch(title,command=self.toggle_monitor)
        self.rx_monitor_switch.pack(side='right')
        self.rx_follow_check=ttk.Checkbutton(parent,text='接收中心跟随发射本振',variable=self.v['rx_follow'],onvalue='1',offvalue='0')
        self.rx_follow_check.pack(anchor='w',pady=(14,8))
        grid=ttk.Frame(parent,style='White.TFrame');grid.pack(fill='x')
        grid.columnconfigure((0,1),weight=1)
        self.rx_center_entry=self._field(grid,0,0,'接收中心频率 / MHz · 300～6000','rx_center')
        self._field(grid,0,1,'RX 模拟带宽 / MHz','rx_bandwidth',values=['0.2','0.5','1','2','5','10','15','20'])
        self._field(grid,1,0,'接收增益模式','rx_gain_mode',values=['手动增益','慢速 AGC','快速 AGC'])
        self.rx_gain_entry=self._field(grid,1,1,'手动增益 / dB','rx_gain')
        self.rx_gain_frame=self.rx_gain_entry.master
        self.rx_rate_entry=self._field(grid,2,0,'观测 / 普通录制 IQ 输出采样率','rate',values=['1 MSPS · FIR 抽取','25 MSPS · 原始采样'])
        self.rx_plan_label=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480,justify='left')
        self.rx_plan_label.pack(anchor='w',pady=10)
        ttk.Label(parent,text='修改后点参数页右上角 upload 生效；观测中 upload 会按新参数重启观测。',style='Hint.TLabel',wraplength=480).pack(anchor='w',pady=5)
        self.rx_recover_btn=ttk.Button(parent,text='清理 RX 故障',command=lambda:self.send('stop_remote'))
        self.rx_recover_btn.pack(anchor='w',pady=5)
        self.rx_actual_label=ttk.Label(parent,text='板端实际 RX：尚未读回',style='White.TLabel',wraplength=480,justify='left')
        self.rx_actual_label.pack(anchor='w',pady=(12,8))
        ttk.Label(parent,text='仅在网口 RX 协议握手成功后开放编辑、观测和录制。RX 使用与悟净相同的 RFCT v1；TX 配置只走 UART。\nPC 调试时替代悟净，不能同时争用接收控制；检测到已有采集时不会自动 STOP 抢占。\nRX 本振独立；带宽按校准档位选择，可切换手动增益或 AGC。\n观测不写盘；录制停止后按原意愿恢复观测。断开网口清除分析数据，UART 发射连接保持。',style='Hint.TLabel',wraplength=480,justify='left').pack(anchor='w',pady=8)

    def _capture_tab(self,parent):
        ttk.Label(parent,text='RX1 原始 IQ 录制',style='Title.TLabel').pack(anchor='w')
        ttk.Label(parent,text='板端 RF_READY 后可开始；使用 RX1 页的接收配置。\n只切换本 PC 的观测会话，不抢占悟净接收；TX 开关保持。',style='Hint.TLabel',wraplength=480).pack(anchor='w',pady=(8,16))
        self.capture_fields=[]
        def entry(label,key):
            ttk.Label(parent,text=label,style='Hint.TLabel').pack(anchor='w',pady=(7,4))
            e=ttk.Entry(parent,textvariable=self.v[key])
            e.pack(fill='x')
            self.capture_fields.append(e)
            return e
        directory_row=ttk.Frame(parent,style='White.TFrame')
        ttk.Label(parent,text='保存目录',style='Hint.TLabel').pack(anchor='w',pady=(0,4))
        directory_row.pack(fill='x')
        e=ttk.Entry(directory_row,textvariable=self.v['directory'])
        e.pack(side='left',fill='x',expand=True)
        self.capture_fields.append(e)
        self.browse_btn=ttk.Button(directory_row,text='浏览',command=self.browse)
        self.browse_btn.pack(side='right',padx=(8,0))
        entry('文件名 / 自动生成 .iq + .index.bin + .json','filename')
        row=ttk.Frame(parent,style='White.TFrame')
        row.pack(fill='x',pady=12)
        row.columnconfigure((0,1),weight=1)
        original=self.edit_fields
        self.edit_fields=self.capture_fields
        self._field(row,0,0,'输出采样率','rate',values=['1 MSPS · FIR 抽取','25 MSPS · 原始采样'])
        self._field(row,0,1,'录制时长 / 秒 · 可提前停止','seconds')
        self.edit_fields=original
        self.estimate=ttk.Label(parent,text='',style='Hint.TLabel')
        self.estimate.pack(anchor='w',pady=(0,14))
        actions=ttk.Frame(parent,style='White.TFrame')
        actions.pack(fill='x')
        self.record_switch=SlideSwitch(actions,command=lambda:self.toggle_capture('normal'))
        self.record_switch.pack(side='left')
        self.open_btn=ttk.Button(actions,text='打开目录',command=self.open_directory)
        self.open_btn.pack(side='right')
        self.progress=ttk.Progressbar(parent,maximum=100)
        self.progress.pack(fill='x',pady=(20,8))
        self.capture_summary=ttk.Label(parent,text='等待开始',style='White.TLabel',wraplength=480,justify='left')
        self.capture_summary.pack(anchor='w')
        ttk.Separator(parent).pack(fill='x',pady=18)
        text=('保存格式\n'
              '• .iq：小端 int16，交织 I/Q，保留 ADC 原始幅值。\n'
              '• .index.bin：完整 1024 点窗索引，保留样本缺口。\n'
              '• .json：参数、TX 状态、CRC/丢窗统计和停止结果。\n\n'
              '仅保存校验通过的完整窗口，不补零伪造缺失数据。\n'
              '25 MSPS 的 IQ 约 100 MB/s，需千兆网卡和足够快的磁盘。\n'
              '离线演示文件以 DEMO_ 开头，不可作为实采训练数据。')
        ttk.Label(parent,text=text,style='Hint.TLabel',wraplength=480,justify='left').pack(anchor='w')

    def open_training_mode(self):
        self.tabs.select(self.training_tab)

    def _training_tab(self,parent):
        ttk.Label(parent,text='训练数据采集',style='Title.TLabel').pack(anchor='w')
        ttk.Label(parent,text='先在“发射配置”应用参数并开启 TX1，再开始采集。\n'
                  '启动、录制、停止收尾期间锁定参数与 TX 开关；可随时停止或紧急停止。',
                  style='Hint.TLabel',wraplength=480,justify='left').pack(anchor='w',pady=(8,12))
        self.training_config_label=ttk.Label(parent,text='尚未连接',style='White.TLabel',wraplength=480,justify='left')
        self.training_config_label.pack(anchor='w',pady=(0,12))
        self.training_fields=[]
        ttk.Label(parent,text='训练数据保存目录',style='Hint.TLabel').pack(anchor='w',pady=(4,4))
        row=ttk.Frame(parent,style='White.TFrame')
        row.pack(fill='x')
        e=ttk.Entry(row,textvariable=self.v['train_directory'])
        e.pack(side='left',fill='x',expand=True)
        self.training_fields.append(e)
        self.train_browse_btn=ttk.Button(row,text='浏览',command=self.browse_training)
        self.train_browse_btn.pack(side='right',padx=(8,0))
        grid=ttk.Frame(parent,style='White.TFrame')
        grid.pack(fill='x',pady=(12,0))
        grid.columnconfigure((0,1),weight=1)
        original=self.edit_fields
        self.edit_fields=self.training_fields
        self._field(grid,0,0,'输出采样率','train_rate',values=['1 MSPS · FIR 抽取','25 MSPS · 原始采样'])
        self._field(grid,0,1,'本次录制时长 / 秒','train_seconds')
        self._field(grid,1,0,'实验备注 / 可选，最多 24 字','train_tag')
        self.edit_fields=original
        self.train_estimate=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480)
        self.train_estimate.pack(anchor='w',pady=(0,8))
        ttk.Label(parent,text='预计文件名 / 开始时以板端最新读回重新生成',style='Hint.TLabel').pack(anchor='w')
        self.train_filename_label=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480,justify='left')
        self.train_filename_label.pack(anchor='w',pady=(4,12))
        actions=ttk.Frame(parent,style='White.TFrame')
        actions.pack(fill='x')
        self.training_switch=SlideSwitch(actions,command=lambda:self.toggle_capture('training'))
        self.training_switch.pack(side='left')
        self.train_open_btn=ttk.Button(actions,text='打开目录',command=self.open_training_directory)
        self.train_open_btn.pack(side='right')
        self.training_progress=ttk.Progressbar(parent,maximum=100)
        self.training_progress.pack(fill='x',pady=(16,8))
        self.training_summary=ttk.Label(parent,text='等待开始训练采集',style='White.TLabel',wraplength=480,justify='left')
        self.training_summary.pack(anchor='w')
        self.campaign=CampaignPanel(self,parent)
        ttk.Separator(parent).pack(fill='x',pady=14)
        ttk.Label(parent,text='每次保存 .iq + .index.bin + .json，IQ 格式与普通录制相同。\n'
                  '文件名含调制、LO、带宽、采样率、内部 SNR、TX 状态/衰减、噪声频段、频偏、种子、配置摘要与时间。\n'
                  '完整配置和标签在 JSON；标签表示 TX1 配置，接收质量与实测 SNR 仍需检查。\n'
                  '紧急停止、配置变化或录制异常会标记为禁止自动贴标签；离线演示始终排除。',
                  style='Hint.TLabel',wraplength=480,justify='left').pack(anchor='w')

    def _log_tab(self,parent):
        top=ttk.Frame(parent,style='White.TFrame')
        top.pack(fill='x',pady=(0,8))
        ttk.Label(top,text='板端状态与操作日志',style='Title.TLabel').pack(side='left')
        ttk.Button(top,text='导出状态',command=self.export_status).pack(side='right')
        self.status_text=tk.Text(parent,height=13,bg=FIELD,fg=TEXT,insertbackground=TEXT,relief='flat',font=('Consolas',9),wrap='none',padx=10,pady=10)
        self.status_text.pack(fill='both',expand=True,pady=(0,12))
        self.status_text.insert('1.0','连接后显示 RFCT 状态字段。')
        self.status_text.configure(state='disabled')
        self.log_text=tk.Text(parent,height=12,bg=FIELD,fg=TEXT,insertbackground=TEXT,relief='flat',font=('Microsoft YaHei UI',9),wrap='word',padx=10,pady=10)
        self.log_text.pack(fill='both',expand=True)
        self.log_text.configure(state='disabled')

    def log(self,text,level='info'):
        line=self.console.write(level,text) if hasattr(self,'console') else datetime.now().strftime('%H:%M:%S')+f' [{level}] '+text
        self.log_text.configure(state='normal')
        self.log_text.insert('end',line+'\n')
        if int(self.log_text.index('end-1c').split('.')[0])>500:
            self.log_text.delete('1.0','50.0')
        self.log_text.see('end')
        self.log_text.configure(state='disabled')
        self.activity.configure(text=text[:85],foreground={'warning':WARN,'critical':CRITICAL,'error':ERROR}.get(level,MUTED))
        try:
            folder=BASE/'logs'
            folder.mkdir(exist_ok=True)
            with (folder/datetime.now().strftime('%Y%m%d.log')).open('a',encoding='utf-8') as f:
                f.write(('\n' if getattr(self.console,'gap',False) else '')+line+'\n')
        except OSError:
            pass

    def connect(self):
        self.send('connect',port=self.v['serial_port'].get().strip(),baud=self.v['baud'].get(),demo=self.demo_choice.get())

    def connect_rx(self):
        self.send('connect_rx',bind=self.v['bind'].get().strip(),peer=self.v['peer'].get().strip(),demo=self.demo_choice.get())

    def send(self,action,**data):
        if self.closing:
            return False
        if self.emergency_waiting and action not in ('status','all_stop'):
            self.log('正在紧急停止，请等待板端确认。')
            return False
        if self._training_active() and action not in ('status','all_stop','capture') and not (
                action in ('configure','monitor','enable') and self.campaign.running() and not self.recording and not self.capture_pending):
            self.log('训练采集已锁定参数，请先停止采集。')
            return False
        if action in ('configure','enable','disconnect') and not self.tx_connected:
            self.log('UART 未握手成功，无法操作 TX。');return False
        if action in ('monitor','capture','stop_remote') and not self.rx_connected:
            self.log('网口 RX 未握手成功，无法采集或分析。');return False
        if action in ('capture','disconnect_rx') and (self.monitoring or self.monitor_pending):
            if self.after_monitor_action is not None:
                self.log('正在切换接收会话，请等待完成。')
                return False
            if action=='disconnect_rx':self.monitor_requested=False
            self.after_monitor_action=(action,data)
            self.monitor_stopping=True
            self.worker.stop_monitor.set()
            self.activity.configure(text='正在停止只观测会话，随后执行'+{'capture':'录制','configure':'参数配置','disconnect_rx':'断开网口'}[action]+'…')
            self._refresh_controls()
            return True
        try:
            self.worker.submit(action,**data)
        except RuntimeError as exc:
            self.log(str(exc))
            return False
        self.pending.add(action)
        self.activity.configure(text={'connect':'正在连接并读取状态…','configure':'正在配置、初始化和校准，请稍候…',
                                     'capture':'正在建立采集会话…','enable':'正在设置 TX 并等待硬件读回…',
                                     'all_stop':'正在关闭 TX 并停止 IQ…'}.get(action,'正在执行…'))
        self._refresh_controls()
        return True

    def _training_active(self):
        return (((self.recording or self.capture_pending) and self.capture_mode=='training') or self.worker.training_lock.is_set()
                or (hasattr(self,'campaign') and self.campaign.running()))

    def toggle_monitor(self):
        if str(self.monitor_switch.cget('state'))=='disabled':return
        if self.monitoring or self.monitor_pending:
            self.monitor_requested=False
            self.monitor_stopping=True
            self.worker.stop_monitor.set()
            self.activity.configure(text='正在停止接收观测，TX 开关保持不变…')
            self._refresh_controls()
        else:
            self.emergency_failed=False
            self.monitor_requested=True
            self.start_monitor()

    def start_monitor(self):
        if (not self.rx_connected or self.closing or self.monitoring or self.monitor_pending or
            self.recording or self.capture_pending or self.pending or self.emergency_waiting or self.emergency_failed):return
        try:self.require_rx_supported()
        except (ValueError,OverflowError) as exc:
            self.monitor_requested=False
            messagebox.showerror('无法开启接收观测',str(exc),parent=self)
            self._refresh_controls()
            return
        fs=25_000_000 if self.v['rate'].get().startswith('25') else 1_000_000
        try:spec=self.current_filter(fs)
        except rx_filter.FilterError as exc:
            self.monitor_requested=False
            self.log('无法开启接收观测：RX 滤波器参数无效：'+str(exc),'error')
            self._refresh_controls()
            return
        self.applied_filter=spec
        self.monitor_pending=True;self.monitor_stopping=False
        self.plot.clear()
        if not self.send('monitor',fs=fs,rf=self.rx_config(),filter=spec):
            self.monitor_pending=False;self.monitor_requested=False
            self._refresh_controls()

    def toggle_tx(self,channel):
        widget=self.tx1_switch if channel==1 else self.tx2_switch
        if str(widget.cget('state'))=='disabled' or self.last_tx is None:
            return
        bit=1 if channel==1 else 2
        return self.send('enable',**{f'tx{channel}':not bool(self.last_tx['applied_mask']&bit)})

    def toggle_capture(self,mode):
        widget=self.record_switch if mode=='normal' else self.training_switch
        if str(widget.cget('state'))=='disabled':
            return
        if (self.recording or self.capture_pending) and self.capture_mode==mode:
            self.stop_recording()
        elif mode=='training':
            self.start_training_capture()
        else:
            self.start_capture()

    def configure_radio(self):
        """Compatibility entry for scripted callers: same path as the upload button."""
        self.upload()

    def values(self):
        return {k:v.get() for k,v in self.v.items()}

    def update_plan(self):
        if getattr(self,'loading_profile',False):return
        mode=display_mode(self.v['modulation'].get())
        if mode!=self.v['modulation'].get():
            self.v['modulation'].set(mode)
            return
        if mode.endswith(('ASK','PSK')) and self.v['rolloff'].get()!='0.35':
            self.v['rolloff'].set('0.35')
        if mode=='FM' and self.v['fm_index'].get()!='4':
            self.v['fm_index'].set('4')
        try:
            # Re-grid only when the mode's field set changes; hiding and re-showing
            # the same frames on every parameter write made the panel jump.
            fields=mode_fields(mode)
            if fields!=getattr(self,'special_layout',None):
                for frame in self.special_frames.values():frame.grid_remove()
                for index,key in enumerate(fields):
                    self.special_frames[key].grid(row=index//2,column=index%2,sticky='ew',padx=(0,14 if index%2==0 else 0),pady=(0,10))
                self.special_layout=fields
            values=self.values()
            validate_tx(values)
            lo=float(values['center']);off=float(values['offset'])
            low,high=(lo+x/1e6 for x in tx1_band(values))
            band=f"TX1 载波：{lo+off:g} MHz · 占用 {low:g}～{high:g} MHz（射频 {rf_occupancy(values):g} MHz）"
            text=band+f"\nTX2 噪声频段：{lo+float(values['noise_low']):g}～{lo+float(values['noise_high']):g} MHz"
            self.plan_label.configure(text=text,foreground=MUTED)
            self.tx2_plan.configure(text=text.split('\n')[-1],foreground=MUTED)
            reason=tx_firmware_reason(values)
            critical='' if self.demo else baseband_firmware_warning(values,self.firmware_number())
            self.tx_capability.configure(text=reason or critical or 'TX 参数检查通过；UART 握手后可应用，以板端读回为准。',
                                         foreground=WARN if reason else CRITICAL if critical else OK)
        except (ValueError,OverflowError) as exc:
            # An invalid mode keeps the last special-field layout; mode_fields failed.
            self.plan_label.configure(text='待修正：'+str(exc),foreground=ERROR)
            self.tx_capability.configure(text='请先修正参数；未向板端发送。',foreground=ERROR)
        hints={'AM-SSB-WC':'单边带带载波：选择 USB / LSB，并设置载波相对所选边带的功率比。频偏与其他调制相同，指边带中心；载波在中心下方（USB）或上方（LSB）带宽/2 处。内部噪声覆盖所选边带（固件 ≥ 18）。',
               'AM-SSB-SC':'单边带抑制载波：选择 USB / LSB。频偏与其他调制相同，指边带中心（单音所在位置）；被抑制的载波在中心下方（USB）或上方（LSB）带宽/2 处。内部噪声覆盖所选边带（固件 ≥ 18）。',
               'AM-DSB-WC':'双边带带载波：调制度只在此模式显示。使用内部单音消息源。',
               'AM-DSB-SC':'双边带抑制载波：输出为抑制载波的双边带信号。',
               'FM':'普通模拟调频；当前固件的调频指数固定为 4。'}
        self.modulation_hint.configure(text=hints.get(mode,'方形 QAM，按平均符号功率归一化；使用 RRC 成形。' if mode.endswith('QAM') else
            'ASK / PSK 使用 RRC 成形，符号率由带宽和滚降系数确定。' if mode.endswith(('ASK','PSK')) else '多进制 FSK；符号率与频率间隔由带宽和阶数确定。'))
        self.update_rx_plan()
        self._refresh_controls()
        self.hold_height(self.modulation_hint,self.plan_label,self.tx2_plan,self.tx_capability)

    def hold_height(self,*labels):
        """Grow-only label height: text that alternates between line counts (batch
        points, typing) must not move the widgets below it up and down."""
        for label in labels:
            label.configure(padding=0)
            natural=label.winfo_reqheight()
            wrap=str(label.cget('wraplength'))
            # A new wrap width (window resize, ScrollPage.reflow) re-measures from scratch.
            tallest=natural if getattr(label,'tallest_wrap',None)!=wrap else max(label.tallest,natural)
            label.tallest,label.tallest_wrap=tallest,wrap
            if tallest>natural:label.configure(padding=(0,0,0,tallest-natural))

    def check_band(self,force=False,annotate=False):
        """Warn when the TX1 band would be cut by the RX path.

        Logged when the kind of problem changes (not on every keystroke), and
        always at upload (force) so the console shows the values being sent.
        """
        findings=tuple(band_check(self.values()))
        codes=tuple((f.level,f.code) for f in findings)
        previous=tuple((f.level,f.code) for f in self.band_findings)
        if force or codes!=previous:
            for f in findings:self.log(f.text,f.level)
            if previous and not findings and not force:self.log('TX1 频带已完整落在 RX 可用带宽内。','ok')
        self.band_findings=findings
        worst='error' if any(f.level=='error' for f in findings) else 'warning' if findings else None
        self.console.set_badge({'error':'● 频带缺失','warning':'● 频带受损'}.get(worst,''),worst or 'info')
        if annotate and findings:
            self.rx_plan_label.configure(text=self.rx_plan_label.cget('text')+'\n⚠ '+findings[0].text,
                                         foreground=ERROR if worst=='error' else WARN)

    def update_rx_plan(self):
        if getattr(self,'loading_profile',False):return
        if not hasattr(self,'rx_plan_label'):return
        follow=self.v['rx_follow'].get()=='1'
        if follow and self.rx_connected and self.v['rx_center'].get()!=self.v['center'].get():
            self.v['rx_center'].set(self.v['center'].get())
        self.rx_gain_frame.grid() if self.v['rx_gain_mode'].get()=='手动增益' else self.rx_gain_frame.grid_remove()
        try:
            values=self.values()
            center=float(values['rx_center']);bw=float(values['rx_bandwidth'])
            if not math.isfinite(center+bw) or not 300<=center<=6000 or not .2<=bw<=20:
                raise ValueError('接收中心需 300～6000 MHz；模拟带宽需 0.2～20 MHz。')
            span=min(bw,.8 if values['rate'].startswith('1 ') else 20)
            reason=rx_firmware_reason(values)
            self.rx_plan_label.configure(text=f'待提交接收范围：{center-span/2:g}～{center+span/2:g} MHz\n'+
                (reason or 'RX 参数符合当前固件；采样率在开启观测或普通录制时应用。'),foreground=WARN if reason else MUTED)
        except (ValueError,OverflowError) as exc:
            self.rx_plan_label.configure(text='待修正：'+str(exc),foreground=ERROR)
        if hasattr(self,'console'):self.check_band(annotate=True)
        if hasattr(self,'record_switch'):self._refresh_controls()
        self.hold_height(self.rx_plan_label)

    def check_rx_configuration(self):
        try:
            reason=rx_firmware_reason(self.values())
            if reason:raise ValueError(reason)
            self.log('RX 参数检查通过；启动采集时应用，板端尚未改变。')
        except (ValueError,OverflowError) as exc:
            messagebox.showinfo('RX 参数尚未应用',str(exc),parent=self)

    def _filter_panel(self,box):
        """RX filter controls (in the analysis option strip, right of the waterfall scale)."""
        head=ttk.Frame(box,style='White.TFrame');head.grid(row=0,column=0,columnspan=4,sticky='w')
        self.filter_check=ttk.Checkbutton(head,text='RX 滤波器',variable=self.v['rx_filter'],onvalue='1',offvalue='0',
                                          command=self.filter_edited)
        self.filter_check.pack(side='left')
        self.filter_type_box=ttk.Combobox(head,textvariable=self.v['filter_type'],values=FILTER_TYPES,width=9,state='readonly')
        self.filter_type_box.pack(side='left',padx=(6,0))
        self.filter_type_box.bind('<<ComboboxSelected>>',lambda e:self.filter_edited())
        self.filter_fields={}
        specs=(('filter_f1','f1 / kHz'),('filter_f2','f2 / kHz'),('filter_ripple','Ap / dB'),
               ('filter_stop','As / dB'),('filter_transition','Δf / kHz'))
        for i,(key,label) in enumerate(specs):
            f=ttk.Frame(box,style='White.TFrame');f.grid(row=1,column=i,padx=(0,6),pady=(2,0),sticky='w')
            self.filter_fields[key]=(ttk.Label(f,text=label,style='Hint.TLabel'),)
            self.filter_fields[key][0].pack(anchor='w')
            e=ttk.Entry(f,textvariable=self.v[key],width=7);e.pack()
            e.bind('<Return>',lambda ev:self.filter_edited());e.bind('<FocusOut>',lambda ev:self.filter_edited())
            self.filter_fields[key]+=(e,)
        self.filter_note=ttk.Label(box,text='',style='Hint.TLabel',wraplength=560,justify='left')
        self.filter_note.grid(row=2,column=0,columnspan=5,sticky='w',pady=(3,0))
        self.applied_filter=None
        self.after_idle(self.update_filter_note)

    def filter_fs(self,training=False):
        key='train_rate' if training else 'rate'
        return 25_000_000 if self.v[key].get().startswith('25') else 1_000_000

    def current_filter(self,fs=None,training=False):
        """FilterSpec for the given output rate, or None when off. Raises FilterError."""
        return filter_spec(self.values(),fs or self.filter_fs(training))

    def update_filter_note(self):
        if not hasattr(self,'filter_note'):return
        kind=self.v['filter_type'].get()[:3]
        lowpass=kind in ('LPF','HPF')
        self.filter_fields['filter_f1'][0].configure(text='fc / kHz' if lowpass else 'f1 / kHz')
        self.filter_fields['filter_f2'][0].configure(text='—' if lowpass else 'f2 / kHz')
        if self.filter_fs()>rx_filter.MAX_FS:
            # 25 MSPS: filtering is unavailable; switch it off (the trace re-enters once).
            if self.v['rx_filter'].get()=='1':self.v['rx_filter'].set('0');return
            self.filter_note.configure(text='关闭：'+rx_filter.RATE_LIMIT_TEXT,foreground=MUTED)
            self.hold_height(self.filter_note)
            return
        on=self.v['rx_filter'].get()=='1'
        try:
            spec=self.current_filter()
            if spec is None:
                text,color='关闭：观测、录制和训练使用原始 IQ。',MUTED
            else:
                info=rx_filter.plan(spec,self.filter_fs())
                text=spec.label()+'\n'+rx_filter.describe(info,self.filter_fs())
                color=ERROR if info['load']>=1 else WARN if info['load']>=.7 or not info['meets'] else OK
        except rx_filter.FilterError as exc:
            text,color=('待修正：' if on else '关闭 · 参数待修正：')+str(exc),ERROR if on else MUTED
        self.filter_note.configure(text=text,foreground=color)
        self.hold_height(self.filter_note)

    def filter_edited(self):
        """Validate; a changed filter restarts the live observation so it takes effect."""
        self.update_filter_note();self._refresh_controls()
        try:spec=self.current_filter()
        except rx_filter.FilterError:return
        if spec==self.applied_filter or not (self.monitoring or self.monitor_pending):return
        # Only restart a session that is fully up: a STOP raced with a queued START
        # would be cleared by the worker and leave the old filter running.
        if (self.monitor_pending or self.monitor_stopping or not self.worker.monitoring or self.pending-{'monitor'} or self.after_monitor_action
                or self.recording or self.capture_pending or self.upload_job):
            self.filter_restart_pending=True;self.after(200,self.filter_edited);return
        self.filter_restart_pending=False
        self.log('RX 滤波器已更改，重启接收观测以生效。')
        self.monitor_requested=True;self.monitor_stopping=True;self.worker.stop_monitor.set()
        self._refresh_controls()

    def require_rx_supported(self):
        if not self.rx_connected:raise ValueError('请先完成网口 RX 协议握手。')
        validate_rx(self.values())
        if self.last_rx and self.last_rx.get('state') not in (0,4) and not (self.monitoring or self.recording):
            raise ValueError('RX 已被悟净或其他会话占用，PC 不会抢占。')
        reason=rx_firmware_reason(self.values())
        if reason:raise ValueError(reason+' 请恢复当前固件支持的 RX 参数后再采集。')

    def rx_config(self):
        values=self.values()
        center=values['center'] if values['rx_follow']=='1' else values['rx_center']
        return RFConfig(round(float(center)*1e6),25_000_000,
                        round(float(values['rx_bandwidth'])*1e6),round(float(values['rx_gain'])*1000) if values['rx_gain_mode']=='手动增益' else 0,
                        {'手动增益':0,'慢速 AGC':1,'快速 AGC':2}[values['rx_gain_mode']],0)

    def upload_snapshot(self):
        try:return tuple(sorted(active_parameters(self.values()).items()))
        except (ValueError,OverflowError,KeyError):return None

    def upload_dirty(self):
        links={'tx'} if self.tx_connected else set()
        if self.rx_connected:links.add('rx')
        current=self.upload_snapshot()
        return current is None or current!=self.uploaded_snapshot or not links<=self.uploaded_links

    def upload(self):
        """Send every edited parameter: TX over UART (0x100), then RX if observing."""
        if self.upload_job or self.recording or self.capture_pending:return
        if self._training_active() and not self.campaign.running():return
        self.check_band(force=True)
        if any(f.level=='error' for f in self.band_findings) and not messagebox.askokcancel(
                '频带缺失',"\n\n".join(f.text for f in self.band_findings)+'\n\n仍要上传吗？',icon='warning',parent=self):
            self.log('upload 已取消：TX1 频带不在 RX 可用带宽内。','warning');return
        if not (self.tx_connected or self.rx_connected):return
        values=self.values()
        config=None
        try:
            if self.tx_connected:
                validate_tx(values)
                reason=tx_firmware_reason(values)
                if reason:raise ValueError(reason)
                config=waveform({k:v.get() for k,v in self.v.items()})
                # Old firmware places SSB by its carrier: proceed, but say the band is off by BW/2.
                warning=baseband_firmware_warning(values,None if self.demo else self.firmware_number())
                if warning:self.log('critical warning：'+warning,'critical')
            if self.rx_connected:
                validate_rx(values)
                reason=rx_firmware_reason(values)
                if reason:raise ValueError(reason)
        except (ValueError,OverflowError) as exc:
            self.log('参数错误，未上传：'+str(exc),'error')
            messagebox.showerror('参数错误 · 未上传',str(exc),parent=self)
            return
        links=frozenset(k for k,on in (('tx',self.tx_connected),('rx',self.rx_connected)) if on)
        self.upload_failed=False
        self.upload_job=dict(snapshot=self.upload_snapshot(),links=links,stage='tx',
                             restart_rx=self.rx_connected and (self.monitoring or self.monitor_pending))
        if not self.tx_connected:self.log('upload：UART 未连接，跳过 TX。')
        if not self.rx_connected:self.log('upload：网口未连接，跳过 RX。')
        if self.tx_connected:
            if not self.send('configure',config=config):self._upload_finished('TX 未能提交')
        else:self._upload_rx()
        self._refresh_controls()

    def _upload_rx(self):
        job=self.upload_job
        if job is None:return
        if not (job['restart_rx'] and self.rx_connected):
            if self.rx_connected:self.log('upload：RX 参数已更新，开启观测时使用。')
            self._upload_finished(None);return
        # Same order as a manual restart: STOP, SET_RF, SET_STREAM, START. A fault
        # recovery inside 0x100 resets RX to firmware defaults, so always restart.
        self.monitor_requested=True
        if self.monitoring or self.monitor_pending:
            job['stage']='rx_stop'
            self.monitor_stopping=True;self.worker.stop_monitor.set()
        else:
            job['stage']='rx_start';self.start_monitor()
            if not self.monitor_pending:self._upload_finished('RX 观测未能重新开启')

    def _upload_finished(self,error):
        job,self.upload_job=self.upload_job,None
        if job is None:return
        if error:
            self.upload_failed=True
            self.log('upload 失败：'+error+'。','error')
            return
        self.upload_failed=False
        self.uploaded_snapshot=job['snapshot'];self.uploaded_links=job['links']
        parts=[]
        if 'tx' in job['links']:parts.append('TX 已上传')
        if 'rx' in job['links']:parts.append('RX 已重新下发' if job['restart_rx'] else 'RX 参数待开启观测时使用')
        self.log('upload 完成：'+'，'.join(parts)+'。')

    def update_estimate(self):
        try:
            fs=25_000_000 if self.v['rate'].get().startswith('25') else 1_000_000
            seconds=float(self.v['seconds'].get())
            if not math.isfinite(seconds) or seconds<=0:
                raise ValueError
            self.estimate.configure(text=f'IQ 数据约 {fs*4*seconds/1e9:.3f} GB  ·  写入 {fs*4/1e6:g} MB/s（另加索引）')
        except (ValueError,OverflowError):
            self.estimate.configure(text='请输入有效录制时长。')
        self.update_rx_plan()

    def start_capture(self):
        if self.recording or self.capture_pending or 'capture' in self.pending or (self.monitor_pending and not self.monitoring) or self.monitor_stopping:
            return
        try:
            self.require_rx_supported()
            fs=25_000_000 if self.v['rate'].get().startswith('25') else 1_000_000
            opts=recording_options(self.v['directory'].get(),self.v['filename'].get().strip(),self.v['seconds'].get(),fs)
            opts['rf']=self.rx_config()
            opts['filter']=self.current_filter(fs)
            directory=opts['path'].parent
            ancestor=directory
            while not ancestor.exists():
                ancestor=ancestor.parent
            required=fs*4*opts['seconds']*1.02
            if not self.demo and shutil.disk_usage(ancestor).free<required:
                raise ValueError(f'磁盘剩余空间不足，预计需要约 {required/1e9:.2f} GB。')
        except (ValueError,OSError,OverflowError) as exc:
            messagebox.showerror('无法开始录制',str(exc),parent=self)
            return
        self.capture_mode='normal'
        self.capture_pending=True
        self.capture_stopping=False
        self.plot.clear()
        self.progress['value']=0
        if not self.send('capture',**opts):
            self.capture_pending=False
            self.capture_mode=None
            self._refresh_controls()

    def update_training_preview(self):
        try:self._update_training_preview()
        finally:self.hold_height(self.training_config_label,self.train_filename_label)

    def _update_training_preview(self):
        try:
            fs=25_000_000 if self.v['train_rate'].get().startswith('25') else 1_000_000
            seconds=float(self.v['train_seconds'].get())
            if not math.isfinite(seconds) or not 0<seconds<=86400:
                raise ValueError('请输入有效时长，最大 86400 秒。')
            self.train_estimate.configure(text=f'预计 IQ {fs*4*seconds/1e6:.1f} MB · {fs*4/1e6:g} MB/s（另加索引）')
            tx=self.last_tx
            if not tx or not tx.get('seed'):
                self.training_config_label.configure(text='连接后显示板端已应用的配置；编辑框中的待提交值不会作为标签。')
                self.train_filename_label.configure(text='应用波形配置后显示。')
                return
            try:spec=self.current_filter(fs)
            except rx_filter.FilterError as exc:raise ValueError('RX 滤波器：'+str(exc)) from None
            snapshot=configuration_snapshot(tx,fs,self.demo,self.rx_config(),spec)
            mask=tx['applied_mask']
            self.training_config_label.configure(text=f"板端已应用：{display_mode(tx['modulation'])} · LO {tx['center_hz']/1e6:g} MHz · 基带带宽 {tx['bandwidth_hz']/1e6:g} MHz\n"
                f"内部 SNR {(format(tx['snr_db'],'g')+' dB') if tx['registers'][11] else '关闭'} · TX1 {'开' if mask&1 else '关'} / {tx['attenuation1_db']:g} dB 衰减 · "
                f"TX2 {'开' if mask&2 else '关'} / {tx['attenuation2_db']:g} dB 衰减\n"
                f"TX2 噪声相对 LO：{tx['noise_low_hz']/1e6:g}～{tx['noise_high_hz']/1e6:g} MHz · 种子 0x{tx['seed']:08X}")
            if not mask&1:
                self.train_filename_label.configure(text='TX1 尚未开启，不能开始带调制标签的训练采集。')
            else:
                # Zero-width spaces let Tk wrap the long name at '_' (display only).
                name=training_basename(snapshot,self.v['train_tag'].get(),stamp='开始时刻')+'.iq'
                self.train_filename_label.configure(text=name.replace('_','_\u200b'))
                verify_training_band(snapshot)
        except (ValueError,OverflowError,KeyError) as exc:
            self.train_filename_label.configure(text='待修正：'+str(exc))

    def start_training_capture(self,campaign=None,discard_seconds=0,rate=None):
        """Single training capture. campaign: batch point info stored in the JSON. Returns True if submitted."""
        self.last_training_refusal=''
        if not self.tx_connected or not self.rx_connected or self.recording or self.capture_pending or self.pending-{'monitor'} or (self.monitor_pending and not self.monitoring) or self.monitor_stopping:
            self.last_training_refusal='界面忙或未连接'
            return False
        try:
            self.require_rx_supported()
            if not self.last_tx:
                raise ValueError('请先刷新板端状态。')
            config=waveform({k:v.get() for k,v in self.v.items()})
            verify_training_tx(self.last_tx,config,self.last_tx['applied_mask'],self.demo)
            fs=rate or (25_000_000 if self.v['train_rate'].get().startswith('25') else 1_000_000)
            verify_training_band(configuration_snapshot(self.last_tx,fs,self.demo,self.rx_config()))
            opts=training_options(self.v['train_directory'].get(),self.v['train_tag'].get(),
                                  self.v['train_seconds'].get(),fs,config,self.last_tx['applied_mask'])
            opts['rf']=self.rx_config()
            opts['filter']=self.current_filter(fs)
            ancestor=opts['path'].parent
            while not ancestor.exists():
                ancestor=ancestor.parent
            required=fs*4*opts['seconds']*1.02
            if not self.demo and shutil.disk_usage(ancestor).free<required:
                raise ValueError(f'磁盘剩余空间不足，预计需要约 {required/1e9:.2f} GB。')
            if campaign:opts['campaign']=campaign
            if discard_seconds:opts['discard_seconds']=float(discard_seconds)
        except (ValueError,OSError,OverflowError) as exc:
            self.last_training_refusal=str(exc)
            self.log('无法开始训练采集：'+str(exc),'error')
            if not campaign:messagebox.showerror('无法开始训练采集',str(exc),parent=self)
            return False
        self.capture_mode='training'
        self.capture_pending=True
        self.capture_stopping=False
        self.plot.clear()
        self.training_progress['value']=0
        self.training_summary.configure(text='正在重新核对板端配置…\n参数与 TX 开关已锁定。')
        if not self.send('capture',**opts):
            self.capture_pending=False
            self.capture_mode=None
            self._refresh_controls()
            self.last_training_refusal='采集命令未能提交'
            return False
        return True

    def stop_recording(self):
        if self.recording or self.capture_pending:
            if self.after_monitor_action and self.after_monitor_action[0]=='capture':
                self.after_monitor_action=None
                self.capture_pending=False;self.capture_mode=None
                self._refresh_controls()
                return
            self.capture_stopping=True
            self.worker.stop_capture.set()
            self.activity.configure(text='正在停止录制并排空有效数据，TX 状态保持不变…')
            self._refresh_controls()
        else:
            self.send('stop_remote')

    def all_stop(self):
        if hasattr(self,'campaign'):self.campaign.abort('紧急停止')
        if not self.connected or self.closing or 'all_stop' in self.pending:
            return
        if self._training_active():
            self.worker.training_emergency.set()
        self.monitor_requested=False
        if self.after_monitor_action and self.after_monitor_action[0]=='capture':
            self.capture_pending=False;self.capture_mode=None
        self.after_monitor_action=None
        self.worker.stop_monitor.set()
        if self.monitoring or self.monitor_pending:self.monitor_stopping=True
        self.emergency_waiting=True
        self.emergency_failed=False
        self.capture_stopping=self.recording or self.capture_pending
        if not self.send('all_stop'):
            self.emergency_waiting=False
            self.emergency_failed=True
            self._refresh_controls()

    def _refresh_controls(self):
        busy=bool(self.pending-{'monitor'})
        live=self.recording or self.capture_pending
        observing=self.monitoring or self.monitor_pending
        training=self._training_active()
        if self.emergency_waiting and not live and not observing and not ({'all_stop','capture'} & self.pending):
            self.emergency_waiting=False
        locked=training or self.emergency_waiting
        def enable(widget,yes,readonly=False):
            widget.configure(state=('readonly' if readonly else 'normal') if yes else 'disabled')
        enable(self.connect_btn,not self.tx_connected and not busy and not locked and not self.closing)
        enable(self.port_entry,not self.tx_connected and not busy and not locked)
        enable(self.baud_entry,not self.tx_connected and not busy and not locked,True)
        enable(self.port_refresh_btn,not self.tx_connected and not busy and not locked)
        enable(self.rx_connect_btn,not self.rx_connected and not busy and not locked and not self.closing)
        enable(self.bind_entry,not self.rx_connected and not busy)
        enable(self.peer_entry,not self.rx_connected and not busy)
        enable(self.demo_check,not self.connected and not busy)
        enable(self.disconnect_btn,self.tx_connected and not live and not busy and not locked)
        enable(self.rx_disconnect_btn,self.rx_connected and not live and not busy and not locked)
        enable(self.refresh_btn,self.connected and not busy)
        self.uart_state.configure(text='UART 已握手' if self.tx_connected else 'UART 未连接')
        self.net_state.configure(text='RX 已握手' if self.rx_connected else 'RX 未连接')
        self.plot.set_available(self.rx_connected)
        txbusy=bool(self.pending-{'capture','monitor'})
        for channel,b in ((1,self.tx1_switch),(2,self.tx2_switch)):
            enable(b,self.tx_connected and self.last_tx is not None and not txbusy and not self.capture_pending and not locked and not self.closing)
            value=None if self.last_tx is None else bool(self.last_tx['applied_mask']&channel)
            switching=bool(self.pending & {'enable','configure','all_stop'})
            text='正在确认…' if switching else '状态未确认' if value is None else ('已开启' if value else '已关闭')+(' · 已锁定' if locked else ' · 点击切换')
            b.display(value,text,pending=switching)
        flags=self.last_tx.get('radio_flags',0) if self.last_tx else 0
        rf_fault=bool(flags&24)
        rf_busy=bool(flags&4) and not rf_fault
        rx_state=self.last_rx.get('state') if self.last_rx else None
        idle = not self.rx_connected or self.last_rx is not None and (rx_state in (0,4) or self.monitoring or self.recording)
        if self.rx_connected:
            if rx_state==4:self.net_state.configure(text='RX 故障 · 可清理恢复')
            elif self.last_rx is None:self.net_state.configure(text='RX 已握手 · 等待状态')
            elif not idle:self.net_state.configure(text='RX 已握手 · 外部会话占用')
        self._refresh_rf_status()
        try:tx_supported=not tx_firmware_reason(self.values())
        except (ValueError,OverflowError):tx_supported=False
        uploading=self.upload_job is not None
        enable(self.upload_btn,(self.tx_connected or self.rx_connected) and not live and not locked and not self.closing and
               not uploading and not busy and not rf_busy and not self.monitor_stopping and (tx_supported or not self.tx_connected))
        dirty=self.upload_dirty()
        self.upload_btn.display('busy' if uploading else 'failed' if self.upload_failed else 'dirty' if dirty else 'synced')
        quad=' · 上次 TX 正交校准未收敛' if self.tx_connected and flags&64 and not rf_fault else ''
        self.upload_hint.configure(text=
            ('上传中…' if uploading else
             'upload · 重新初始化射频' if rf_fault and self.tx_connected else
             '录制中 · upload 已禁用' if live else
             '当前 TX 草稿待 FPGA 支持' if self.tx_connected and not tx_supported else
             '上次上传失败' if self.upload_failed else '有未上传修改' if dirty else '已同步')+quad,
            fg=ERROR if self.upload_failed or rf_fault else WARN if dirty and not uploading else MUTED)
        enable(self.readback_btn,self.tx_connected and self.last_tx is not None and not busy and not locked)
        for mode,widget in (('normal',self.record_switch),('training',self.training_switch)):
            own=self.capture_mode==mode
            on=bool(self.recording and own)
            transition=bool(own and (self.capture_pending or self.capture_stopping))
            text=('停止中 · 请等待' if self.capture_stopping else '启动中 · 请等待') if transition else '录制中 · 点击停止' if on else ('训练采集中' if self.capture_mode=='training' else '普通录制中') if live and not own else '未录制 · 点击开始'
            enable(widget,self.rx_connected and (mode!='training' or self.tx_connected) and idle and not self.closing and not self.emergency_waiting and
                   ((on and not self.capture_stopping) or (not live and not busy and not rf_busy and not self.monitor_pending and not self.monitor_stopping)))
            widget.display(on,text,pending=transition)
        for widget in (self.monitor_switch,self.rx_monitor_switch):
            enable(widget,self.rx_connected and idle and not live and not busy and not locked and not self.closing and
                   not self.monitor_pending and not self.monitor_stopping and not rf_busy)
            transition=self.monitor_pending or self.monitor_stopping or self.capture_pending or self.capture_stopping
            text=('切换/停止中 · 请等待' if self.monitor_stopping else '正在开启接收观测…') if transition else \
                 '录制接收中 · 已锁定' if live else '接收观测中 · 不录制' if self.monitoring else '接收观测 · 点击开启'
            if self.capture_pending:text='录制启动中 · 接收待确认'
            elif self.capture_stopping:text='录制停止中 · 请等待'
            value=bool(self.monitoring or self.recording)
            if self.monitor_unknown and not value and not transition:
                value=None;text='接收状态未确认 · 请刷新'
            widget.display(value,text,pending=transition)
        enable(self.all_stop_btn,self.connected and 'all_stop' not in self.pending and not self.closing)
        self.all_stop_btn.configure(text='■ 紧急停止 · 正在确认…' if self.emergency_waiting else
                                    '■ 停止结果未确认 · 再次停止' if self.emergency_failed else '■ 紧急停止 · TX1 + TX2 + IQ')
        for b in self.capture_fields:
            enable(b,not live, isinstance(b,ttk.Combobox))
            if isinstance(b,ttk.Combobox) and str(b.cget('textvariable'))==str(self.v['rate']):
                enable(b,not live and not observing,True)
        enable(self.browse_btn,not live)
        for b in self.edit_fields:
            enable(b,not locked and not self.closing,isinstance(b,ttk.Combobox))
        rx_editable=self.rx_connected and idle and not live and not locked and not self.closing and not busy
        for key in ('rx_center','rx_bandwidth','rx_gain_mode','rx_gain'):
            enable(self.parameter_widgets[key],rx_editable,isinstance(self.parameter_widgets[key],ttk.Combobox))
        for key in ('fm_index','rolloff'):
            fixed=key=='fm_index' or self.v['modulation'].get().endswith(('ASK','PSK','QAM'))
            enable(self.parameter_widgets[key],not locked and not self.closing,fixed)
        enable(self.am_depth_entry,not locked and not self.closing and self.v['modulation'].get() in ('AM','AM-DSB-WC'))
        enable(self.tx1_noise_check,not locked and not self.closing)
        enable(self.parameter_widgets['snr'],not locked and not self.closing and self.v['tx1_noise'].get()=='1')
        enable(self.rx_follow_check,rx_editable)
        enable(self.rx_center_entry,rx_editable and self.v['rx_follow'].get()!='1')
        enable(self.rx_recover_btn,self.rx_connected and rx_state==4 and not live and not observing and not busy and not locked and not self.closing)
        enable(self.rx_rate_entry,rx_editable and not observing,True)
        for b in (self.load_profile_btn,self.save_profile_btn):
            enable(b,not locked and not self.closing)
        # The filter is part of a recording's configuration: locked while one runs.
        filter_free=(not live and not locked and not self.closing and not self.upload_job
                     and self.filter_fs()<=rx_filter.MAX_FS)
        enable(self.filter_check,filter_free)
        enable(self.filter_type_box,filter_free,True)
        lowpass=self.v['filter_type'].get()[:3] in ('LPF','HPF')
        for key,(label,entry) in self.filter_fields.items():
            enable(entry,filter_free and not (key=='filter_f2' and lowpass))
        for b in self.training_fields:
            enable(b,self.rx_connected and not live and not self.closing and not self.campaign.running(),isinstance(b,ttk.Combobox))
        self.campaign.update_controls()
        enable(self.train_browse_btn,not live and not self.closing)
        for b in self.capture_fields:
            if str(b.cget('textvariable'))==str(self.v['rate']):enable(b,rx_editable and not observing,True)

    def _refresh_rf_status(self):
        """Ethernet is optional for UART TX; show RF and network separately."""
        if self.tx_connected and self.last_tx:
            flags=self.last_tx.get('radio_flags',0)
            if flags&24:text,color='射频 / 数据故障 · 可通过应用参数恢复',ERROR
            elif flags&4:text,color='射频操作中',WARN
            elif flags&2:text,color='RF 就绪',OK
            else:text,color='RF 未就绪',WARN
            link_up=bool(flags&1)
        elif self.rx_connected and self.last_rx:
            flags=self.last_rx.get('status_flags',0)
            text,color=('RF 就绪',OK) if flags&1 else ('RF 未就绪 / 故障',WARN)
            link_up=bool(flags&2)
        else:
            self.rf_state_label.configure(text='射频状态未读回',foreground=MUTED)
            return
        if self.demo:text='演示 · '+text
        link_text='PHY/MDIO 链路就绪' if link_up else ('PHY/MDIO 未就绪 · UDP 已通信' if self.rx_connected else 'PHY/MDIO 未就绪；可单独连接 UART')
        self.rf_state_label.configure(text=text+'\n'+link_text,foreground=color)

    def show_tx(self,tx):
        if not self.tx_connected or tx.get('available') is False:
            self.last_tx=None
            for key in ('tx1','tx2'):self.card_values[key].configure(text='UART 未连接 · 状态未知',fg=MUTED)
            self.plot.set_tx(None);self.model_tester.set_tx(None)
            self.update_training_preview();return
        self.last_tx=tx
        self.plot.set_tx(tx);self.model_tester.set_tx(tx)
        firmware='演示' if self.demo else str(tx.get('firmware_version') or '未识别')
        self.version_label.configure(text=f'版本信息：上位机 12.1 · 固件 {firmware} · 控制协议 RX v1 / TX v2')
        mask=tx.get('applied_mask',0)
        for key,bit in (('tx1',1),('tx2',2)):
            state='已开启' if mask&bit else '已关闭'
            att=tx.get('attenuation1_db' if bit==1 else 'attenuation2_db',0)
            mode=display_mode(tx.get('modulation') or '未配置') if key=='tx1' else '噪声'
            self.card_values[key].configure(text=f'{mode} · {state} · {att:g} dB',fg=OK if mask&bit else MUTED,
                font=('Microsoft YaHei UI',14 if len(mode)>7 else 16,'bold'))
        self.update_training_preview()

    def firmware_number(self):
        """Firmware version from the last UART/RX readback, or None if not reported."""
        tx=self.last_tx or {}
        value=tx.get('firmware_version') or getattr(self,'reported_firmware',None)
        try:return int(value) if value is not None else None
        except (TypeError,ValueError):return None

    def show_status(self,data):
        self.tx_connected=data.get('tx_connected',self.tx_connected)
        self.rx_connected=data.get('rx_connected',self.rx_connected)
        self.connected=self.tx_connected or self.rx_connected
        self.last_rx=data['rx'] if self.rx_connected else None
        self.show_tx(data['tx'])
        firmware=data['tx'].get('firmware_version') or data.get('rx_firmware_version') or getattr(self,'reported_firmware',None)
        self.reported_firmware=firmware
        self.version_label.configure(text=f"版本信息：上位机 12.1 · 固件 {'演示' if self.demo else firmware or '未识别'} · 控制协议 RX v1 / TX v2")
        self.status_at=time.monotonic()
        self.status_document=dict(received_local=datetime.now().isoformat(),**data)
        tx,rx=data['tx'],data['rx']
        if rx['state']==0:self.monitor_unknown=False
        rx_label='RX 上次读回（状态查询超时，IQ 仍到达）' if data.get('rx_status_stale') else '板端实际 RX'
        self.rx_actual_label.configure(text=f"{rx_label}：{rx.get('lo_hz',0)/1e6:g} MHz · 模拟带宽 {rx.get('rx_bandwidth_hz',0)/1e6:g} MHz\n"
            f"{('手动增益 '+str(rx.get('rx_gain_mdB',0)/1000)+' dB') if not ((rx.get('status_flags',0)>>3)&3) else ('慢速 AGC' if ((rx.get('status_flags',0)>>3)&3)==1 else '快速 AGC')} · ADC {rx.get('adc_sample_rate_hz',0)/1e6:g} MSPS · IQ {rx.get('fs_eff_hz',0)/1e6:g} MSPS")
        if rx.get('lo_hz'):
            self.plot.set_rf(rx['lo_hz'],rx.get('rx_bandwidth_hz') or 20_000_000)
        self.card_values['link'].configure(text=('UART 已连接' if self.tx_connected else 'UART 未连接')+(' · RX 已连接' if self.rx_connected else ' · RX 未连接'),fg=OK if self.tx_connected else MUTED)
        state='观测中' if rx['state']==2 and self.monitoring else '录制中' if rx['state']==2 and self.recording else STATES.get(rx['state'],'未知')
        self.card_values['rx'].configure(text=(state+(f" · {rx['fs_eff_hz']/1e6:g} M" if rx['fs_eff_hz'] else '')) if self.rx_connected else '网口未连接 · 分析已锁定',fg=ACCENT if self.rx_connected and rx['state']==2 else MUTED)
        self.status_text.configure(state='normal')
        self.status_text.delete('1.0','end')
        self.status_text.insert('1.0',json.dumps(self.status_document,ensure_ascii=False,indent=2))
        self.status_text.configure(state='disabled')
        self._refresh_controls()

    def events(self):
        processed=0
        latest_preview=None
        while processed<100:
            try:
                kind,data=self.worker.events.get_nowait()
            except queue.Empty:
                break
            processed+=1
            if kind=='log':
                self.log(data['text'],data.get('level','info'))
            elif kind=='connected':
                setattr(self,data.get('channel','tx')+'_connected',True)
                self.connected=self.tx_connected or self.rx_connected
                self.demo=data['demo']
                self.update_training_preview()
                self.header_mode.configure(text='界面演示 · 合成源' if self.demo else 'TX 串口控制 · RX 网口接收',fg='#f5bc59' if self.demo else '#a9c0df')
                self.notice.configure(text='离线演示：UART / 网口独立模拟连接。数据为简化基带合成，文件带 DEMO_ 标识。' if self.demo else 'TX 通过 UART 控制；RX 配置与 IQ 通过网口传输。参数修改后点参数页右上角 upload 生效。',bg='#3a2c12' if self.demo else '#132a4a',fg='#f0c97a' if self.demo else '#9cc0f0')
            elif kind in ('disconnected','link_fault'):
                latest_preview=None
                channel=data.get('channel','rx')
                setattr(self,channel+'_connected',False)
                self.connected=self.tx_connected or self.rx_connected
                self.campaign.abort(('UART' if channel=='tx' else '网口')+' 连接断开')
                self.uploaded_links=self.uploaded_links-{channel}
                if self.upload_job:self._upload_finished(('UART' if channel=='tx' else '网口')+' 连接中断')
                if channel=='rx':
                    self.monitor_requested=False;self.monitoring=False;self.monitor_pending=False;self.monitor_stopping=False
                    self.monitor_unknown=False;self.after_monitor_action=None;self.last_rx=None
                    self.plot.set_available(False)
                    self.rx_actual_label.configure(text='板端实际 RX：网口未连接')
                    self.card_values['rx'].configure(text='网口未连接 · 分析已锁定',fg=MUTED)
                else:
                    self.last_tx=None
                    for key in ('tx1','tx2'):self.card_values[key].configure(text='UART 未连接 · 状态未知',fg=MUTED)
                self.card_values['link'].configure(text=('UART 已连接' if self.tx_connected else 'UART 未连接')+(' · RX 已连接' if self.rx_connected else ' · RX 未连接'),fg=MUTED)
                self.update_training_preview()
            elif kind=='status':
                self.show_status(data)
            elif kind=='tx':
                self.show_tx(data['tx'])
            elif kind=='preview':
                # Rendering/DSP may take longer than a preview interval. Drain
                # controls first and render only the newest accepted block.
                # The worker records every complete window independently.
                latest_preview=data
            elif kind=='monitor_started':
                latest_preview=None
                self.monitoring=True;self.monitor_pending=False
                if self.upload_job and self.upload_job['stage']=='rx_start':self._upload_finished(None)
                self.monitor_unknown=False
                self.preview_note.configure(text='演示观测 · 不写盘' if self.demo else '实时观测 · 不写盘')
                self.card_values['rx'].configure(text=f"观测中 · {data['fs']/1e6:g} M",fg=ACCENT)
            elif kind=='monitor_progress':
                stats=data['stats'];n=stats.get('complete_windows',0)
                self.meter_label.configure(text=f"仅观测 · UDP {stats.get('udp_datagrams',0):,} 包 · {n:,} 个有效窗口 · 丢失/冲突 {stats.get('missing_or_conflicting_windows',0):,} · CRC 错误 {stats.get('bad_crc',0):,}")
                self.preview_note.configure(text=data.get('receive_health','观测已开启 · 等待有效 IQ'))
            elif kind=='monitor_finished':
                self.monitoring=False
                self.monitor_unknown=bool(data.get('started') and not data['stop_confirmed'])
                if data.get('error') or (data.get('started') and not data['stop_confirmed']):
                    self.monitor_requested=False
                    if self.after_monitor_action and self.after_monitor_action[0]=='capture':
                        self.capture_pending=False;self.capture_mode=None
                    self.after_monitor_action=None
                self.preview_note.configure(text='观测已停止 · 保留最后窗口' if not data.get('error') else '观测异常 · 已停止显示')
            elif kind=='capture_settling':
                self.campaign.on_capture_settling(data['seconds'])
                self.training_summary.configure(text=f"死区等待 {data['seconds']:g} s · 数据丢弃，参数已锁定")
            elif kind=='capture_started':
                self.campaign.on_capture_started()
                self.recording=True
                self.capture_pending=False
                self.last_capture_path=Path(data['path'])
                # A batch runs unattended: leave the user on whatever page they watch.
                if not self.campaign.running():
                    self.tabs.select(self.training_tab if data.get('training') else self.cap_tab)
                if data.get('training'):
                    self.training_summary.configure(text='正在采集 · 参数已锁定\n'+data['path'])
                self.preview_note.configure(text='演示合成 · 录制中' if self.demo else '接收并录制中')
            elif kind=='progress':
                self.progress['value']=min(100,data['elapsed']/data['seconds']*100)
                stats=data['stats']
                n=stats.get('complete_windows',0)
                missing=stats.get('missing_or_conflicting_windows',0)
                self.meter_label.configure(text=f"UDP {stats.get('udp_datagrams',0):,} 包 · {n:,} 个完整窗口 · {data['bytes']/1e6:.2f} MB")
                self.preview_note.configure(text=data.get('receive_health','接收并录制中'))
                self.capture_summary.configure(text=f"已录制 {data['elapsed']:.1f} / {data['seconds']:g} 秒\n完整窗口 {n:,}  ·  丢失/冲突 {missing:,}  ·  CRC 错误 {stats.get('bad_crc',0):,}\n有效数据时长 {n*1024/data['fs']:.3f} 秒\n{data['path']}")
                if self.capture_mode=='training':
                    self.training_progress['value']=self.progress['value']
                    self.training_summary.configure(text='训练采集中 · 参数与 TX 开关已锁定\n'+self.capture_summary.cget('text'))
            elif kind=='capture_finished':
                self.recording=False
                self.capture_pending=False
                self.capture_stopping=False
                self.last_capture_path=Path(data['path'])
                m=data['metadata']
                if data['error']:self.monitor_requested=False
                stats=m.get('receiver_stats',{})
                n=stats.get('complete_windows',0)
                self.meter_label.configure(text=f"{n:,} 个完整窗口  ·  {m.get('file_bytes',0)/1e6:.2f} MB")
                summary=('录制异常' if data['error'] else '录制已结束')
                if m.get('stopped_by_user') and not data['error']:
                    summary='已按请求停止录制'
                self.capture_summary.configure(text=f"{summary}  ·  {m.get('file_bytes',0)/1e6:.2f} MB\n完整窗口 {n:,}  ·  丢失/冲突 {stats.get('missing_or_conflicting_windows',0):,}  ·  CRC 错误 {stats.get('bad_crc',0):,}\nSTOP {'已确认' if m.get('stop_confirmed') else '未确认 / 未启动'}\n{data['path']}\n{data['error'] or 'TX 开关未因停止录制而改变。'}")
                self.progress['value']=0 if data['error'] else 100
                self.preview_note.configure(text='已停止 · 保留最后窗口')
                self.v['filename'].set(self.new_name())
                self.campaign.on_capture_finished(data['path'],m,data['error'])
                if m.get('training_mode'):
                    reasons=m.get('automatic_label_exclusion_reasons',[])
                    quality='禁止自动贴标签：'+', '.join(reasons) if reasons else '配置一致；仍需检查接收信号质量。'
                    self.training_summary.configure(text=self.capture_summary.cget('text')+'\n'+quality)
                    self.training_progress['value']=self.progress['value']
            elif kind=='done':
                self.pending.discard(data['action'])
                job=self.upload_job
                if job and data['action']=='configure' and job['stage']=='tx':self._upload_rx()
                elif job and data['action']=='monitor' and job['stage']=='rx_stop':
                    # The old session is gone (stopped, or revoked by RF recovery);
                    # the generic restart below opens it with the uploaded RX.
                    job['stage']='rx_start';self.monitor_requested=True
                if data['action']=='monitor':
                    self.monitor_pending=False;self.monitor_stopping=False;self.monitoring=False
                    deferred=self.after_monitor_action
                    self.after_monitor_action=None
                    if deferred and not self.closing and not self.emergency_waiting and not self.emergency_failed:
                        self.send(deferred[0],**deferred[1])
                if data['action']=='capture':
                    self.recording=False
                    self.capture_pending=False
                    self.capture_mode=None
                    self.capture_stopping=False
                if (data['action'] in ('monitor','capture','configure','enable','status') and self.monitor_requested and
                    not self.after_monitor_action and not self.pending and not self.recording and not self.capture_pending and
                    not self.monitoring and not self.monitor_pending):
                    self.start_monitor()
            elif kind=='error':
                job=self.upload_job
                if job and data['action']=='configure' and job['stage']=='tx':
                    job['stage']='failed';self._upload_finished('TX 0x100 未确认：'+data['message'])
                elif job and data['action']=='monitor' and job['stage']=='rx_start':
                    self._upload_finished('RX 观测重启失败：'+data['message'])
                restarting=bool(self.upload_job and self.upload_job['stage']=='rx_stop')
                if data['action'] in ('monitor','capture','configure') and not restarting:
                    self.monitor_requested=False
                if data['action']=='monitor':
                    if self.after_monitor_action and self.after_monitor_action[0]=='capture':
                        self.capture_pending=False;self.capture_mode=None
                    self.after_monitor_action=None
                if data['action']=='all_stop':
                    self.emergency_failed=True
                self.log(f"操作失败 [{data['action']}]：{data['message']}",'error')
                if data['action']=='capture' and self.capture_mode=='training':
                    self.training_summary.configure(text='训练采集未完成：'+data['message'])
                if data['action']=='capture':self.campaign.on_capture_error(data['message'])
                if data['action']=='all_stop':self.campaign.abort('紧急停止')
                if data['uncertain'] and data['action'] in ('configure','enable','all_stop'):
                    self.last_tx=None
                    for key in ('tx1','tx2'):self.card_values[key].configure(text='UART 操作未确认',fg=WARN)
                if data['action']=='poll':self.log('状态轮询失败：'+data['message'],'warning')
                if data['action']!='poll' and not self.closing:
                    detail='\n\n请查看日志并刷新状态；通信超时不能视为板端操作未执行。' if data['uncertain'] else ''
                    messagebox.showerror('操作未确认',data['message']+detail,parent=self)
            elif kind=='shutdown':
                self.destroy()
                return
            self._refresh_controls()
        if processed:self.hold_height(self.training_summary,self.capture_summary)
        if latest_preview is not None and self.rx_connected and not self.closing:
            self.plot.update_signal(latest_preview['raw'],latest_preview['fs'],self.demo,latest_preview.get('context'))
            self.model_tester.feed(latest_preview['raw'],latest_preview['fs'])
        if self.winfo_exists():
            self.after(60,self.events)

    def readback(self):
        if self._training_active():
            return
        if not self.last_tx:
            return
        tx=self.last_tx
        if not tx.get('seed'):
            messagebox.showinfo('尚无波形配置','板端尚未配置波形，请先应用参数。',parent=self)
            return
        regs=tx['registers']
        offset=regs[6] if regs[6]<2**31 else regs[6]-2**32
        values=dict(modulation=display_mode(tx.get('modulation') or '4PSK'),center=tx['center_hz']/1e6,
                    bandwidth=tx['bandwidth_hz']/1e6,snr=tx['snr_db'],atten1=tx['attenuation1_db'],
                    atten2=tx['attenuation2_db'],noise_low=tx['noise_low_hz']/1e6,
                    noise_high=tx['noise_high_hz']/1e6,seed=hex(tx['seed']),
                    offset=round(offset*25_000_000/2**32)/1e6,am_depth=regs[14]/32768,
                    rolloff='0.35',fm_index='4',tx1_noise='1' if regs[11] else '0')
        if regs[0] in (7,8):
            values['sideband']='LSB / 下边带' if regs[15]&1 else 'USB / 上边带'
        if regs[0]==8 and regs[14]>0:values['carrier_ratio']=20*math.log10(regs[14]/16384)
        for key,value in values.items():
            self.v[key].set(f'{value:g}' if isinstance(value,float) else str(value))
        self.log('已把板上参数填入编辑框，未发送新配置。')

    def browse(self):
        if self.recording or self.capture_pending:
            return
        path=filedialog.askdirectory(parent=self,initialdir=self.v['directory'].get(),title='选择 IQ 录制目录')
        if path:
            self.v['directory'].set(path)

    def open_directory(self):
        path=self.last_capture_path.parent if self.last_capture_path else Path(self.v['directory'].get())
        try:
            path.mkdir(parents=True,exist_ok=True)
            os.startfile(path)
        except OSError as exc:
            messagebox.showerror('无法打开目录',str(exc),parent=self)

    def browse_training(self):
        if self.recording or self.capture_pending:
            return
        path=filedialog.askdirectory(parent=self,initialdir=self.v['train_directory'].get(),title='选择训练数据目录')
        if path:
            self.v['train_directory'].set(path)

    def open_training_directory(self):
        path=Path(self.v['train_directory'].get())
        try:
            path.mkdir(parents=True,exist_ok=True)
            os.startfile(path)
        except OSError as exc:
            messagebox.showerror('无法打开目录',str(exc),parent=self)

    def save_profile(self):
        if self._training_active():
            return
        try:
            parameters=active_parameters(self.values())
            path=filedialog.asksaveasfilename(parent=self,title='保存 TX / RX 参数草稿',defaultextension='.json',filetypes=[('JSON 参数','*.json')],initialfile='radio_profile.json')
            if path:
                Path(path).write_text(json.dumps(dict(schema='KU5P_GUI_PROFILE_2',hardware_applied=False,
                    pending_fpga_reason=tx_firmware_reason(self.values()) or rx_firmware_reason(self.values()),
                    parameters=parameters),ensure_ascii=False,indent=2),encoding='utf-8')
                self.log('参数已保存：'+path)
        except (ValueError,OSError,OverflowError) as exc:
            messagebox.showerror('无法保存参数',str(exc),parent=self)

    def load_profile(self):
        if self._training_active():
            return
        path=filedialog.askopenfilename(parent=self,title='载入发射参数',filetypes=[('JSON 参数','*.json')])
        if not path:
            return
        try:
            profile=json.loads(Path(path).read_text(encoding='utf-8'))
            if profile['schema'] not in ('KU5P_GUI_PROFILE_1','KU5P_GUI_PROFILE_2'):
                raise ValueError('不是 KU5P 图形界面的参数文件。')
            parameters={**DEFAULTS,**profile['parameters']}
            parameters['modulation']=display_mode(parameters['modulation'])
            normalized=normalize_hw06_draft(parameters)
            validate_draft(parameters)
            self.loading_profile=True
            try:
                for k,v in parameters.items():
                    if k in DEFAULTS:
                        if not self.rx_connected and k in ('rx_follow','rx_center','rx_bandwidth','rx_gain_mode','rx_gain','rate'):
                            continue
                        self.v[k].set(str(v))
            finally:
                self.loading_profile=False
            self.update_plan()
            self.update_rx_plan()
            self.log('已载入参数到编辑框，尚未发送到板端。')
            if normalized:self.log('参数已适配：'+', '.join(normalized)+'；未来调制草稿保留。')
        except (OSError,ValueError,KeyError,TypeError,OverflowError) as exc:
            messagebox.showerror('无法载入参数',str(exc),parent=self)

    def export_status(self):
        path=filedialog.asksaveasfilename(parent=self,title='导出最近状态',defaultextension='.json',filetypes=[('JSON','*.json')],initialfile='ku5p_status.json')
        if path:
            try:
                Path(path).write_text(json.dumps(self.status_document,ensure_ascii=False,indent=2),encoding='utf-8')
            except OSError as exc:
                messagebox.showerror('无法导出',str(exc),parent=self)

    def clock(self):
        self.campaign.tick()
        if self.connected and self.status_at and time.monotonic()-self.status_at>12 and not self.pending:
            self.card_values['link'].configure(text='状态已过期 · 请刷新',fg=WARN)
        self.after(1000,self.clock)

    def close(self):
        if self.closing:
            return
        self.commands.close()
        try:
            self.settings.write_text(json.dumps({k:self.v[k].get() for k in DEFAULTS},ensure_ascii=False,indent=2),encoding='utf-8')
        except OSError:
            pass
        self.closing=True
        self.monitor_requested=False;self.after_monitor_action=None
        self.log('正在关闭；如有录制将尝试发送 STOP。板上 TX 不因关闭界面而关闭。')
        self.model_tester.close()
        self.worker.shutdown()
        self._refresh_controls()
        self.title('KU5P · 正在排空录制并关闭连接…')


def main():
    # Analysis worker processes re-enter the frozen EXE; let them run their task.
    import multiprocessing
    multiprocessing.freeze_support()
    if sys.platform=='win32':
        try:
            ctypes.windll.shcore.SetProcessDpiAwareness(1)
        except Exception:
            pass
    app=Application()
    if '--serve' in sys.argv:
        # --serve [port]: open the local command port at start (127.0.0.1 only).
        i=sys.argv.index('--serve');arg=sys.argv[i+1] if i+1<len(sys.argv) else ''
        for level,text in app.commands.execute('serve '+(arg if arg.isdigit() else '')):app.log(text,level)
    if '--self-test' in sys.argv:
        from exe_selftest import install
        install(app)
    app.mainloop()


if __name__=='__main__':
    main()
