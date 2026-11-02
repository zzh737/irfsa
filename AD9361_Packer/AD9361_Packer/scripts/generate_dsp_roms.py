"""Deterministic build-time constants; the FPGA never runs Python."""
from pathlib import Path
from math import sin, cos, pi, sqrt
from statistics import NormalDist
import hashlib,json
R=Path(__file__).resolve().parents[1]
D=R/'rtl'/'rom';D.mkdir(exist_ok=True)
def save(name,values,bits=16):
    p=D/name;p.write_text(''.join(f'{v&((1<<bits)-1):0{bits//4}x}\n' for v in values),encoding='ascii')
def rrc(t,b):
    if abs(t)<1e-10:return 1+b*(4/pi-1)
    if abs(abs(t)-1/(4*b))<1e-9:
        return b/sqrt(2)*((1+2/pi)*sin(pi/(4*b))+(1-2/pi)*cos(pi/(4*b)))
    return (sin(pi*t*(1-b))+4*b*t*cos(pi*t*(1+b)))/(pi*t*(1-(4*b*t)**2))
save('sine.mem',[round(32767*sin(2*pi*i/4096)) for i in range(4096)])
save('gaussian.mem',[round(4096*NormalDist().inv_cdf((i+.5)/4096)) for i in range(4096)])
for name,beta in [('rrc_data.mem',.35),('rrc_noise.mem',.15)]:
    # Causal 33-symbol pulse, 128 fractional phases, Q2.14 coefficients.
    vals=[round(16384*rrc(k+p/128-16,beta)) for k in range(33) for p in range(128)]
    assert max(vals)<32768 and min(vals)>=-32768
    save(name,vals)
(D/'manifest.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest()
                                         for p in sorted(D.glob('*.mem'))},indent=2),encoding='ascii')
print('Generated sine, inverse Gaussian CDF and two fractional RRC pulse tables')
