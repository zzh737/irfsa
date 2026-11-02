"""Background analysis processes for the GUI. No hardware access.

Spectrum and constellation jobs run in separate worker processes, so large
FFTs and Gardner/DD loops use other CPU cores instead of the Tk thread.  Only
the newest pending block is kept per job: if a worker is busy, a newer IQ
block replaces the queued one rather than building a backlog.
"""
from __future__ import annotations

import multiprocessing
import os
import queue
from concurrent.futures import ProcessPoolExecutor

import dsp_analysis

JOBS=('spectrum','constellation')
POLL_MS=15


def _worker_count():
    return 2 if (os.cpu_count() or 1)>=3 else 0


class AnalysisPool:
    def __init__(self,widget,deliver):
        """deliver(job,generation,result_or_exception) runs on the Tk thread."""
        # Timers live on the root window so a global after-cancel and the
        # widget's own destroy never both try to delete the same Tcl command.
        self.widget,self.deliver=widget._root(),deliver
        self.busy=dict.fromkeys(JOBS,False);self.queued=dict.fromkeys(JOBS)
        self.executor=None;self.closed=False;self.results=queue.SimpleQueue();self.timer=None
        if _worker_count():
            try:
                # spawn is the Windows default; freeze_support in app.main covers EXE builds.
                self.executor=ProcessPoolExecutor(_worker_count(),mp_context=multiprocessing.get_context('spawn'))
            except (OSError,ValueError):
                self.executor=None
        if self.executor:self._poll()

    @property
    def parallel(self):
        return self.executor is not None

    def submit(self,job,generation,function,*args):
        if self.closed:return
        if self.executor is None:
            # Single-core fallback keeps the old synchronous behaviour.
            try:result=function(*args)
            except Exception as exc:result=exc
            self.deliver(job,generation,result);return
        if self.busy[job]:
            self.queued[job]=(generation,function,args);return
        self._launch(job,generation,function,args)

    def _launch(self,job,generation,function,args):
        self.busy[job]=True
        try:future=self.executor.submit(function,*args)
        except RuntimeError:
            self.busy[job]=False;return
        future.add_done_callback(lambda f:self._done(job,generation,f))

    def _done(self,job,generation,future):
        # Runs on an executor thread: Tk calls are not thread-safe here, so only
        # enqueue. The Tk thread drains the queue in _poll.
        try:result=future.result()
        except Exception as exc:result=exc
        self.results.put((job,generation,result))

    def _poll(self):
        if self.closed:return
        try:
            while True:self._finish(*self.results.get_nowait())
        except queue.Empty:pass
        try:self.timer=self.widget.after(POLL_MS,self._poll)
        except Exception:self.timer=None

    def _finish(self,job,generation,result):
        self.busy[job]=False
        if self.closed:return
        pending,self.queued[job]=self.queued[job],None
        if pending:self._launch(job,*pending)
        self.deliver(job,generation,result)

    def idle(self):
        return not any(self.busy.values()) and not any(self.queued.values())

    def close(self):
        self.closed=True
        if self.timer:
            try:self.widget.after_cancel(self.timer)
            except Exception:pass
            self.timer=None
        if self.executor:
            self.executor.shutdown(wait=False,cancel_futures=True);self.executor=None


def spectrum(*args):
    return dsp_analysis.analyze_spectrum(*args)


def constellation(*args):
    return dsp_analysis.analyze_constellation(*args)
