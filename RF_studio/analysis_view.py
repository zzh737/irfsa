"""Shared real-IQ analysis, docked/focused/detached Tk views. No hardware commands."""
from __future__ import annotations

import cmath
import math
import struct
import time
import tkinter as tk
from collections import deque
from tkinter import ttk

from signal_view import SignalView,envelope_points
import numpy as np
from dsp_analysis import iq_array,periodogram,synchronize,tx_symbol_plan,FFT_SIZES,LINEAR_FAMILIES
import analysis_workers
import theme

PLOT='#0c1729'
PLOT_RGB=np.array((0x0c,0x17,0x29),dtype=float)
DOT_LOW=np.array((0x2a,0x7f,0x9a),dtype=float);DOT_HIGH=np.array((0xb8,0xf4,0xf0),dtype=float)
WATERFALL=np.array([(0x0d,0x19,0x30),(0x19,0x2b,0x52),(0x27,0x3c,0x70),(0x28,0x69,0x86),
                    (0x2b,0xa9,0x9f),(0x94,0xcf,0x84),(0xf7,0xdf,0x63)],dtype=np.uint8)
# 256-step colour scale through the same anchors: contrast changes stay smooth.
WATERFALL_LUT=np.stack([np.interp(np.linspace(0,6,256),np.arange(7),WATERFALL[:,c]) for c in range(3)],axis=1).astype(np.uint8)
TITLES={'iq':'I/Q 波形 + FFT','constellation':'星座图','spectrum':'全域功率谱 + 瀑布图'}
def engineering(value,unit):
    for scale,prefix in ((1e9,'G'),(1e6,'M'),(1e3,'k'),(1,''),(1e-3,'m'),(1e-6,'μ'),(1e-9,'n')):
        if abs(value)>=scale or scale==1e-9:return f'{value/scale:.5g} {prefix}{unit}'


def psd(raw,fs,nfft=1024):
    """Two-sided complex Hann periodogram, normalized to ADC peak code 2048."""
    samples=iq_array(raw)
    return tuple(np.frombuffer(raw,dtype='<i2')),periodogram(samples,fs,nfft).tolist()


class AnalysisCanvas(tk.Canvas):
    def __init__(self,parent,kind,owner):
        super().__init__(parent,bg=PLOT,highlightthickness=0)
        self.kind,self.owner=kind,owner
        self.bind('<Configure>',lambda _:self.draw())

    def text(self,x,y,value,size=9,anchor='w',color='#8fa8c6'):
        self.create_text(x,y,text=value,anchor=anchor,fill=color,font=('Microsoft YaHei UI',size))

    def grid(self,box,yticks,xticks):
        l,t,r,b=box
        for f,label in yticks:
            y=t+f*(b-t)
            self.create_line(l,y,r,y,fill='#22364d')
            self.text(l-8,y,label,8,'e')
        for f,label in xticks:
            x=l+f*(r-l)
            self.create_line(x,t,x,b,fill='#1d3049')
            self.text(x,b+16,label,8,'center')

    def draw(self):
        self.delete('all')
        w,h=self.winfo_width(),self.winfo_height()
        if w<180 or h<130:return
        if self.kind=='constellation':self.constellation(w,h)
        else:self.spectrum(w,h)

    def constellation(self,w,h):
        o=self.owner
        context=o.context or {}
        mode=context.get('modulation','')
        source=(f'{mode} 简化基带演示' if context.get('tx1') else '演示 · TX1 关闭') if o.demo else ('实采 · '+o.receive_mode.get() if o.sync_active else '实采 · 原始 I/Q 点云')
        self.text(14,15,source+' · '+('显示归一化' if o.normalize.get() or o.sync_active else 'ADC 码值'),9)
        note=o.sync_status.get() if o.sync_active else ('矩形符号演示；无射频信道' if o.demo else '原始点云；开启同步后观察符号星座')
        if o.demo and context.get('undersampled'):
            self.text(14,35,'信号超出输出可用带宽，可能出现混叠',8,color='#f5bc59')
        elif o.demo and context.get('offset_hz'):
            self.text(14,35,f"含频偏 {context['offset_hz']/1e6:g} MHz，点云会旋转",8,color='#f5bc59')
        size=max(40,min(w-110,h-124))
        cx,cy=w/2,(h+26)/2
        box=cx-size/2,cy-size/2,cx+size/2,cy+size/2
        lim=1.8 if o.normalize.get() or o.sync_active else o.amplitude_limit
        self.grid(box,[(0,f'{lim:g}'),(.5,'0'),(1,f'−{lim:g}')],
                  [(0,f'−{lim:g}'),(.5,'0'),(1,f'+{lim:g}')])
        self.text(cx+size/2+12,cy,'I',11)
        self.text(cx,cy-size/2-11,'Q',11,'center')
        points=o.points
        if not len(points):
            self.text(cx,cy,'等待有效 IQ 数据',11,'center')
        else:
            if o.remove_dc.get():points=points-points.mean()
            norm=float(np.sqrt(np.mean(abs(points)**2))) if o.normalize.get() or o.sync_active else 1.
            norm=max(norm,1e-12)
            # One bitmap instead of thousands of canvas items; colour = hit density.
            px=int(size)
            x=np.floor((points.real/norm/(2*lim)+.5)*px).astype(int)
            y=np.floor((.5-points.imag/norm/(2*lim))*px).astype(int)
            keep=(x>=0)&(x<px)&(y>=0)&(y<px)
            hits=np.bincount(y[keep]*px+x[keep],minlength=px*px).reshape(px,px)
            hits=np.maximum(hits,np.pad(hits,((0,0),(1,0)))[:,:-1])  # 2-pixel-wide dots
            level=np.clip(np.log1p(hits)/math.log1p(max(1,int(hits.max()))),0,1)[...,None]
            rgb=np.where(hits[...,None]>0,DOT_LOW+(DOT_HIGH-DOT_LOW)*level,PLOT_RGB).astype(np.uint8)
            self.image=tk.PhotoImage(data=f'P6 {px} {px} 255 '.encode()+rgb.tobytes(),format='PPM')
            self.create_image(box[0],box[1],image=self.image,anchor='nw')
            self.grid(box,[(0,''),(.5,''),(1,'')],[(0,''),(.5,''),(1,'')])
        self.text(w-12,h-13,note,8,'e')

    def spectrum(self,w,h):
        o=self.owner
        l,r=60,w-28;split=int(h*.44)
        t,b=35,split-11;wt,wb=split+48,h-40
        self.text(14,15,'功率谱密度 · dBFS/Hz · 未标定 dBm',9)
        high,low=o.db_high,o.db_low
        self.grid((l,t,r,b),[(f,f'{high+(low-high)*f:.0f}') for f in (0,.33,.67,1)],[])
        self.text(14,split+23,'瀑布图 · 新数据在上 · 与功率谱共用频率轴',9)
        fs=o.fs
        span=o.view_span
        center=o.center+o.view_offset
        for i in range(5):
            x=l+(r-l)*i/4
            self.create_line(x,wt,x,wb,fill='#20354c')
            self.text(x,wb+15,engineering(center-span/2+span*i/4,'Hz'),8,'center')
        self.text((l+r)/2,h-9,'接收射频频率 · 显示跨度 '+engineering(span,'Hz'),8,'center')
        if not len(o.power):
            self.text((l+r)/2,(t+b)/2,'等待有效 IQ 数据',11,'center')
            self.text((l+r)/2,(wt+wb)/2,'最高显示当前接收 20 MHz 瞬时带宽',10,'center')
            return
        n=len(o.power)
        freq=(np.arange(n)-n//2)*fs/n
        keep=np.flatnonzero((freq>=o.view_offset-span/2)&(freq<=o.view_offset+span/2))
        xs=l+(freq[keep]-o.view_offset+span/2)/span*(r-l)
        for values,color in ((o.peak,'#ac8df5'),(o.average,'#779cff'),(o.power,'#52d3f4')):
            if len(values)!=n:continue
            db=10*np.log10(np.maximum(np.asarray(values)[keep],1e-18))
            coords=envelope_points(xs,t+(high-np.clip(db,low,high))/(high-low)*(b-t),l,r)
            if len(coords)>=4:self.create_line(coords,fill=color,width=1.1)
        history=list(o.history)
        width,height=max(1,int(r-l)),max(1,int(wb-wt))
        if len(keep) and history:
            # Mean power per waterfall column, one row per history frame, newest on top.
            cols=min(110,len(keep))
            edges=np.linspace(0,len(keep),cols+1).astype(int);edges[1:]=np.maximum(edges[1:],edges[:-1]+1)
            starts=np.minimum(edges[:-1],len(keep)-1)
            frames=np.array([v for _,v in reversed(history) if len(v)==n])
            if len(frames):
                sums=np.add.reduceat(frames[:,keep],starts,axis=1)/np.diff(np.r_[starts,len(keep)])
                db=10*np.log10(np.maximum(sums,1e-18))
                w_low,w_high=o.waterfall_limits(db)
                index=np.rint(np.clip((db-w_low)/(w_high-w_low),0,1)*255).astype(int)
                rgb=WATERFALL_LUT[index]
                self.text(r,split+23,f'色标 {w_low:.0f}～{w_high:.0f} dB',8,'e')
                rows=np.minimum(np.arange(height)*len(frames)//height,len(frames)-1)
                columns=np.minimum(np.arange(width)*cols//width,cols-1)
                bitmap=np.ascontiguousarray(rgb[rows][:,columns])
                self.image=tk.PhotoImage(data=f'P6 {width} {height} 255 '.encode()+bitmap.tobytes(),format='PPM')
                self.create_image(l,wt,image=self.image,anchor='nw')
                for i in range(5):self.create_line(l+(r-l)*i/4,wt,l+(r-l)*i/4,wb,fill='#20354c')
        elapsed=history[-1][0]-history[0][0] if len(history)>1 else 0
        self.text(l-8,wt,'0 s',8,'e')
        self.text(l-8,wb,f'−{elapsed:.1f} s',8,'e')
        self.text(w-14,15,f'FFT {len(o.power)} · 当前 / 平均 / 峰值',8,'e')


class Panel(tk.Frame):
    def __init__(self,parent,kind,owner,focused=False,detached=False):
        super().__init__(parent,bg=PLOT,highlightbackground='#26364a',highlightthickness=1)
        self.kind,self.owner=kind,owner
        header=tk.Frame(self,bg=PLOT)
        header.pack(fill='x',padx=10,pady=(7,2))
        title=tk.Label(header,text=TITLES[kind],bg=PLOT,fg='#d6e4f5',font=('Microsoft YaHei UI',11,'bold'))
        title.pack(side='left')
        title.bind('<Double-Button-1>',lambda _:owner.focus(kind))
        def button(text,command):
            b=tk.Button(header,text=text,command=command,bg='#1e3552',fg='#c5d9f0',
                        activebackground='#285079',activeforeground='white',relief='flat',
                        padx=7,pady=3,font=('Microsoft YaHei UI',9))
            b.pack(side='right',padx=(5,0))
        if detached:
            button('↙ 收回',lambda:owner.dock(kind))
        else:
            button('↗ 弹出',lambda:owner.popout(kind))
            button('← 返回总览' if focused else '□ 放大',owner.overview if focused else lambda:owner.focus(kind))
        if kind=='iq':self.chart=SignalView(self)
        else:self.chart=AnalysisCanvas(self,kind,owner)
        self.chart.pack(fill='both',expand=True,padx=4,pady=(0,4))
        self.render()

    def render(self):
        o=self.owner
        if self.kind=='iq':
            if o.display_raw:
                self.chart.time_span=o.time_span;self.chart.amplitude_limit=o.amplitude_limit
                self.chart.fft_size=o.actual_fft;self.chart.span=o.view_span;self.chart.offset=o.view_offset
                self.chart.update_signal(o.display_raw,o.fs,o.demo,o.iq_db)
            else:self.chart.clear()
        else:self.chart.draw()


class AnalysisDashboard(ttk.Frame):
    """The same accepted IQ window feeds every view, including pop-outs."""
    def __init__(self,parent,emergency,layout_changed=None,filter_panel=None):
        super().__init__(parent,style='White.TFrame')
        self.emergency=emergency
        self.layout_changed=layout_changed
        self.available=True
        self.raw=None;self.display_raw=None;self.fs=1_000_000;self.center=2_400_000_000;self.rx_bandwidth=20_000_000
        self.demo=False;self.power=[];self.average=[];self.peak=[];self.iq_db=None
        self.context=None;self.latest_context=None
        self.points=np.zeros(0,dtype=complex);self.history=deque(maxlen=40);self.frames=deque(maxlen=8)
        self.panels={};self.windows={};self.focused=None
        self.paused=tk.BooleanVar(value=False)
        self.normalize=tk.BooleanVar(value=True)
        self.remove_dc=tk.BooleanVar(value=False)
        # AUTO is one-shot: the first block (and each AUTO click) fills the
        # manual fields once; afterwards the fields stay as the user left them.
        self.auto_pending=True;self.manual_time=tk.StringVar(value='256')
        self.manual_span=tk.StringVar(value='20');self.manual_offset=tk.StringVar(value='0')
        self.manual_fft=tk.StringVar(value='4096');self.manual_amplitude=tk.StringVar(value='2048')
        self.manual_high=tk.StringVar(value='-60');self.manual_range=tk.StringVar(value='90')
        # Waterfall colour floor/top, separate from the PSD axis. AUTO fills them once
        # from the next waterfall drawn; editing them only redraws (history is kept).
        self.wf_low=tk.StringVar(value='-150');self.wf_high=tk.StringVar(value='-60')
        self.wf_limits=(-150.,-60.);self.wf_auto_pending=True
        self.receive_mode=tk.StringVar(value='4PSK');self.symbol_rate=tk.StringVar(value='100')
        self.follow_tx=tk.BooleanVar(value=True);self.tx_plan=None;self.rx_lo_hz=None
        self.carrier_sync=tk.BooleanVar(value=False);self.symbol_sync=tk.BooleanVar(value=False)
        self.sync_status=tk.StringVar(value='同步关闭 · 原始 IQ');self.sync_active=False
        self.rate_note=tk.StringVar(value='')
        self.time_span=256/self.fs;self.amplitude_limit=2048.;self.view_span=800000.;self.view_offset=0.
        self.actual_fft=1024;self.db_high=-60.;self.db_low=-150.
        self.generation=0;self.pool=analysis_workers.AnalysisPool(self,self._deliver)
        toolbar=ttk.Frame(self,style='White.TFrame')
        toolbar.pack(fill='x',padx=10,pady=(5,7))
        ttk.Button(toolbar,text='同窗总览',command=self.overview).pack(side='left')
        ttk.Checkbutton(toolbar,text='暂停显示',variable=self.paused,command=self.resume).pack(side='left',padx=7)
        ttk.Checkbutton(toolbar,text='星座归一化',variable=self.normalize,command=self.redraw).pack(side='left')
        ttk.Checkbutton(toolbar,text='去均值',variable=self.remove_dc,command=self.redraw).pack(side='left',padx=7)
        ttk.Button(toolbar,text='清除历史',command=self.clear_history).pack(side='right')
        self.workspace=ttk.Frame(self,style='White.TFrame')
        self.workspace.pack(fill='both',expand=True)
        self.toolbar=toolbar
        options=ttk.Frame(self,style='White.TFrame');options.pack(fill='x',before=self.workspace,padx=10,pady=(0,6))
        self.options=options
        self.auto_button=ttk.Button(options,text='AUTO',width=6,command=self.auto_once)
        self.auto_button.grid(row=0,column=0,sticky='w')
        specs=(('时间窗/μs',self.manual_time),('跨度/MHz',self.manual_span),('频偏/MHz',self.manual_offset),
               ('FFT点数',self.manual_fft),('幅度/码',self.manual_amplitude),('参考/dBFS/Hz',self.manual_high),('范围/dB',self.manual_range))
        self.manual_widgets=[]
        for index,(label,var) in enumerate(specs):
            f=ttk.Frame(options,style='White.TFrame');f.grid(row=index//4,column=index%4+1,padx=5,sticky='w')
            ttk.Label(f,text=label,style='Hint.TLabel').pack(anchor='w')
            entry=ttk.Combobox(f,textvariable=var,values=FFT_SIZES,width=8,state='readonly') if var is self.manual_fft else ttk.Entry(f,textvariable=var,width=8)
            entry.pack();entry.bind('<Return>',lambda e:self.manual_edited());entry.bind('<FocusOut>',lambda e:self.manual_edited())
            if var is self.manual_fft:entry.bind('<<ComboboxSelected>>',lambda e:self.manual_edited())
            self.manual_widgets.append(entry)
        # Waterfall colour scale: its own column right of the view fields (no extra
        # height for the plots); AUTO fills it together with the fields on the left.
        ttk.Separator(options,orient='vertical').grid(row=0,column=5,rowspan=2,sticky='ns',padx=(10,5))
        for row,(label,var) in enumerate((('瀑布下限/dB',self.wf_low),('瀑布上限/dB',self.wf_high))):
            f=ttk.Frame(options,style='White.TFrame');f.grid(row=row,column=6,padx=5,sticky='w')
            ttk.Label(f,text=label,style='Hint.TLabel').pack(anchor='w')
            entry=ttk.Entry(f,textvariable=var,width=8);entry.pack()
            entry.bind('<Return>',lambda e:self.waterfall_edited());entry.bind('<FocusOut>',lambda e:self.waterfall_edited())
            self.manual_widgets.append(entry)
        # RX filter: right of the waterfall scale when the pane is wide enough,
        # otherwise under the view fields. The strip never asks the paned window for
        # more width than before, so the left parameter panel keeps its size.
        self.filter_box=None
        if filter_panel:
            self.filter_sep=ttk.Separator(options,orient='vertical')
            self.filter_box=ttk.Frame(options,style='White.TFrame')
            filter_panel(self.filter_box)
            self.filter_wide=None
            self.bind('<Configure>',self._place_filter,add='+')
            self._place_filter()
        sync=ttk.Frame(options,style='White.TFrame');sync.grid(row=2,column=0,columnspan=7,sticky='ew',pady=(5,0))
        ttk.Label(sync,text='接收调制',style='White.TLabel').pack(side='left')
        modes=tuple(f'{m}{family}' for family in ('ASK','PSK') for m in (2,4,8,16))+('16QAM','64QAM','256QAM')
        box=ttk.Combobox(sync,textvariable=self.receive_mode,values=modes,width=9,state='readonly');box.pack(side='left',padx=4)
        ttk.Label(sync,text='符号率/ksym/s',style='White.TLabel').pack(side='left')
        self.rate_entry=ttk.Entry(sync,textvariable=self.symbol_rate,width=9);self.rate_entry.pack(side='left',padx=4)
        ttk.Checkbutton(sync,text='跟随 TX',variable=self.follow_tx,command=self.follow_changed).pack(side='left',padx=(0,4))
        ttk.Checkbutton(sync,text='载波同步',variable=self.carrier_sync,command=self.analysis_changed).pack(side='left',padx=4)
        ttk.Checkbutton(sync,text='符号同步',variable=self.symbol_sync,command=self.analysis_changed).pack(side='left',padx=4)
        ttk.Label(options,textvariable=self.rate_note,style='Hint.TLabel',wraplength=620).grid(row=3,column=0,columnspan=7,sticky='w',pady=(3,0))
        ttk.Label(options,textvariable=self.sync_status,style='Hint.TLabel',wraplength=620).grid(row=4,column=0,columnspan=7,sticky='w',pady=(1,0))
        self.mode_box=box
        box.bind('<<ComboboxSelected>>',lambda e:self.analysis_changed())
        self.rate_entry.bind('<Return>',lambda e:self.analysis_changed());self.rate_entry.bind('<FocusOut>',lambda e:self.analysis_changed())
        self.follow_changed(recompute=False)
        self.lock_notice=ttk.Label(self,text='网口 RX 未连接\n完成 RFCT 接收协议握手后，才能开启接收分析。',
                                  style='Hint.TLabel',anchor='center',justify='center')
        self.overview()

    def destroy(self):
        self.pool.close()
        super().destroy()

    def set_available(self,available):
        if self.available==available:return
        self.available=available
        for widget in self.toolbar.winfo_children():widget.configure(state='normal' if available else 'disabled')
        if available:
            self.lock_notice.pack_forget();self.workspace.pack(fill='both',expand=True)
        else:
            for kind in tuple(self.windows):self.dock(kind)
            self.overview();self.clear()
            self.workspace.pack_forget();self.lock_notice.pack(fill='both',expand=True)
        self.options.pack_forget()
        if available:self.options.pack(fill='x',before=self.workspace,padx=10,pady=(0,6))

    def set_rf(self,center,bandwidth=20_000_000):
        if (center,bandwidth)!=(self.center,self.rx_bandwidth):
            self.clear()
        self.center,self.rx_bandwidth=center,bandwidth
        self.rx_lo_hz=center
        self.update_rate_note();self.redraw()

    def set_tx(self,tx):
        """Board TX readback (RFCT 0x102); drives the 'follow TX' symbol rate."""
        plan=tx_symbol_plan(tx)
        if plan==self.tx_plan:return
        self.tx_plan=plan
        if self.follow_tx.get():self.follow_changed()
        else:self.update_rate_note()

    def clear(self):
        self.generation+=1
        self.raw=None;self.display_raw=None;self.power=[];self.average=[];self.peak=[];self.iq_db=None
        self.points=np.zeros(0,dtype=complex);self.history.clear();self.frames.clear()
        self.redraw()

    def clear_history(self):
        self.points=np.zeros(0,dtype=complex);self.history.clear();self.frames.clear()
        self.peak=np.array(self.power);self.average=np.array(self.power)
        self.redraw()

    def effective_symbol_rate(self):
        """(rate_hz, source). Follow uses the exact readback NCO rate, not the rounded text."""
        if self.follow_tx.get() and self.tx_plan:return self.tx_plan['symbol_rate_hz'],'tx'
        rate=float(self.symbol_rate.get())*1000
        if not math.isfinite(rate) or rate<=0:raise ValueError('请输入大于 0 的符号率')
        return rate,'manual'

    def carrier_prior(self):
        """Known carrier offset of TX1 relative to the RX LO, removed before the coarse CFO search."""
        if not (self.follow_tx.get() and self.tx_plan):return 0.
        if self.demo:return float((self.context or {}).get('offset_hz') or 0.)
        if not self.rx_lo_hz or not self.tx_plan['center_hz']:return 0.
        return float(self.tx_plan['center_hz']+self.tx_plan['offset_hz']-self.rx_lo_hz)

    def update_rate_note(self):
        notes=[]
        plan=self.tx_plan;fs=self.fs
        if self.follow_tx.get():
            if plan:notes.append(f"跟随板端 TX1：{plan['modulation']} · Rs {plan['symbol_rate_hz']/1e3:.6g} ksym/s")
            else:notes.append('跟随 TX：TX1 未读回 ASK/PSK/QAM 配置，暂用手动符号率')
        if plan and plan['modulation']!=self.receive_mode.get():
            notes.append(f"接收调制与 TX1（{plan['modulation']}）不一致")
        try:rate,_=self.effective_symbol_rate()
        except ValueError:rate=0.
        if rate>fs/2:
            notes.append(f'每符号仅 {fs/rate:.2f} 个采样点，无法同步：{fs/1e6:g} MSPS 下需 Rs ≤ {fs/2e3:g} k'
                         +('，请改用 25 MSPS 或减小 TX 带宽' if fs<25e6 else ''))
        if plan and self.rx_lo_hz and not self.demo:
            offset=plan['center_hz']+plan['offset_hz']-self.rx_lo_hz
            edge=abs(offset)+plan['bandwidth_hz']/2;usable=min(self.rx_bandwidth,.8*fs)/2
            if edge>usable:
                notes.append(f'TX1 占用 {offset/1e3:+.6g} kHz ± {plan["bandwidth_hz"]/2e3:g} kHz，超出当前可用 ±{usable/1e3:g} kHz')
        self.rate_note.set(' · '.join(notes))

    def follow_changed(self,recompute=True):
        following=self.follow_tx.get()
        if following and self.tx_plan:self.symbol_rate.set(f"{self.tx_plan['symbol_rate_hz']/1e3:.6g}")
        self.rate_entry.configure(state='disabled' if following and self.tx_plan else 'normal')
        self.update_rate_note()
        if recompute:self.analysis_changed()

    def manual_values(self):
        return tuple(v.get() for v in (self.manual_time,self.manual_span,self.manual_offset,self.manual_fft,
                                       self.manual_amplitude,self.manual_high,self.manual_range))

    def manual_edited(self):
        """Recompute only when a view field really changed (focus-out alone keeps averaging)."""
        values=self.manual_values()
        if values==getattr(self,'_applied_manual',None):return
        self._applied_manual=values;self.auto_pending=False
        self.analysis_changed()

    def _place_filter(self,event=None):
        box=self.filter_box
        if box is None:return
        base=self.options.grid_bbox(0,0,6,1)[2]+40      # width of the view + waterfall columns
        wide=self.winfo_width()>=base+box.winfo_reqwidth()
        if wide==self.filter_wide:return
        self.filter_wide=wide
        if wide:
            self.filter_sep.grid(row=0,column=7,rowspan=2,sticky='ns',padx=(10,5))
            box.grid(row=0,column=8,rowspan=2,sticky='nw')
        else:
            self.filter_sep.grid_remove()
            box.grid(row=5,column=0,columnspan=9,sticky='w',pady=(6,0))
        # Requested width of the strip must not grow the pane (would squeeze the left panel).
        self.options.grid_propagate(True)

    def waterfall_edited(self):
        try:
            low,high=float(self.wf_low.get()),float(self.wf_high.get())
            if not (math.isfinite(low) and math.isfinite(high)) or high-low<1:raise ValueError
        except ValueError:
            low,high=self.wf_limits
            self.wf_low.set(f'{low:g}');self.wf_high.set(f'{high:g}')
            self.sync_status.set('瀑布图对比度须为有限数值，且上限比下限至少高 1 dB；已恢复上次的值。')
            return
        if (low,high)!=self.wf_limits:self.wf_limits=(low,high);self.wf_auto_pending=False;self.redraw()

    def waterfall_limits(self,db):
        """Colour floor/top for the displayed waterfall cells (dBFS/Hz)."""
        if self.wf_auto_pending:
            # Floor just under the noise, top at the strongest signal; >=15 dB keeps
            # a noise-only picture from turning into speckle.
            low=math.floor(float(np.percentile(db,5)));high=max(math.ceil(float(np.percentile(db,99.5))),low+15)
            self.wf_auto_pending=False;self.wf_limits=(float(low),float(high))
            self.wf_low.set(str(low));self.wf_high.set(str(high))
        return self.wf_limits

    def auto_once(self):
        """One AUTO pass on the next/current block; the manual fields then keep the result."""
        self.auto_pending=True;self.wf_auto_pending=True
        self.analysis_changed()

    def _manual_view(self,fs,samples_count):
        for variable in (self.manual_time,self.manual_span,self.manual_offset,self.manual_amplitude,self.manual_high,self.manual_range):
            if not math.isfinite(float(variable.get())):raise ValueError('请输入有限数值')
        max_span=min(self.rx_bandwidth,fs*.8)
        self.time_span=max(1/fs,min(samples_count/fs,float(self.manual_time.get())*1e-6))
        self.view_span=max(fs/65536,min(max_span,float(self.manual_span.get())*1e6))
        self.view_offset=float(np.clip(float(self.manual_offset.get())*1e6,-max_span/2+self.view_span/2,max_span/2-self.view_span/2))
        self.amplitude_limit=max(1,float(self.manual_amplitude.get()))
        self.db_high=float(self.manual_high.get());self.db_low=self.db_high-max(1,float(self.manual_range.get()))
        return int(self.manual_fft.get())

    def update_signal(self,raw,fs,demo=False,context=None):
        try:self._update_signal_impl(raw,fs,demo,context)
        except (ValueError,OverflowError,ZeroDivisionError) as exc:self.sync_status.set('分析参数无效：'+str(exc))

    def _update_signal_impl(self,raw,fs,demo=False,context=None):
        sync_requested=self.carrier_sync.get() or self.symbol_sync.get()
        symbol_rate=self.effective_symbol_rate()[0] if sync_requested else 0.
        if self.raw is not None and (fs!=self.fs or demo!=self.demo or
                                    (not self.paused.get() and context!=self.context)):self.clear()
        rate_changed=fs!=self.fs
        self.raw,self.fs,self.demo=raw,fs,demo
        self.latest_context=context
        if rate_changed:self.update_rate_note()
        if self.paused.get():return
        self.context=context
        count=len(raw)//4
        auto=self.auto_pending
        nfft=1024 if auto else self._manual_view(fs,count)
        key=(self.generation,raw,auto)
        # Spectrum and synchronization run in separate worker processes.
        self.pool.submit('spectrum',key,analysis_workers.spectrum,raw,fs,nfft,auto,
                         min(self.rx_bandwidth,fs*.8),symbol_rate,self.symbol_sync.get())
        if sync_requested:
            self.pool.submit('constellation',(self.generation,raw,self.receive_mode.get()),analysis_workers.constellation,
                             raw,fs,self.receive_mode.get(),symbol_rate,self.carrier_sync.get(),self.symbol_sync.get(),
                             self.carrier_prior() if self.carrier_sync.get() else 0.)
        else:
            self.sync_active=False;self.sync_status.set('同步关闭 · 原始 IQ 点云')
            self.points=iq_array(raw)[-8192:]

    def _deliver(self,job,key,result):
        if key[0]!=self.generation or not self.winfo_exists():return
        if isinstance(result,Exception):
            self.sync_status.set('分析计算失败：'+str(result));return
        if job=='constellation':
            if not (self.carrier_sync.get() or self.symbol_sync.get()):return
            self.points,info=result;self.sync_active=True
            self.sync_status.set(info['text']+' · 仅分析')
            if 'constellation' in self.panels or 'constellation' in self.windows:self._render('constellation')
            return
        raw,auto=key[1],key[2]
        view=result['auto']
        if auto and view:
            self.auto_pending=False
            self.view_span,self.view_offset,self.time_span=view['view_span'],view['view_offset'],view['time_span']
            self.amplitude_limit,self.db_high,self.db_low=view['amplitude_limit'],view['db_high'],view['db_low']
            for variable,value in ((self.manual_time,self.time_span*1e6),(self.manual_span,self.view_span/1e6),
                                   (self.manual_offset,self.view_offset/1e6),(self.manual_fft,len(result['power'])),
                                   (self.manual_amplitude,self.amplitude_limit),(self.manual_high,self.db_high),
                                   (self.manual_range,self.db_high-self.db_low)):
                variable.set(f'{value:.6g}')
            self._applied_manual=self.manual_values()
        self.display_raw=raw;self.power=result['power'];self.iq_db=result['iq_db']
        if self.frames and len(self.frames[-1])!=len(self.power):self.frames.clear();self.history.clear();self.peak=[]
        self.actual_fft=len(self.power)
        self.frames.append(self.power)
        self.average=np.mean(self.frames,axis=0)
        self.peak=np.maximum(self.peak,self.power) if len(self.peak) else self.power.copy()
        self.history.append((time.monotonic(),self.power))
        self.redraw()

    def _render(self,kind):
        panel=self.panels.get(kind) or (self.windows.get(kind) or (None,None))[1]
        if panel is not None and panel.winfo_exists():panel.render()

    def wait_idle(self,timeout=10.):
        """Test/self-test helper: pump Tk until both analysis jobs have delivered."""
        end=time.monotonic()+timeout
        while not self.pool.idle() and time.monotonic()<end:
            self.update();time.sleep(.005)
        self.update()

    def analysis_changed(self,recompute=True):
        self.generation+=1;self.frames.clear();self.history.clear();self.peak=[]
        self.update_rate_note()
        if recompute and self.raw:
            try:self.update_signal(self.raw,self.fs,self.demo,self.latest_context)
            except (ValueError,OverflowError) as exc:self.sync_status.set('参数无效：'+str(exc))

    def resume(self):
        if not self.paused.get() and self.raw:self.update_signal(self.raw,self.fs,self.demo,self.latest_context)

    def redraw(self):
        for panel in list(self.panels.values()):
            if panel.winfo_exists():panel.render()
        for window,panel in list(self.windows.values()):
            if window.winfo_exists():panel.render()

    def rebuild(self):
        if self.layout_changed:self.layout_changed(self.focused is not None)
        for child in self.workspace.winfo_children():child.destroy()
        self.panels={}
        # Grid keeps uniform/minsize settings after children are destroyed. Clear them
        # so the unused overview row/column cannot reserve space in focused mode.
        for row in (0,1):self.workspace.rowconfigure(row,weight=0,uniform='',minsize=0)
        for col in (0,1):self.workspace.columnconfigure(col,weight=0,uniform='',minsize=0)
        if self.focused:
            kind=self.focused
            self.workspace.rowconfigure(0,weight=1);self.workspace.columnconfigure(0,weight=1)
            panel=Panel(self.workspace,kind,self,focused=True)
            panel.grid(row=0,column=0,sticky='nsew');self.panels[kind]=panel
            return
        self.workspace.rowconfigure((0,1),weight=1,uniform='charts')
        self.workspace.columnconfigure(0,weight=1,uniform='charts')
        self.workspace.columnconfigure(1,weight=1,uniform='charts')
        for kind,row,col,span in (('iq',0,0,1),('constellation',1,0,1),('spectrum',0,1,2)):
            if kind in self.windows:
                panel=tk.Frame(self.workspace,bg=PLOT)
                tk.Label(panel,text=TITLES[kind]+'\n已在独立窗口显示',bg=PLOT,fg='#9ab1d0',font=('Microsoft YaHei UI',11)).pack(expand=True)
                ttk.Button(panel,text='收回主窗口',command=lambda k=kind:self.dock(k)).pack(pady=15)
            else:
                panel=Panel(self.workspace,kind,self);self.panels[kind]=panel
            panel.grid(row=row,column=col,rowspan=span,sticky='nsew',padx=(0,7) if col==0 else (0,0),pady=(0,7) if row==0 and span==1 else (0,0))

    def overview(self):
        self.focused=None
        self.rebuild()

    def focus(self,kind):
        if not self.available:return
        if kind in self.windows:
            self.windows[kind][0].lift();return
        self.focused=kind;self.rebuild()

    def popout(self,kind):
        if not self.available:return
        if kind in self.windows:
            self.windows[kind][0].lift();return
        window=tk.Toplevel(self)
        window.title('KU5P · '+TITLES[kind]+' · 与主窗口共用采集数据')
        window.configure(bg=theme.BG);theme.dark_titlebar(window)
        window.geometry('1050x800');window.minsize(650,480)
        window.state('zoomed')
        window.protocol('WM_DELETE_WINDOW',lambda:self.dock(kind))
        panel=Panel(window,kind,self,detached=True);panel.pack(fill='both',expand=True)
        footer=tk.Frame(window,bg=theme.SURFACE);footer.pack(fill='x')
        tk.Label(footer,text='关闭此窗口恢复主布局；暂停显示不停止录制',bg=theme.SURFACE,fg=theme.MUTED).pack(side='left',padx=10)
        ttk.Button(footer,text='■ 紧急停止 · TX1 + TX2 + IQ',style='Emergency.TButton',command=self.emergency).pack(side='right',padx=8,pady=6)
        self.windows[kind]=(window,panel)
        self.focused=None;self.rebuild()

    def dock(self,kind):
        item=self.windows.pop(kind,None)
        if item:item[0].destroy()
        self.rebuild()
