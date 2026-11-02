"""'模型测试' tab: load an exported IQ model, classify live RX1 IQ, evaluate recordings.

Inference runs in one dedicated worker process (ONNX session cached there), so
the Tk thread, the receiver and the spectrum/constellation workers are not
blocked. Live results are scored against the board's TX1 configuration
readback; that is a configuration label, not an independent truth. No
hardware commands are issued from this tab.
"""
from __future__ import annotations

import json
import multiprocessing
import queue
import threading
import tkinter as tk
from concurrent.futures import ProcessPoolExecutor
from datetime import datetime
from pathlib import Path
from tkinter import filedialog, ttk

import model_eval
import theme

POLL_MS=40
LIVE_INTERVAL=.25


class ModelTester:
    """Owns the worker process and the tab widgets; app.py only forwards IQ and TX readback."""

    def __init__(self,app,parent,base):
        self.app,self.base=app,Path(base)
        self.model_path=None;self.stamp=None;self.info=None
        self.executor=None;self.busy=False;self.pending=None;self.closed=False
        self.results=queue.SimpleQueue();self.label=None;self.last_submit=0.
        self.history=[];self.offline_thread=None
        self.live=tk.BooleanVar(value=False);self.frames=tk.StringVar(value='4')
        self.model_dir=self.base/'model'
        self.path_var=tk.StringVar(value='');self.dir_var=tk.StringVar(value=str(self.base/'captures'/'training'))
        self._build(parent)
        self.timer=app.after(POLL_MS,self._poll)

    # ---------------------------------------------------------------- layout
    def _build(self,parent):
        ttk.Label(parent,text='模型测试',style='Title.TLabel').pack(anchor='w')
        ttk.Label(parent,text='加载 V2 导出的 ONNX 模型（python -m v2 export 生成 .onnx + .model.json），'
                  '对 RX1 实时 IQ 或已录制的训练数据做分类。\n'
                  '输入约定：1 MSPS，窗长按所选模型，逐窗 RMS 归一化、不去均值；输出 logits，多帧取平均。\n'
                  '实时判对错以板端 TX1 配置读回为标签，不是独立真值；不发任何硬件命令。',
                  style='Hint.TLabel',wraplength=480,justify='left').pack(anchor='w',pady=(8,12))
        ttk.Label(parent,text=f'模型目录 {self.model_dir}（放入 .onnx + 同名 .model.json）',style='Hint.TLabel',
                  wraplength=480,justify='left').pack(anchor='w',pady=(0,4))
        row=ttk.Frame(parent,style='White.TFrame');row.pack(fill='x')
        self.model_box=ttk.Combobox(row,textvariable=self.path_var,state='readonly')
        self.model_box.pack(side='left',fill='x',expand=True)
        self.model_box.bind('<<ComboboxSelected>>',lambda _:self.load(self.model_dir/self.path_var.get()))
        ttk.Button(row,text='其他位置…',command=self.browse_model).pack(side='right',padx=(8,0))
        ttk.Button(row,text='刷新',command=self.scan_models).pack(side='right',padx=(8,0))
        self.model_label=ttk.Label(parent,text='未加载模型',style='White.TLabel',wraplength=480,justify='left')
        self.model_label.pack(anchor='w',pady=(8,12))

        ttk.Separator(parent).pack(fill='x',pady=(0,12))
        ttk.Label(parent,text='实时识别（RX1 同窗观测的 IQ）',style='Title.TLabel').pack(anchor='w')
        live=ttk.Frame(parent,style='White.TFrame');live.pack(fill='x',pady=(8,4))
        self.live_check=ttk.Checkbutton(live,text='开启实时识别',variable=self.live,command=self.live_changed)
        self.live_check.pack(side='left')
        ttk.Label(live,text='融合帧数',style='Hint.TLabel').pack(side='left',padx=(18,4))
        ttk.Combobox(live,textvariable=self.frames,values=['1','2','4','8','16'],width=5,state='readonly').pack(side='left')
        self.live_label=ttk.Label(parent,text='开启“RX1 同窗观测”后显示结果',style='White.TLabel',
                                  wraplength=480,justify='left',font=('Microsoft YaHei UI',11,'bold'))
        self.live_label.pack(anchor='w',pady=(8,4))
        self.bars=tk.Canvas(parent,height=150,bg=theme.SURFACE,highlightthickness=0)
        self.bars.pack(fill='x',pady=(0,4))
        self.live_detail=ttk.Label(parent,text='',style='Hint.TLabel',wraplength=480,justify='left')
        self.live_detail.pack(anchor='w')

        ttk.Separator(parent).pack(fill='x',pady=12)
        ttk.Label(parent,text='离线评估（训练采集目录）',style='Title.TLabel').pack(anchor='w')
        row=ttk.Frame(parent,style='White.TFrame');row.pack(fill='x',pady=(8,0))
        ttk.Entry(row,textvariable=self.dir_var).pack(side='left',fill='x',expand=True)
        ttk.Button(row,text='浏览',command=self.browse_dir).pack(side='right',padx=(8,0))
        actions=ttk.Frame(parent,style='White.TFrame');actions.pack(fill='x',pady=(8,0))
        self.eval_btn=ttk.Button(actions,text='开始评估',style='Primary.TButton',command=self.start_offline)
        self.eval_btn.pack(side='left')
        self.report_btn=ttk.Button(actions,text='打开报告目录',command=self.open_reports)
        self.report_btn.pack(side='right')
        self.offline_progress=ttk.Progressbar(parent,maximum=100);self.offline_progress.pack(fill='x',pady=(10,6))
        self.offline_label=ttk.Label(parent,text='按每份录制的 JSON 标签评估；过滤规则与 V2 训练一致，连续 1/2/4/8 帧融合。',
                                     style='Hint.TLabel',wraplength=480,justify='left')
        self.offline_label.pack(anchor='w')
        self._refresh()
        # After the whole window (incl. the log tab) exists: load() writes to the log.
        self.app.after_idle(lambda:self.scan_models(load_first=True))

    def scan_models(self,load_first=False):
        """List models in operate/model; optionally load the first one (live stays off)."""
        try:names=sorted(p.name for p in self.model_dir.glob('*.onnx') if p.with_suffix('.model.json').exists())
        except OSError:names=[]
        self.model_box.configure(values=names)
        if not names:
            if self.info is None:self.model_label.configure(text='模型目录中没有可用模型')
            return
        if load_first and self.info is None:
            self.path_var.set(names[0]);self.load(self.model_dir/names[0])

    def _refresh(self):
        loaded=self.info is not None
        state='normal' if loaded else 'disabled'
        self.live_check.configure(state=state)
        self.eval_btn.configure(state='disabled' if not loaded or self.offline_thread else 'normal')

    # ---------------------------------------------------------------- model
    def browse_model(self):
        start=Path(self.model_path).parent if self.model_path else self.model_dir
        path=filedialog.askopenfilename(parent=self.app,title='选择 ONNX 模型',initialdir=str(start),
                                        filetypes=[('ONNX 模型','*.onnx'),('模型说明','*.model.json')])
        if path:self.load(path)

    def load(self,path):
        """Validate in this process (fast), then hand the path to the worker."""
        path=str(Path(path).with_suffix('.onnx'))
        try:info=model_eval.IQModel(path).describe()
        except model_eval.ModelError as exc:
            self.info=None;self.model_label.configure(text='加载失败：'+str(exc),foreground=theme.ERROR)
            self._refresh();return False
        self.model_path,self.info=path,info
        self.stamp=Path(path).stat().st_mtime_ns
        p=Path(path)
        self.path_var.set(p.name if p.parent.resolve()==self.model_dir.resolve() else str(p));self.history.clear()
        warn='\n注意：模型标记为 fixture（合成数据训练），结果不代表实采性能。' if info['fixture_only'] else ''
        self.model_label.configure(foreground=theme.TEXT,
            text=f"{info['name']} · {info['architecture']} · {len(info['classes'])} 类 · {info['fs_hz']/1e6:g} MSPS × {info['window_points']} 点"
                 f"\nSHA-256 {str(info['onnx_sha256'])[:12]}…{warn}")
        self.app.log(f"模型测试：已加载 {Path(path).name}（{len(info['classes'])} 类）")
        self._refresh();return True

    def _ensure_executor(self):
        if self.executor is None:
            # spawn matches analysis_workers; freeze_support in app.main covers the EXE.
            self.executor=ProcessPoolExecutor(1,mp_context=multiprocessing.get_context('spawn'))
        return self.executor

    # ---------------------------------------------------------------- live
    def set_tx(self,tx):
        self.label=(tx or {}).get('modulation') if tx and (tx.get('applied_mask',0)&1) else None

    def live_changed(self):
        self.history.clear()
        if not self.live.get():self.live_label.configure(text='实时识别已关闭');self.bars.delete('all')

    def feed(self,raw,fs):
        """Called with every rendered preview block; drops blocks while the worker is busy."""
        if self.closed or not self.live.get() or self.info is None or not raw:return
        now=datetime.now().timestamp()
        if now-self.last_submit<LIVE_INTERVAL:return
        self.last_submit=now
        args=(self.model_path,self.stamp,bytes(raw),fs,int(self.frames.get()),self.label)
        if self.busy:self.pending=args;return
        self._launch(args)

    def _launch(self,args):
        try:future=self._ensure_executor().submit(model_eval.live_job,*args)
        except RuntimeError:return
        self.busy=True
        future.add_done_callback(lambda f:self.results.put(('live',f)))

    def _poll(self):
        if self.closed:return
        try:
            while True:
                kind,payload=self.results.get_nowait()
                if kind=='live':self._live_done(payload)
                elif kind=='offline_progress':self._offline_progress(*payload)
                elif kind=='offline_done':self._offline_done(payload)
        except queue.Empty:pass
        try:self.timer=self.app.after(POLL_MS,self._poll)
        except Exception:self.timer=None

    def _live_done(self,future):
        self.busy=False
        if self.pending and self.live.get():
            args,self.pending=self.pending,None;self._launch(args)
        try:result=future.result()
        except Exception as exc:result=dict(error=str(exc))
        self.show_live(result)

    def show_live(self,r):
        if not self.live.get():return
        if r.get('error'):
            self.live_label.configure(text='无法识别：'+r['error'],foreground=theme.WARN);self.bars.delete('all');return
        if 'correct' in r:self.history.append(bool(r['correct']));self.history=self.history[-200:]
        label=r.get('label')
        verdict=('  ✓ 与 TX1 配置一致' if r.get('correct') else '  ✗ TX1 配置为 '+label) if 'correct' in r else (
            f'  · TX1 配置 {label} 不在模型类别中' if label else '  · TX1 未开启或未读回，不判对错')
        self.live_label.configure(text=f"识别：{r['predicted']}  {r['confidence']*100:.1f}%{verdict}",
                                  foreground=theme.OK if r.get('correct') else (theme.ERROR if 'correct' in r else theme.TEXT))
        self._draw_bars(r['top'],label)
        rate=f" · 最近 {len(self.history)} 次融合判决正确率 {sum(self.history)/len(self.history)*100:.1f}%" if self.history else ''
        single=f" · 本块单窗正确率 {r['single_window_accuracy']*100:.0f}%" if 'single_window_accuracy' in r else ''
        self.live_detail.configure(text=f"本块 {r['windows']} 窗，融合最新 {r['fused_frames']} 窗{single}{rate}\n"
                                        f"单窗判决（新→右）：{' '.join(r['single_predictions'][-8:])}")

    def _draw_bars(self,top,label):
        c=self.bars;c.delete('all');w=max(c.winfo_width(),300);row=28
        for i,(name,p) in enumerate(top):
            y=6+i*row
            c.create_text(4,y+10,text=name,anchor='w',font=('Microsoft YaHei UI',9),fill=theme.TEXT)
            x0,x1=110,w-60
            c.create_rectangle(x0,y+3,x1,y+17,fill=theme.RAISED,width=0)
            c.create_rectangle(x0,y+3,x0+(x1-x0)*p,y+17,fill=theme.OK if name==label else theme.BLUE,width=0)
            c.create_text(w-4,y+10,text=f'{p*100:.1f}%',anchor='e',font=('Consolas',9),fill=theme.TEXT)

    # ---------------------------------------------------------------- offline
    def browse_dir(self):
        path=filedialog.askdirectory(parent=self.app,initialdir=self.dir_var.get(),title='选择训练采集目录')
        if path:self.dir_var.set(path)

    def start_offline(self):
        if self.info is None or self.offline_thread:return
        directory=self.dir_var.get().strip()
        out=self.base/'reports'/'model_tests';path=self.model_path
        def run():
            try:
                report=model_eval.evaluate_directory(path,directory,
                    progress=lambda n,total,name:self.results.put(('offline_progress',(n,total,name))))
                out.mkdir(parents=True,exist_ok=True)
                target=out/f"{Path(path).stem}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
                target.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
                report['saved_to']=str(target)
                self.results.put(('offline_done',report))
            except Exception as exc:
                self.results.put(('offline_done',dict(error=str(exc))))
        # Offline runs on a background thread in this process: onnxruntime
        # releases the GIL during inference, and file reading is I/O bound.
        self.offline_thread=threading.Thread(target=run,daemon=True,name='model-offline-eval')
        self.offline_thread.start();self.offline_progress['value']=0
        self.offline_label.configure(text='评估中…',foreground=theme.TEXT);self._refresh()

    def _offline_progress(self,n,total,name):
        self.offline_progress['value']=100*n/max(total,1)
        if name:self.offline_label.configure(text=f'评估中 {n+1}/{total} · {name}')

    def _offline_done(self,report):
        self.offline_thread=None;self._refresh()
        if report.get('error'):
            self.offline_label.configure(text='评估失败：'+report['error'],foreground=theme.ERROR);return
        self.offline_progress['value']=100
        parts=[f"{k} 帧 {v['accuracy']*100:.1f}%（{v['groups']} 组）" for k,v in report['summary'].items() if v['accuracy'] is not None]
        worst=sorted((f for f in report['files'] if f.get('accuracy_1') is not None),key=lambda f:f['accuracy_1'])[:3]
        low='\n最低：'+'；'.join(f"{f['label']} {f['accuracy_1']*100:.0f}%" for f in worst) if worst else ''
        skipped=f"\n跳过 {len(report['skipped'])} 份（采样率或标签不匹配、CRC 错误等，见报告）" if report['skipped'] else ''
        self.offline_label.configure(foreground=theme.TEXT,
            text=f"{len(report['files'])} 份录制 · "+' · '.join(parts)+low+skipped+f"\n报告：{report['saved_to']}")
        self.app.log(f"模型测试：离线评估完成，{len(report['files'])} 份录制，报告 {Path(report['saved_to']).name}")

    def open_reports(self):
        import os
        folder=self.base/'reports'/'model_tests';folder.mkdir(parents=True,exist_ok=True)
        try:os.startfile(folder)
        except OSError:pass

    def close(self):
        self.closed=True
        if self.timer:
            try:self.app.after_cancel(self.timer)
            except Exception:pass
        if self.executor:self.executor.shutdown(wait=False,cancel_futures=True);self.executor=None
