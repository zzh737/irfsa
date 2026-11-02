"""xsim packet stream checked by the unmodified Wujing v1 decoder."""
from pathlib import Path
import subprocess,sys,json
R=Path(__file__).resolve().parents[1];O=R/'reports/packetizer_sim';O.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,r'D:\FPGA_programs\FPAI_30T\ps\udp')
from rf_protocol import decode_iq
B=Path(r'D:\Xilinx\2025.2\Vivado\bin')
(O/'tb_packetizer.sv').write_text('''`timescale 1ns/1ps
module tb_packetizer;
reg clk=0;always #4 clk=~clk;
reg rst=1,run=0;reg [2:0] div=0;reg [31:0] idx=0,cycle=0;
wire sv=run&&div==0;wire [15:0] si={6'd0,idx[9:0]},sq= -$signed(si);
wire hv,v,last,idle;wire [7:0] data;wire [63:0] samples,grams,drops;
reg ready=0;reg [31:0] rng=32'h12345678;reg [15:0] gap=0;
wire hr=ready&&gap==0;
rfiq_packetizer dut(.clk(clk),.rst(rst),.run(run),.stream_id(32'd1),.capture_id(32'd77),
.fs_hz(32'd25000000),.lo_hz(64'd2400000000),.gain_mdb(32'd10000),
.sample_clipped(idx==77),.sample_valid(sv),.sample_i(si),.sample_q(sq),.hdr_valid(hv),.hdr_ready(hr),
.data(data),.valid(v),.ready(hr),.last(last),.samples(samples),.datagrams(grams),.dropped(drops),.idle(idle));
integer f,bytes=0,packets=0;reg held=0;reg [8:0] beat;
always @(posedge clk)begin
 if(rst)begin div<=0;idx<=0;cycle<=0;end
 else begin
  cycle<=cycle+1;div<=div==4?0:div+1;
  if(sv&&dut.was_run)idx<=idx+1;
  if(held&&(!v||{last,data}!==beat))$fatal(1,"AXIS changed while stalled");
  held<=v&&!hr;beat<={last,data};
  if(v&&hr)begin
   $fwrite(f,"%02x",data);bytes=bytes+1;
   if(last)begin
    if(bytes!=1088)$fatal(1,"truncated datagram");bytes=0;packets=packets+1;$fwrite(f,"\\n");
   end
  end
 end
end
always @(negedge clk)begin
 rng<={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
 ready<=rng[5:0]!=0&&!(cycle>250000&&cycle<550000);
 if(gap!=0)gap<=gap-1;else if(v&&hr&&last)gap<=80;
end
initial begin
 f=$fopen("packets.txt","w");repeat(8)@(negedge clk);rst=0;run=1;
 wait(cycle>950000);wait(v&&dut.pos==91);@(negedge clk);run=0;
 wait(idle);repeat(4)@(negedge clk);
 if(packets%4!=0||drops==0)$fatal(1,"whole-window drain/drop failed");
 $fclose(f);$display("PACKETIZER PASSED packets=%0d dropped=%0d",packets,drops);$finish;
end
initial begin #12000000;$fatal(1,"timeout");end
endmodule
''',encoding='ascii')
for tool,args in [('xvlog',['--sv',R/'rtl/rfiq_packetizer.sv',O/'tb_packetizer.sv']),
 ('xelab',['tb_packetizer','-s','packets_tb']),('xsim',['packets_tb','-runall'])]:
 with (O/(tool+'.log')).open('w') as f:p=subprocess.run([str(B/(tool+'.bat')),*map(str,args)],cwd=O,stdout=f,stderr=subprocess.STDOUT)
 log=(O/(tool+'.log')).read_text(errors='replace')
 if p.returncode or 'Fatal' in log:raise RuntimeError(log[-5000:])
previous=-1;frag=0;gaps=0;windows=0
for line in (O/'packets.txt').read_text().splitlines():
 h,p=decode_iq(bytes.fromhex(line));assert h.capture_id==77 and h.fs_eff_hz==25_000_000
 assert bool(h.flags&4)==(h.window_seq==0), (h.window_seq,h.flags)
 assert h.fragment_index==frag
 if frag==0:
  assert h.window_seq>previous
  if previous>=0 and h.window_seq!=previous+1:assert h.flags&1;gaps+=1
  previous=h.window_seq;windows+=1
 for j in range(256):
  expected=(frag*256+j)%1024
  i=int.from_bytes(p[j*4:j*4+2],'little',signed=True);q=int.from_bytes(p[j*4+2:j*4+4],'little',signed=True)
  assert(i,q)==(expected,-expected),(h,j,i,q,expected)
 frag=(frag+1)%4
assert frag==0 and gaps>0
(O/'result.json').write_text(json.dumps({'passed':True,'windows':windows,'gap_events':gaps,
 'checks':['unmodified Wujing v1 decode+CRC','sample content and IQ byte order','random backpressure stability',
 'whole-window congestion drops','STOP mid-datagram drains complete windows'],'board_verified':False},indent=2))
print(log[-1000:]);print('Wire decoder, sequence, gap and sample checks passed')
