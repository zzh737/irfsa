"""Malformed UDP/RFCT frames must have no effects; exercise the RTL mailbox."""
from pathlib import Path
import sys,struct,zlib,subprocess,json
R=Path(__file__).resolve().parents[1];O=R/'reports/command_rx_sim';O.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,r'D:\FPGA_programs\FPAI_30T\ps\udp')
from rf_protocol import ControlMessage
cases=[]
def checksum(data):
 if len(data)%2:data+=b'\0'
 s=sum(struct.unpack('>'+str(len(data)//2)+'H',data))
 while s>>16:s=(s&65535)+(s>>16)
 return (~s)&65535
def add(expected,**kw):
 rid=len(cases)+1
 p=ControlMessage(0,rid,0,5,0,0).pack()
 if kw.get('bad_crc'):p=p[:-1]+bytes([p[-1]^1])
 if kw.get('bad_magic'):p=b'NOPE'+p[4:]
 if kw.get('bad_version'):p=p[:4]+b'\x07'+p[5:]
 if kw.get('v2'):
  p=p[:4]+b'\x02'+p[5:28]+bytes(4)+p[32:]
  p=p[:28]+struct.pack('>I',zlib.crc32(p))+p[32:]
 flags=kw.get('flags',2);ihl=kw.get('ihl',5);src=kw.get('src',0xc0a80a01)
 port=kw.get('port',40001);length=len(p)+8
 pseudo=struct.pack('>IIBBHHHHH',src,0xc0a80a02,0,17,length,port,40001,length,0)
 c=checksum(pseudo+p) or 65535
 if kw.get('bad_sum'):c^=1
 if kw.get('zero_sum'):c=0
 cases.append((rid,expected,p,flags,ihl,src,port,length,c,kw.get('user',0),kw.get('offset',0),kw.get('bad_iplen',0)))
add(True);add(True,zero_sum=True)
for kw in ({'bad_crc':1},{'bad_magic':1},{'bad_version':1},{'flags':1},{'flags':4},
 {'ihl':6},{'src':0xc0a80a03},{'port':1234},{'bad_sum':1},{'user':1},{'offset':1},{'bad_iplen':1},{'v2':1}):add(False,**kw)
blocks=[]
for rid,expected,p,flags,ihl,src,port,length,c,user,offset,badip in cases:
 blocks.append(f'''wait(hr);@(negedge clk);hv=1;flags=3'd{flags};ihl=4'd{ihl};src=32'h{src:08x};
 sport={port};ulen={length};cs=16'h{c:04x};iplen={length+20+badip};fo={offset};
 @(negedge clk);hv=0;''')
 for j,b in enumerate(p):
  blocks.append(f"@(negedge clk);v=1;d=8'h{b:02x};last={int(j==len(p)-1)};user={user};")
 blocks.append('@(negedge clk);v=0;last=0;user=0;repeat(8)@(negedge clk);')
tb='''~timescale 1ns/1ps
module tb_command_rx;
reg clk=0;always #4 clk=~clk;
reg rst=1,hv=0,v=0,last=0,user=0;reg [7:0] d;
reg [3:0] ihl=5;reg [2:0] flags=2;reg [12:0] fo=0;
reg [31:0] src;reg [15:0] sport,ulen,cs,iplen;
wire hr,ready,cv;wire [1023:0] command;wire [15:0] cl;wire [31:0] bad;
udp_command_rx dut(.clk(clk),.rst(rst),.hdr_valid(hv),.hdr_ready(hr),
.dest_mac(48'h020000000002),.version(4'd4),.ihl(ihl),.ip_length(iplen),.ip_flags(flags),.fragment_offset(fo),
.source_ip(src),.dest_ip(32'hc0a80a02),.source_port(sport),.dest_port(16'd40001),
.udp_length(ulen),.udp_checksum(cs),.data(d),.valid(v),.ready(ready),.last(last),.user(user),
.command_valid(cv),.command_ready(1'b1),.command_bytes(command),.command_length(cl),.bad_packets(bad));
integer count=0;always @(posedge clk)if(cv)begin
 count=count+1;if(command[959-:32]!=count||cl!=32)$fatal(1,"unexpected command accepted");
end
initial begin repeat(5)@(negedge clk);rst=0;
'''+''.join(blocks)+f'''
if(count!=2||bad!={len(cases)-2})$fatal(1,"counts accepted=%0d rejected=%0d",count,bad);
$display("COMMAND RX CHECKS PASSED");$finish;end
endmodule
'''
(O/'tb_command_rx.sv').write_text(tb.replace('~timescale',chr(96)+'timescale'),encoding='ascii')
B=Path(r'D:\Xilinx\2025.2\Vivado\bin')
for tool,args in [('xvlog',['--sv',R/'rtl/udp_command_rx.sv',O/'tb_command_rx.sv']),
 ('xelab',['tb_command_rx','-s','commands_tb']),('xsim',['commands_tb','-runall'])]:
 with (O/(tool+'.log')).open('w') as f:p=subprocess.run([str(B/(tool+'.bat')),*map(str,args)],cwd=O,stdout=f,stderr=subprocess.STDOUT)
 log=(O/(tool+'.log')).read_text(errors='replace')
 if p.returncode or 'Fatal' in log:raise RuntimeError(log[-6000:])
(O/'result.json').write_text(json.dumps({'passed':True,'accepted':2,'rejected':len(cases)-2,'board_verified':False},indent=2))
print(log[-1200:])
