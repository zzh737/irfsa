"""Bottom-left console: levelled log view plus a command line.

Lines read  "HH:MM:SS [level] text". info is neutral, warning yellow, critical orange-red, error red.
Commands are parsed by command_interface.CommandInterface; the same parser
serves the optional local TCP control port, so a bench script and a human
typing here drive the GUI through exactly the same code path.
"""
from __future__ import annotations

import time
import tkinter as tk
import tkinter.font as tkfont
from datetime import datetime
from tkinter import ttk

# critical (orange-red): the action proceeds but its result will not match the plan.
LEVELS = {'info': '#c9d4e3', 'ok': '#7fd3b3', 'warning': '#f5c451', 'critical': '#ff8a3d', 'error': '#ff6b7d',
          'cmd': '#8fb8ff'}
MAX_LINES = 2000
# "HH:MM:SS [critical] ": every label is padded to the widest one, so all
# messages start in the same column. The prefix is ASCII, so a monospaced
# font keeps it aligned even though CJK message text falls back to another font.
LABEL_WIDTH = len('[critical]') + 1
FONT = ('Consolas', 9)
# Lines more than this far apart belong to different operations; a blank line separates them.
GROUP_GAP_S = 2.0


def prefix(stamp, level):
    label = '[cmd]' if level == 'cmd' else f'[{level}]'
    return f'{stamp} {label:<{LABEL_WIDTH}}'


class Console(ttk.Frame):
    def __init__(self, parent, execute, height=9):
        super().__init__(parent, style='White.TFrame')
        self.execute = execute
        self.history = []
        self.cursor = 0
        head = tk.Frame(self, bg='#13233b')
        head.pack(fill='x')
        tk.Label(head, text='控制台', bg='#13233b', fg='#e8eef7', font=('Microsoft YaHei UI', 9, 'bold')).pack(side='left', padx=(10, 6), pady=4)
        self.badge = tk.Label(head, text='', bg='#13233b', fg=LEVELS['warning'], font=('Microsoft YaHei UI', 9))
        self.badge.pack(side='left')
        tk.Button(head, text='清空', command=self.clear, bg='#13233b', fg='#a9c0df', activebackground='#1d3354',
                  activeforeground='white', relief='flat', bd=0, font=('Microsoft YaHei UI', 9), cursor='hand2').pack(side='right', padx=8)
        body = tk.Frame(self, bg='#0f1b2d')
        body.pack(fill='both', expand=True)
        bar = ttk.Scrollbar(body, orient='vertical')
        bar.pack(side='right', fill='y')
        self.font = tkfont.Font(font=FONT)
        self.text = tk.Text(body, height=height, bg='#0f1b2d', fg=LEVELS['info'], insertbackground='white',
                            relief='flat', font=self.font, wrap='word', padx=8, pady=6, yscrollcommand=bar.set)
        self.text.pack(side='left', fill='both', expand=True)
        bar.configure(command=self.text.yview)
        for level, color in LEVELS.items():
            self.text.tag_configure(level, foreground=color)
        self.text.tag_configure('stamp', foreground='#6f819b')
        # Hanging indent: wrapped continuation lines start under the message, not at column 0.
        self.text.tag_configure('entry', lmargin1=0, lmargin2=self.font.measure(prefix('00:00:00', 'critical')))
        self.text.configure(state='disabled')
        entry_row = tk.Frame(self, bg='#0b1524')
        entry_row.pack(fill='x')
        tk.Label(entry_row, text='>', bg='#0b1524', fg=LEVELS['cmd'], font=('Consolas', 10, 'bold')).pack(side='left', padx=(8, 4))
        self.entry = tk.Entry(entry_row, bg='#0b1524', fg='#e8eef7', insertbackground='white', relief='flat',
                              font=('Consolas', 10))
        self.entry.pack(side='left', fill='x', expand=True, ipady=4)
        self.entry.bind('<Return>', self._submit)
        self.entry.bind('<Up>', lambda e: self._recall(-1))
        self.entry.bind('<Down>', lambda e: self._recall(1))
        self.entry.insert(0, '')
        self.placeholder = '输入 help 查看指令'
        self._show_placeholder()
        self.entry.bind('<FocusIn>', self._clear_placeholder)
        self.entry.bind('<FocusOut>', lambda e: self._show_placeholder())
        self.warnings = 0
        self.last_write = None
        self.gap = False   # True if the latest write() started a new group

    def _show_placeholder(self):
        if not self.entry.get():
            self.entry.insert(0, self.placeholder)
            self.entry.configure(fg='#5d6f88')

    def _clear_placeholder(self, event=None):
        if self.entry.get() == self.placeholder:
            self.entry.delete(0, 'end')
        self.entry.configure(fg='#e8eef7')

    def write(self, level, text):
        level = level if level in LEVELS else 'info'
        stamp = datetime.now().strftime('%H:%M:%S')
        head = prefix(stamp, level)
        body = ('entry', level) if level in ('warning', 'critical', 'error', 'cmd') else ('entry',)
        now = time.monotonic()
        gap = self.last_write is not None and now - self.last_write > GROUP_GAP_S
        self.last_write = now
        self.gap = gap
        self.text.configure(state='normal')
        if gap:
            self.text.insert('end', '\n')
        self.text.insert('end', stamp + ' ', ('entry', 'stamp'))
        self.text.insert('end', head[len(stamp) + 1:], ('entry', level))
        self.text.insert('end', text + '\n', body)
        lines = int(self.text.index('end-1c').split('.')[0])
        if lines > MAX_LINES:
            self.text.delete('1.0', f'{lines - MAX_LINES}.0')
        self.text.see('end')
        self.text.configure(state='disabled')
        return head + text

    def set_badge(self, text, level='warning'):
        self.badge.configure(text=text, fg=LEVELS.get(level, LEVELS['warning']))

    def clear(self):
        self.text.configure(state='normal')
        self.text.delete('1.0', 'end')
        self.text.configure(state='disabled')
        self.last_write = None

    def _recall(self, step):
        if not self.history:
            return 'break'
        self.cursor = max(0, min(len(self.history), self.cursor + step))
        self._clear_placeholder()
        self.entry.delete(0, 'end')
        if self.cursor < len(self.history):
            self.entry.insert(0, self.history[self.cursor])
        return 'break'

    def _submit(self, event=None):
        line = self.entry.get().strip()
        if not line or line == self.placeholder:
            return 'break'
        self.history.append(line)
        self.cursor = len(self.history)
        self.entry.delete(0, 'end')
        self.write('cmd', line)
        for level, text in self.execute(line):
            self.write(level, text)
        return 'break'
