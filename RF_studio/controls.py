"""Read-back driven switch controls: clicking never optimistically changes state."""
import tkinter as tk
import tkinter.font as tkfont

import theme
from theme import SURFACE


class SlideSwitch(tk.Frame):
    def __init__(self,parent,command,**kwargs):
        super().__init__(parent,bg=SURFACE,takefocus=True,highlightthickness=2,
                         highlightbackground=SURFACE,highlightcolor=theme.BLUE,**kwargs)
        self.command=command
        self.value=None
        self.pending=False
        self.control_state='normal'
        self.caption='状态未确认'
        scale=max(1,float(self.tk.call('tk','scaling'))/(96/72))
        self.track_width=round(54*scale)
        self.track_height=round(28*scale)
        self.track=tk.Canvas(self,width=self.track_width,height=self.track_height,
                             bg=SURFACE,highlightthickness=0)
        self.track.pack(side='left',padx=(0,8),pady=3)
        self.label=tk.Label(self,text=self.caption,bg=SURFACE,anchor='w',
                            font=('Microsoft YaHei UI',10,'bold'))
        self.label.pack(side='left')
        for widget in (self,self.track,self.label):
            widget.bind('<Button-1>',self._click)
        self.bind('<space>',self._keyboard)
        self.bind('<Return>',self._keyboard)
        self._paint()

    def _click(self,event):
        self.focus_set()
        self.invoke()

    def _keyboard(self,event):
        self.invoke()
        return 'break'

    def invoke(self):
        if self.control_state!='disabled' and not self.pending:
            return self.command()

    def configure(self,cnf=None,**kwargs):
        if isinstance(cnf,dict):
            kwargs={**cnf,**kwargs}
        if 'state' in kwargs:
            self.control_state=kwargs.pop('state')
        result=super().configure(**kwargs)
        if hasattr(self,'track'):
            self._paint()
        return result

    config=configure

    def cget(self,key):
        if key=='state':
            return self.control_state
        return super().cget(key)

    def display(self,value,text,pending=False):
        self.value=value
        self.caption=text
        self.pending=pending
        self._paint()

    def _paint(self):
        color='#4a72b8' if self.pending else '#13947b' if self.value is True else '#34445e' if self.value is False else '#c9962e'
        foreground='#8fb2f0' if self.pending else theme.OK if self.value is True else theme.MUTED if self.value is False else theme.WARN
        w,h=self.track_width,self.track_height
        self.track.delete('all')
        self.track.create_oval(0,0,h,h,fill=color,outline=color)
        self.track.create_rectangle(h/2,0,w-h/2,h,fill=color,outline=color)
        self.track.create_oval(w-h,0,w,h,fill=color,outline=color)
        left=w-h+3 if self.value is True else 3 if self.value is False else (w-h)/2+3
        self.track.create_oval(left,3,left+h-6,h-3,fill='#e9eef6',outline='#e9eef6')
        self.label.configure(text=self.caption,fg=foreground)
        cursor='hand2' if self.control_state!='disabled' and not self.pending else 'arrow'
        for widget in (self,self.track,self.label):
            widget.configure(cursor=cursor) if widget is not self else super().configure(cursor=cursor)


class UploadButton(tk.Canvas):
    """Rectangular upload button. Colour shows the upload state, not a click echo."""
    COLORS=dict(synced=('#5b7fa6','#ffffff'),dirty=('#e8892b','#ffffff'),
                busy=('#4f5f78','#d5deea'),failed=('#c4263d','#ffffff'),
                disabled=('#26344c','#5f6f88'))
    def __init__(self,parent,command,text='upload',bg=theme.BG,height=36,font=('Segoe UI',11,'bold')):
        self.font=font;self.text=text
        width=tkfont.Font(font=font).measure(text)+2*round(height*.9)
        self.box=(width,height)
        super().__init__(parent,width=width,height=height,bg=bg,highlightthickness=0,takefocus=True)
        self.command=command;self.kind='disabled';self.control_state='disabled'
        self.bind('<Button-1>',lambda e:self.invoke())
        self.bind('<space>',lambda e:(self.invoke(),'break')[1])
        self.bind('<Return>',lambda e:(self.invoke(),'break')[1])
        self._paint()

    def invoke(self):
        if self.control_state!='disabled' and self.kind!='busy':
            return self.command()

    def configure(self,cnf=None,**kwargs):
        if isinstance(cnf,dict):kwargs={**cnf,**kwargs}
        if 'state' in kwargs:self.control_state=kwargs.pop('state')
        result=super().configure(**kwargs) if kwargs else None
        if hasattr(self,'kind'):self._paint()
        return result

    config=configure

    def cget(self,key):
        if key=='state':return self.control_state
        return super().cget(key)

    def display(self,kind):
        self.kind=kind;self._paint()

    def _paint(self):
        kind=self.kind if self.kind=='busy' or self.control_state!='disabled' else 'disabled'
        fill,fg=self.COLORS[kind]
        w,h=self.box
        self.delete('all')
        self.create_rectangle(0,0,w,h,fill=fill,outline=fill)
        self.create_text(w/2,h/2,text='上传中…' if kind=='busy' else self.text,fill=fg,font=self.font)
        super().configure(cursor='hand2' if kind not in ('disabled','busy') else 'arrow')
