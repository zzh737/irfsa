"""Eight RX filter profiles and compact exact ADI ADC/TIA coefficient ROM."""
from pathlib import Path
import json
from generate_adc_cal import cal

R=Path(__file__).resolve().parents[1]
BANDWIDTHS=(200_000,500_000,1_000_000,2_000_000,5_000_000,10_000_000,15_000_000,20_000_000)
VARIABLE=(7,8,9,10,11,12,13,15,16,18,19,21,22,41,42)
def divider(bw):
    target=126906*(max(200_000,bw//2)//10000)
    return min(511,(800_000_000+target-1)//target)

def generate():
    p=R/'rtl/rom/rx_cal_profiles.mem'
    with p.open('w',encoding='ascii') as f:
        for bw in BANDWIDTHS:
            for product in range(8192):
                d=cal(product,divider(bw),bw)
                f.write(f'{sum(d[n]<<(8*j) for j,n in enumerate(VARIABLE)):030x}\n')
    (R/'rtl/rom/rx_profiles.json').write_text(json.dumps({'bandwidths_hz':BANDWIDTHS,'dividers':[divider(b) for b in BANDWIDTHS],'adc_hz':200000000,'bbpll_hz':800000000,'hardware_verified':False},indent=2))

if __name__=='__main__':generate()
