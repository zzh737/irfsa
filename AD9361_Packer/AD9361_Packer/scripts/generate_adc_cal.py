"""ADI ad9361_rx_adc_setup + ad9361_rx_tia_calib, specialized to fixed clocks.

The live LUT address is R2346*(16*C3_MSB+C3_LSB+14), read AFTER filter tuning.
No assumed device trim values are embedded. ADI BSD-3-Clause algorithm.
"""
from pathlib import Path
from math import isqrt
import json,hashlib
R=Path(__file__).resolve().parents[1]
def closest(n,d):return (n+d//2)//d
def cal(product, divider=7, bandwidth=20_000_000):
 # Fixed BBPLL/ADC clocks; ADI clamps the derived BBBW before ADC setup.
 bw=max(200_000,min(28_000_000,800_000_000*10000//(126906*divider)))
 rc=160975*10*product*bw//1_000_000_000
 if not rc:return [0]*64
 sqrt_rc=isqrt(rc);scaled=closest(200_000_000,640)
 inv=closest(640_000_000,closest(200_000_000,1000))
 tmp=closest(980000+20*max(1000,closest(inv,4)),1000)
 sq=isqrt(scaled);mn=min(1000,isqrt(4*scaled))
 u64=lambda n:n&((1<<64)-1)
 u32=lambda n:n&0xffffffff
 d=[0]*64;d[3]=d[4]=0x24
 d[7]=min(124,u64(-50000000+8*1585*sqrt_rc*mn)//100000000)
 d[8]=min(255,((rc>>1)+(20*inv*d[7]//80)*1000)//rc)
 d[10]=min(127,u64(-500000+77*sqrt_rc*mn)//1000000)
 d[9]=min(127,800*d[10]//1000)
 d[11]=min(255,((rc>>1)+20*inv*d[10]*1000)//(rc*77))
 d[12]=min(127,u32(-500000+80*sqrt_rc*mn)//1000000)
 d[13]=min(255,u64(-3*(rc>>1)+inv*d[12]*250)//rc)
 d[14]=21*(inv//10000)
 d[15]=min(127,(500+1025*d[7])//1000)
 d[16]=min(127,d[15]*tmp//1000);d[17]=d[15]
 d[18]=min(127,(500+975*d[10])//1000)
 d[19]=min(127,d[18]*tmp//1000);d[20]=d[18]
 d[21]=min(127,(500+975*d[12])//1000)
 d[22]=min(127,d[21]*tmp//1000);d[23]=d[21]
 d[24]=0x2e;d[25]=128+min(63000,closest(63*scaled,1000))//1000
 d[26]=min(63,(63*scaled//1000000)*(920+80*inv//1000)//1000)
 d[27]=min(63,32*sq//1000)
 d[28]=d[31]=d[25];d[29]=d[32]=d[26];d[30]=d[27]
 d[33]=min(63,63*sq//1000);d[34]=min(127,64*sq//1000)
 d[35]=d[36]=0x40;d[37]=0x2c
 ctia=10*product*18300*560//3500000
 if ctia>2920:lsb=0x40;msb=min(127,closest(ctia-400,320))
 else:lsb=(closest(u32(ctia-400),40)+0x40)&255;msb=0
 # Additional five addresses: 1DB,1DC,1DD,1DE,1DF.
 d[40:45]=[0xe0 if bandwidth<=6_000_000 else 0x60,lsb,msb,lsb,msb]
 assert all(0<=v<256 for v in d)
 return d
if __name__=='__main__':
 p=R/'rtl/rom/adc_cal.mem'
 with p.open('w',encoding='ascii') as f:
  for n in range(8192):f.write(''.join(f'{v:02x}\n' for v in cal(n)))
 (R/'rtl/rom/adc_cal_manifest.json').write_text(json.dumps({
  'bbpll_hz':800000000,'adc_hz':200000000,'rxbbf_div':7,
  'lut_address':'R2346*(16*C3_MSB+C3_LSB+14)','entries':8192,'bytes_per_entry':64,
  'sha256':hashlib.sha256(p.read_bytes()).hexdigest()},indent=2),encoding='ascii')
 print('Generated runtime ADC/TIA calibration LUT')
