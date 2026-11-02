"""Exercise actual RTL with xsim, measure samples with NumPy (no board claim)."""
import sys,pathlib,subprocess,shutil,json,time
import numpy as np
R=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'host'))
from waveform_config import WaveformConfig,MODES,FS
B=pathlib.Path(r'D:\Xilinx\2025.2\Vivado\bin');O=R/'reports/waveform_sim';O.mkdir(parents=True,exist_ok=True)
cases=[WaveformConfig(modulation=m,snr_db=0) for m in MODES]
# Firmware 23: bandwidth_hz is the one-sided baseband B; 4PSK occupies 2B.
cases += [WaveformConfig(modulation='4PSK',bandwidth_hz=b,snr_db=s,
 noise_low_hz=-b,noise_high_hz=b) for b,s in [(500_000,-10),(500_000,20),(5_000,0),(10_000_000,0)]]
# Firmware 23: SSB tx1_offset_hz is the carrier; the sideband is carrier..+B (USB) or -B..carrier (LSB),
# the tone sits at carrier +/-B (band edge), TX1 noise is centred at carrier +/-B/2. tx1_noise=False forces cfg[11]=0.
ssb_cases=[WaveformConfig(modulation=m,bandwidth_hz=1_000_000,snr_db=0,sideband=sb,tx1_offset_hz=o)
 for m,sb,o in [('AM-SSB-SC','USB',0),('AM-SSB-SC','LSB',2_000_000),('AM-SSB-WC','USB',-3_000_000),
                ('AM-SSB-WC','LSB',1_500_000)]]
quiet_cases=[WaveformConfig(modulation=m,snr_db=0,tx1_noise=False) for m in ('4PSK','AM-SSB-SC','FM')]
cases+=ssb_cases+quiet_cases
for p in (R/'rtl/rom').glob('*.mem'):shutil.copy2(p,O/p.name)
blocks=[]
for k,c in enumerate(cases):
 n=524288 if c.bandwidth_hz==5000 else 65536
 words=c.plan()['registers'];packed=sum(v<<(32*j) for j,v in enumerate(words))
 blocks.append(f'''rst=1; cfg=512'h{packed:0128x}; repeat(12)@(negedge clk);
 rst=0; f=$fopen("samples_{k}.txt","w"); count=0;
 while(count<{n})begin @(negedge clk);if(valid)begin
 $fwrite(f,"%0d %0d %0d %0d %0d %0d %0d %0d\\n",i1,q1,i2,q2,ci,cq,ni,nq);count=count+1;end end
 $fclose(f);$display("CASE {k} {c.modulation} DONE clips=%0d,%0d",clip1,clip2);''')
tb='''`timescale 1ns/1ps
module tb_waveforms;
reg clk=0,rst=1;always #5 clk=~clk;
reg [1:0] div=0;always @(posedge clk)if(rst)div<=0;else div<=div+1;
wire strobe=div==0;reg [511:0] cfg;reg en1=1,en2=1;
wire valid;wire signed [11:0] i1,q1,i2,q2;wire [31:0] clip1,clip2;
wire signed [31:0] ci,cq,ni,nq;
waveform_core dut(clk,rst,strobe,cfg,en1,en2,valid,i1,q1,i2,q2,clip1,clip2,ci,cq,ni,nq);
integer count,f;initial begin
'''+'\n'.join(blocks)+'''
en1=0;repeat(100)@(negedge clk);if(i1!==0||q1!==0)$fatal(1,"TX1 disable failed");
if(i2===0&&q2===0)$display("TX2 instantaneous zero allowed");
en2=0;repeat(100)@(negedge clk);if(i2!==0||q2!==0)$fatal(1,"TX2 disable failed");
en1=1;repeat(100)@(negedge clk);if(i2!==0||q2!==0)$fatal(1,"TX2 changed with TX1 enable");
$display("WAVEFORM DIGITAL GATES PASSED");$finish;end
initial begin #200000000;$fatal(1,"timeout");end
endmodule
'''
(O/'tb_waveforms.sv').write_text(tb,encoding='ascii')
def run(tool,args):
 with (O/(tool+'.log')).open('w') as f:
  p=subprocess.run([str(B/(tool+'.bat')),*map(str,args)],cwd=O,stdout=f,stderr=subprocess.STDOUT)
 log=(O/(tool+'.log')).read_text(errors='replace')
 if p.returncode or 'Fatal' in log:raise RuntimeError(log[-12000:])
 return log
if '--analyze-only' not in sys.argv:
 run('xvlog',['--sv',*[R/f'rtl/{p}.sv' for p in ['gaussian_prng','rrc_resampler','waveform_core']],O/'tb_waveforms.sv'])
 run('xelab',['tb_waveforms','-s','waveforms_tb'])
 log=run('xsim',['waveforms_tb','-runall']);print(log[-3000:])
results=[]
for k,c in enumerate(cases):
 a=np.loadtxt(O/f'samples_{k}.txt',dtype=np.float64)
 # History spans 33 symbols. Exclude at least 50 symbol periods at the input.
 warm=max(2048,int(50*FS/min(c.plan()['symbol_rate_hz'],c.plan()['rf_bandwidth_hz']/1.15)))
 a=a[warm:];assert len(a)>10000
 z=[a[:,j]+1j*a[:,j+1] for j in range(0,8,2)]
 if not c.tx1_noise:
  assert not np.any(z[3]),(c,'TX1 noise not zero')
  # Offset 0: TX1 output == clean codes (rotation by cos=32767 drops <=1 code); SSB included,
  # since firmware 23 puts its carrier at cfg[6] again.
  assert np.max(abs(z[0]-z[2]))<=2,(c,'clean path changed',np.max(abs(z[0]-z[2])))
  results.append({'mode':c.modulation,'tx1_noise':False,'max_noise_code':0,'samples_analyzed':len(a)});continue
 measured=10*np.log10(np.mean(abs(z[2])**2)/np.mean(abs(z[3])**2))
 tol=1.2 if c.bandwidth_hz==5000 else .45
 assert abs(measured-c.snr_db)<tol,(c,measured)
 if c.plan()['registers'][0] in (7,8):
  # Remaining TX1 power (tone/carrier removed) must lie inside the selected sideband.
  nfft=8192;nseg=len(a)//nfft;freq=np.fft.fftfreq(nfft,1/FS)
  t=np.arange(len(a))/FS;sgn=-1 if c.sideband=='LSB' else 1
  # Firmware 23: tx1_offset_hz is the carrier; tone at carrier +/-B, sideband centre at +/-B/2.
  carrier=c.tx1_offset_hz;tone=c.tx1_offset_hz+sgn*c.bandwidth_hz;want=c.tx1_offset_hz+sgn*c.bandwidth_hz/2
  y=z[0][:nseg*nfft]
  py=np.mean(abs(np.fft.fft(y.reshape(nseg,nfft)*np.hanning(nfft),axis=1))**2,axis=0)
  near=lambda f:abs(freq-f)<=FS/nfft*2
  # Noise codes are pre-rotation; check the rotated TX1 output with the tone and carrier excluded.
  mask=(abs(freq-tone)>FS/nfft*8)&(abs(freq-carrier)>FS/nfft*8)
  floor=float(py[mask].max())
  assert py[near(tone)].max()>floor*10,(c,'SSB tone not at carrier +/- B')
  if c.modulation=='AM-SSB-WC':
   assert py[near(carrier)].max()>floor*10,(c,'SSB-WC carrier not at the offset')
  inband=float(py[mask&(abs(freq-want)<c.bandwidth_hz*.45)].sum()/py[mask].sum())
  assert inband>.9,(c,'SSB noise not on sideband',inband)
  results.append({'mode':c.modulation,'sideband':c.sideband,'offset_hz':c.tx1_offset_hz,'carrier_hz':carrier,
   'noise_inband_fraction':inband,'measured_pre_dac_snr_db':float(measured),'samples_analyzed':len(a)});continue
 assert np.max(abs(a[:,:4]))<2048
 # Measure independent TX2 PSD occupied support and proper complex Gaussian moments.
 nfft=min(8192,len(a)//8);nseg=len(a)//nfft
 p=np.mean(abs(np.fft.fft(z[1][:nseg*nfft].reshape(nseg,nfft)*np.hanning(nfft),axis=1))**2,axis=0)
 freq=np.fft.fftfreq(nfft,1/FS);edge=c.bandwidth_hz
 outside=float(p[abs(freq)>edge+max(FS/nfft*3,edge*.1)].sum()/p.sum())
 assert outside<.025,(c,outside)
 corr=float(abs(np.mean(z[3]*np.conj(z[1])))/np.sqrt(np.mean(abs(z[3])**2)*np.mean(abs(z[1])**2)))
 assert corr<(.35 if c.bandwidth_hz==5000 else .12),(c,corr)
 results.append({'mode':c.modulation,'bandwidth_hz':c.bandwidth_hz,'requested_snr_db':c.snr_db,
 'measured_pre_dac_snr_db':float(measured),'tx2_outside_band_fraction':outside,'noise_cross_correlation':corr,
 'samples_analyzed':len(a)})
out={'passed':True,'board_verified':False,'sample_rate_hz':FS,'cases':results}
(O/'result.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
