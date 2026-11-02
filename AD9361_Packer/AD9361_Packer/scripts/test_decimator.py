from sim_utils import *
from source_manifest import design_sources
import numpy as np,json
rng=np.random.default_rng(614)
samples=rng.integers(-1600,1601,(20000,2),dtype=np.int64)
samples[1000,0]=2047
out=R/'reports/decimator';out.mkdir(parents=True,exist_ok=True)
(out/'samples.mem').write_text(''.join(f'{int(q)&65535:04x}{int(i)&65535:04x}\n' for i,q in samples))
tb=r'''~timescale 1ns/1ps
module tb_decimator;
reg clk=0;always #4 clk=~clk;
reg rst=1,v=0,clipped=0;reg signed [15:0] i=0,q=0;wire v1,v2,f1,f2,c1,c2;
wire signed [15:0] i1,q1,i2,q2;
fir_decimate5 a(clk,rst,v,i,q,v1,i1,q1,f1,clipped,c1);
fir_decimate5 #(.LOG_TAPS(8),.LANES(4),.ROM_FILE("decim2.mem")) b(clk,rst,v1,i1,q1,v2,i2,q2,f2,c1,c2);
reg [31:0] points[0:19999];integer f,g,n;
initial begin
 $readmemh("samples.mem",points);f=$fopen("stage1.txt","w");g=$fopen("stage2.txt","w");
 repeat(5)@(negedge clk);rst=0;
 for(n=0;n<20000;n=n+1)begin @(negedge clk);v=1;clipped=(n==1000);{q,i}=points[n];@(negedge clk);v=0;repeat(3)@(negedge clk);end
 repeat(500)@(negedge clk);if(f1||f2)$fatal(1,"FIR overrun");
 $fclose(f);$fclose(g);$display("FIR CHECKS PASSED");$finish;
end
always @(posedge clk)begin #1;if(v1)$fdisplay(f,"%d %d %d",i1,q1,c1);if(v2)$fdisplay(g,"%d %d %d",i2,q2,c2);end
endmodule'''
run_sim('decimator',tb,design_sources(['fir_decimate5']))
def coeff(name):
    a=np.array([int(x,16) for x in (R/f'rtl/rom/{name}.mem').read_text().split()],dtype=np.int64)
    return np.where(a>=131072,a-262144,a)
def fir(x,h,clipped):
    y=np.stack([np.convolve(x[:,k],h)[:len(x)] for k in (0,1)],axis=1)
    # First output index is phase 4 after the complete history is filled.
    first=((len(h)+4)//5)*5-1
    raw=(y[first::5]+65536)>>17
    inherited=np.convolve(clipped,np.ones(len(h),dtype=np.int64))[:len(x)][first::5]>0
    overload=inherited|np.any((raw>32767)|(raw< -32768),axis=1)
    return np.clip(raw,-32768,32767),overload
clips=np.zeros(len(samples),dtype=np.int64);clips[1000]=1
a,ca=fir(samples,coeff('decim1'),clips);b,cb=fir(a,coeff('decim2'),ca.astype(np.int64))
assert ca.any() and cb.any()
for name,expected in [('stage1',np.column_stack((a,ca))),('stage2',np.column_stack((b,cb)))]:
    actual=np.loadtxt(out/(name+'.txt'),dtype=np.int64)
    if not np.array_equal(actual,expected):raise AssertionError((name,actual.shape,expected.shape,actual[:4],expected[:4]))
(out/'result.json').write_text(json.dumps({'passed':True,'sample_exact_against_convolution':True,'ADC_clip_propagates_through_both_FIR_supports':True,'input_points':len(samples),'output_points':len(b),'hardware_verified':False},indent=2))
