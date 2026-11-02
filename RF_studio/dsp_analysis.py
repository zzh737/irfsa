"""Host-only IQ analysis. Never modifies recording buffers or hardware settings.

analyze_spectrum/analyze_constellation are pure module-level functions so the
GUI can run them in worker processes; they only receive copies of the IQ bytes.
"""
import cmath
import functools
import math
import numpy as np

FFT_SIZES=(256,512,1024,2048,4096,8192,16384,32768,65536)
DAC_RATE=25_000_000
LINEAR_FAMILIES=('ASK','PSK','QAM')

def iq_array(raw):
    a=np.frombuffer(raw,dtype='<i2').astype(float).reshape(-1,2)
    return a[:,0]+1j*a[:,1]

def periodogram(samples,fs,nfft):
    n=min(nfft,1<<int(math.log2(max(2,len(samples)))))
    x=samples[-n:];w=np.hanning(n)
    return np.fft.fftshift(abs(np.fft.fft(x*w))**2)/(fs*np.sum(w*w)*2048**2)

def amplitude_db(samples,nfft):
    """Hann FFT magnitude in dBFS (full scale 2048), clipped at -100 dB, DC centred."""
    n=min(nfft,1<<int(math.log2(max(2,len(samples)))))
    w=np.hanning(n)
    db=20*np.log10(np.maximum(abs(np.fft.fft(samples[-n:]*w))/(np.sum(w)*2048),1e-5))
    return np.fft.fftshift(np.maximum(-100,db))

@functools.lru_cache(maxsize=8)
def _rrc_taps(sps,alpha,span):
    half=min(32768,max(8,int(span*sps/2)))
    t=np.arange(-half,half+1)/sps
    singular=abs(abs(t)-1/(4*alpha))<1e-8
    centre=abs(t)<1e-10
    with np.errstate(divide='ignore',invalid='ignore'):
        h=(np.sin(np.pi*t*(1-alpha))+4*alpha*t*np.cos(np.pi*t*(1+alpha)))/(np.pi*t*(1-(4*alpha*t)**2))
    h[singular]=alpha/np.sqrt(2)*((1+2/np.pi)*np.sin(np.pi/(4*alpha))+(1-2/np.pi)*np.cos(np.pi/(4*alpha)))
    h[centre]=1+alpha*(4/np.pi-1)
    h=h/np.sqrt(np.sum(h*h))
    h.setflags(write=False)
    return h

def rrc(sps,alpha=.35,span=10):
    return _rrc_taps(float(sps),float(alpha),float(span))

def convolve_same(x,h):
    n=1<<(len(x)+len(h)-2).bit_length()
    y=np.fft.ifft(np.fft.fft(x,n)*np.fft.fft(h,n))[:len(x)+len(h)-1]
    return y[(len(h)-1)//2:(len(h)-1)//2+len(x)]

def scalar_decision(mode):
    """Return a per-symbol Python version of decision(); identical rounding."""
    order=int(mode[:-3])
    if mode.endswith('PSK'):
        k=order/(2*math.pi);step=2*math.pi/order
        return lambda v:cmath.exp(1j*step*round(cmath.phase(v)*k))
    if mode.endswith('ASK'):
        scale=math.sqrt((order-1)*(2*order-1)/6)
        return lambda v:complex(min(max(round(v.real*scale),0),order-1)/scale,0)
    side=int(math.sqrt(order));scale=math.sqrt(2*(order-1)/3)
    quant=lambda x:2*min(max(round((x*scale+side-1)/2),0),side-1)-(side-1)
    return lambda v:complex(quant(v.real),quant(v.imag))/scale

def decision(z,mode):
    order=int(mode[:-3])
    if mode.endswith('PSK'):
        return np.exp(2j*np.pi*np.round(np.angle(z)*order/(2*np.pi))/order)
    if mode.endswith('ASK'):
        scale=np.sqrt((order-1)*(2*order-1)/6)
        return np.clip(np.round(z.real*scale),0,order-1)/scale+0j
    side=int(np.sqrt(order));scale=np.sqrt(2*(order-1)/3)
    quant=lambda v:2*np.clip(np.round((v*scale+side-1)/2),0,side-1)-(side-1)
    return (quant(z.real)+1j*quant(z.imag))/scale

def tx_symbol_plan(tx):
    """Board-readback TX modulation and symbol rate from RFCT 0x102 registers.

    registers[2] is the RTL symbol NCO step at 25 MSPS (waveform_config.step(rs)).
    Returns None unless TX1 carries a configured linear (ASK/PSK/QAM) modulation.
    """
    if not tx or tx.get('available') is False:return None
    mode=tx.get('modulation') or ''
    regs=tx.get('registers') or ()
    if not mode.endswith(LINEAR_FAMILIES) or len(regs)<3 or not regs[2]:return None
    # Linear families only (never SSB), so register 6 is the band centre.
    offset=regs[6]-(1<<32) if len(regs)>6 and regs[6]>=1<<31 else (regs[6] if len(regs)>6 else 0)
    return dict(modulation=mode,symbol_rate_hz=regs[2]*DAC_RATE/2**32,
                offset_hz=offset*DAC_RATE/2**32,center_hz=tx.get('center_hz') or 0,
                bandwidth_hz=tx.get('bandwidth_hz') or 0,tx1_on=bool(tx.get('applied_mask',0)&1))

def auto_view(samples,fs,max_span,symbol_rate=0.,symbol_view=False):
    """One-shot AUTO scaling: span/offset around active bins, time window,
    amplitude and dB range, plus the FFT size that resolves the chosen span."""
    base=periodogram(samples,fs,4096);freq=np.fft.fftshift(np.fft.fftfreq(len(base),1/fs))
    floor=float(np.median(base));active=(base>floor*16)&(abs(freq)<max_span/2)
    if np.any(active):
        lo,hi=float(freq[active][0]),float(freq[active][-1])
        span=min(max_span,max(fs/len(base)*32,(hi-lo)*1.5));offset=(lo+hi)/2
    else:span=max_span;offset=0.
    offset=float(np.clip(offset,-max_span/2+span/2,max_span/2-span/2))
    if symbol_view and symbol_rate>0:time_span=min(len(samples)/fs,10/symbol_rate)
    else:
        tone=abs(float(freq[int(np.argmax(base))]))
        duration=6/tone if 0<np.count_nonzero(active)<8 and tone>fs/len(base) else 8/max(1,span)
        time_span=min(len(samples)/fs,max(16/fs,duration))
    db=10*np.log10(np.maximum(base,1e-18))
    return dict(view_span=span,view_offset=offset,time_span=time_span,
        amplitude_limit=max(32.,2**math.ceil(math.log2(max(1.,float(np.percentile(abs(samples),99))*1.2)))),
        db_high=math.ceil(float(np.max(db))/10)*10+10,db_low=math.floor(float(np.percentile(db,10))/10)*10-10,
        nfft=min(65536,max(1024,1<<int(math.ceil(math.log2(fs/max(1,span)*1024))))))

def analyze_spectrum(raw,fs,nfft,auto=False,max_span=0.,symbol_rate=0.,symbol_view=False):
    """Spectrum job; runs in a worker process. Returns plain arrays/numbers only."""
    samples=iq_array(raw)
    view=auto_view(samples,fs,max_span,symbol_rate,symbol_view) if auto else None
    if view:nfft=view['nfft']
    return dict(power=periodogram(samples,fs,nfft),iq_db=amplitude_db(samples,nfft),auto=view)

def analyze_constellation(raw,fs,mode,rs,carrier,timing,prior_hz=0.,limit=8192):
    """Synchronization job; runs in a worker process."""
    points,info=synchronize(iq_array(raw),fs,mode,rs,carrier,timing,prior_hz)
    return np.asarray(points[-limit:],dtype=complex),info

def synchronize(samples,fs,mode,rs,carrier=False,timing=False,prior_hz=0.):
    """Known-modulation RRC/Gardner and coarse Mth-power/DD carrier recovery.

    Each call processes one contiguous block; no filter state bridges a packet
    gap or a skipped display block. Quadrant/symbol-label ambiguities remain.
    prior_hz (carrier only) removes a known offset, e.g. TX LO+offset minus RX
    LO, before the limited-range coarse CFO search.
    """
    if not (carrier or timing):return samples,dict(text='原始 IQ 点云',locked=False)
    if not mode.endswith(('PSK','QAM','ASK')):
        return samples,dict(text='当前调制不使用线性调制星座同步',locked=False)
    if not 0<rs<=fs/2:
        return samples,dict(text='符号率须大于 0，且每符号至少 2 个采样点',locked=False)
    sps=fs/rs
    if len(samples)<max(256,32*sps):
        return samples,dict(text='连续样点不足，等待至少 32 个符号',locked=False)
    z=samples.astype(complex).copy();rms=np.sqrt(np.mean(abs(z)**2))
    if rms<1:return samples,dict(text='信号幅度过低',locked=False)
    z/=rms;order=int(mode[:-3]);m=order if mode.endswith('PSK') else 1 if mode.endswith('ASK') else 4
    cfo=0.
    if carrier:
        prior=float(prior_hz or 0.)
        if prior:z*=np.exp(-2j*np.pi*prior*np.arange(len(z))/fs)
        # Bound amplitude before high powers; PSK phase statistics carry CFO.
        v=(z/np.maximum(1,abs(z)))**m
        spec=abs(np.fft.fftshift(np.fft.fft(v*np.hanning(len(v)))))
        freq=np.fft.fftshift(np.fft.fftfreq(len(v),1/fs))
        allowed=abs(freq)<min(fs*.48,rs*.45*m)
        peak=int(np.argmax(np.where(allowed,spec,0)))
        residual=float(freq[peak]/m)
        z*=np.exp(-2j*np.pi*residual*np.arange(len(z))/fs)
        cfo=prior+residual
    if timing:
        z=convolve_same(z,rrc(sps))
        margin=min(len(z)//4,int(6*sps))
        # Initial timing from periodic symbol energy; then Gardner tracks drift.
        phases=np.arange(0,sps,max(sps/64,.05))
        score=[]
        for phase in phases:
            ids=np.arange(margin+phase,len(z)-margin,sps)
            base=ids.astype(int);frac=ids-base
            vals=z[base]*(1-frac)+z[np.minimum(base+1,len(z)-1)]*frac
            score.append(np.mean(abs(vals)**2) if len(vals) else 0)
        t=margin+phases[int(np.argmax(score))];omega=sps;symbols=[]
        power=max(1e-12,float(np.mean(abs(z)**2)))
        # Python complex list: per-symbol NumPy scalar indexing dominates otherwise.
        zl=z.tolist();lo,hi=.98*sps,1.02*sps;gain_f,gain_p=.00005*sps,.01*sps
        end=len(z)-margin;half=sps/2
        while t+half<end:
            i=int(t-half);f=t-half-i;early=zl[i]*(1-f)+zl[i+1]*f
            i=int(t);f=t-i;mid=zl[i]*(1-f)+zl[i+1]*f
            i=int(t+half);f=t+half-i;late=zl[i]*(1-f)+zl[i+1]*f
            err=min(1.,max(-1.,((late-early)*mid.conjugate()).real/power))
            omega=min(hi,max(lo,omega+gain_f*err))
            symbols.append(mid);t+=omega+gain_p*err
        z=np.asarray(symbols,dtype=complex)
    z/=max(1e-12,np.sqrt(np.mean(abs(z)**2)))
    if carrier:
        moment=np.mean(z**m)
        phase=(np.angle(moment)-(np.pi if mode.endswith('QAM') else 0))/m
        z*=np.exp(-1j*phase)
        if timing and len(z):
            # Select the QAM orientation minimizing EVM before tracking residual
            # frequency. This never snaps displayed points to ideal decisions.
            if mode.endswith('QAM'):
                phases=np.linspace(-np.pi/4,np.pi/4,65)
                errors=[np.mean(abs(z*np.exp(-1j*p)-decision(z*np.exp(-1j*p),mode))**2) for p in phases]
                z*=np.exp(-1j*phases[int(np.argmin(errors))])
            out=[];phase=0.;freq=0.;decide=scalar_decision(mode)
            for value in z.tolist():
                v=value*cmath.exp(-1j*phase);d=decide(v)
                error=min(.4,max(-.4,cmath.phase(v*d.conjugate()))) if abs(d)>1e-8 else 0.
                freq+=.0001*error;phase+=freq+.025*error;out.append(v)
            z=np.asarray(out,dtype=complex)
    error=float(np.mean(abs(z-decision(z,mode))**2)) if carrier and timing and len(z) else None
    locked=bool(error is not None and len(z)>=64 and error<(.025 if mode.endswith('QAM') else .12))
    text=('同步估计有效' if locked else '同步估计中 / 未锁定')+f' · CFO {cfo:g} Hz'
    if error is not None:text+=f' · EVM {100*np.sqrt(error):.1f}%'
    return z,dict(text=text,locked=locked,cfo_hz=cfo,evm_rms=None if error is None else np.sqrt(error))
