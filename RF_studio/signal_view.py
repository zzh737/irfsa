"""IQ and NumPy FFT preview drawn with Tk."""
import tkinter as tk
import numpy as np


def spectrum(raw, size=512):
    from dsp_analysis import iq_array,amplitude_db
    return amplitude_db(iq_array(raw),size)


def envelope_points(xs, ys, left, right):
    """Flat Tk polyline for x-sorted data, at most a min/max pair per pixel column."""
    xs=np.asarray(xs,dtype=float);ys=np.asarray(ys,dtype=float)
    columns=max(2,int(right-left))
    if len(xs)>2*columns:
        bins=np.clip(((xs-left)/max(1e-9,right-left)*columns).astype(int),0,columns-1)
        starts=np.flatnonzero(np.r_[True,bins[1:]!=bins[:-1]])
        top=np.minimum.reduceat(ys,starts);bottom=np.maximum.reduceat(ys,starts)
        xs=np.repeat(left+(bins[starts]+.5)*(right-left)/columns,2)
        ys=np.column_stack((top,bottom)).ravel()
    return np.column_stack((xs,ys)).ravel().tolist()


class SignalView(tk.Canvas):
    def __init__(self, parent, **kwargs):
        super().__init__(parent, bg='#0c1729', highlightthickness=0, **kwargs)
        self.raw = None
        self.fs = 1_000_000
        self.db = []
        self.demo = False
        self.time_span=256/self.fs;self.amplitude_limit=2048;self.fft_size=512;self.span=self.fs;self.offset=0
        self.bind('<Configure>', lambda _: self.draw())

    def update_signal(self, raw, fs, demo=False, db=None):
        """db: optional precomputed amplitude spectrum (worker process)."""
        self.raw, self.fs, self.demo = raw, fs, demo
        self.db = spectrum(raw,self.fft_size) if db is None else db
        self.draw()

    def clear(self):
        self.raw = None
        self.db = []
        self.draw()

    def draw(self):
        self.delete('all')
        w, h = self.winfo_width(), self.winfo_height()
        if w < 100 or h < 100:
            return
        left, right = 56, w-24
        top, middle, bottom = 38, int(h*.48), h-32
        self.create_text(18, 17, text='I/Q 波形 · ADC 码值', fill='#c5d4e9', anchor='w', font=('Microsoft YaHei UI', 10))
        self.create_text(18, middle+18, text='复数 FFT · 相对满量程幅度 / dBFS', fill='#c5d4e9', anchor='w', font=('Microsoft YaHei UI', 10))
        a, b = top, middle-20
        c, d = middle+42, bottom
        for y0, y1 in ((a,b), (c,d)):
            for n in range(5):
                y = y0+(y1-y0)*n/4
                self.create_line(left, y, right, y, fill='#213047')
            for n in range(9):
                x = left+(right-left)*n/8
                self.create_line(x, y0, x, y1, fill='#1a2940')
        for value, y in ((self.amplitude_limit,a), (0,(a+b)/2), (-self.amplitude_limit,b)):
            self.create_text(left-8,y,text=str(value),anchor='e',fill='#788da8',font=('Consolas',8))
        for value, y in ((0,c),(-50,(c+d)/2),(-100,d)):
            self.create_text(left-8,y,text=str(value),anchor='e',fill='#788da8',font=('Consolas',8))
        frequency_scale=1e6 if self.span>=1e6 else 1e3 if self.span>=1e3 else 1
        unit='MHz' if frequency_scale==1e6 else 'kHz' if frequency_scale==1e3 else 'Hz'
        for text, x in ((f'{(self.offset-self.span/2)/frequency_scale:g}',left), (f'{self.offset/frequency_scale:g} {unit}',(left+right)/2), (f'{(self.offset+self.span/2)/frequency_scale:g}',right)):
            self.create_text(x,d+15,text=text,fill='#788da8',font=('Consolas',9))
        if not self.raw:
            self.create_text((left+right)/2,(a+b)/2,text='开启接收观测或录制后显示有效 IQ',fill='#788da8',font=('Microsoft YaHei UI',11))
            self.create_text((left+right)/2,(c+d)/2,text='频谱仅用于预览，不是功率 / SNR 标定结果',fill='#788da8',font=('Microsoft YaHei UI',10))
            return
        codes=np.frombuffer(self.raw,dtype='<i2').reshape(-1,2)
        count=max(2,min(len(codes),round(self.time_span*self.fs)))
        scale=1e6 if self.time_span<.001 else 1e3 if self.time_span<1 else 1
        label='μs' if scale==1e6 else 'ms' if scale==1e3 else 's'
        self.create_text(right,middle-5,text=f'时间窗 {count/self.fs*scale:g} {label}',anchor='e',fill='#91a5bf',font=('Consolas',8))
        shown=min(count,1200)
        index=np.rint(np.arange(shown)*(count-1)/(shown-1)).astype(int)
        xs=left+(right-left)*np.arange(shown)/(shown-1)
        for channel,color in ((0,'#4be3ca'),(1,'#8eacff')):
            ys=(a+b)/2-np.clip(codes[index,channel]/self.amplitude_limit,-1,1)*(b-a)/2
            self.create_line(np.column_stack((xs,ys)).ravel().tolist(),fill=color,width=1.25)
        db=np.asarray(self.db,dtype=float);n=len(db)
        if n:
            freq=(np.arange(n)-n//2)*self.fs/n
            keep=(freq>=self.offset-self.span/2)&(freq<=self.offset+self.span/2)
            coords=envelope_points(left+(right-left)*(freq[keep]-self.offset+self.span/2)/self.span,
                                   c+np.clip(-db[keep],0,100)/100*(d-c),left,right)
            if len(coords)>=4:self.create_line(coords,fill='#53c9f4',width=1.4)
        self.create_text(right,17,text='演示合成数据' if self.demo else '最近有效窗口 · I 绿 / Q 蓝',anchor='e',fill='#f5b849' if self.demo else '#91a5bf',font=('Microsoft YaHei UI',9))
