"""Two cascaded 5:1 FIRs, Kaiser-window lowpasses, Q17 coefficients."""
from pathlib import Path
import numpy as np,json
R=Path(__file__).resolve().parents[1]
profiles=[('decim1',128,25e6,2.5e6,2e6,3e6),('decim2',256,5e6,450e3,400e3,500e3)]
report=[]
for name,n,fs,fc,fp,stop in profiles:
    x=np.arange(n)-(n-1)/2
    h=2*fc/fs*np.sinc(2*fc/fs*x)*np.kaiser(n,7.86);h/=sum(h)
    q=np.rint(h*131072).astype(np.int64)
    q[n//2]+=131072-int(sum(q))
    (R/f'rtl/rom/{name}.mem').write_text(''.join(f'{v&0x3ffff:05x}\n' for v in q),encoding='ascii')
    H=np.abs(np.fft.rfft(q/131072,262144));f=np.fft.rfftfreq(262144,1/fs)
    report.append(dict(name=name,taps=n,passband_hz=fp,stopband_hz=stop,
        ripple_db=float(np.ptp(20*np.log10(H[f<=fp]))),
        rejection_db=float(-20*np.log10(max(H[f>=stop])))))
(R/'rtl/rom/decimator_manifest.json').write_text(json.dumps(report,indent=2))
print(report)
