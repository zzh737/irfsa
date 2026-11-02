from sim_utils import *
from source_manifest import design_sources
import sys,struct,zlib,json
sys.path.insert(0,str(R/'host'));from rf_protocol import ControlMessage,decode_control,decode_iq
def csum(x):
    if len(x)%2:x+=b'\0'
    v=sum(struct.unpack('>'+str(len(x)//2)+'H',x))
    while v>>16:v=(v&65535)+(v>>16)
    return (~v)&65535
local=bytes.fromhex('020000000002');peer=bytes.fromhex('020000000001')
arp=b'\xff'*6+peer+b'\x08\x06'+struct.pack('>HHBBH',1,0x800,6,4,1)+peer+bytes([192,168,10,1])+bytes(6)+bytes([192,168,10,2])
body=ControlMessage(0,1,0,5,0,0).pack()
def udp(bad=False):
    length=8+len(body)
    pseudo=bytes([192,168,10,1,192,168,10,2,0,17])+struct.pack('>H',length)
    uh=struct.pack('>HHHH',40001,40001,length,0)
    check=csum(pseudo+uh+body) or 65535
    if bad:check^=1
    uh=uh[:6]+struct.pack('>H',check)
    ip=struct.pack('>BBHHHBBH4s4s',0x45,0,20+length,1,0x4000,64,17,0,bytes([192,168,10,1]),bytes([192,168,10,2]))
    ip=ip[:10]+struct.pack('>H',csum(ip))+ip[12:]
    return local+peer+b'\x08\x00'+ip+uh+body
frames=[]
for p in (arp,udp(),udp(True)):
    p=p.ljust(60,b'\0');frames.append(b'\x55'*7+b'\xd5'+p+struct.pack('<I',zlib.crc32(p)))
out=R/'reports/ethernet';out.mkdir(parents=True,exist_ok=True)
blocks=[]
for j,p in enumerate(frames):
    (out/f'input{j}.mem').write_text('\n'.join(f'{v:02x}' for v in p))
    blocks.append(f'$readmemh("input{j}.mem",framebuf,0,{len(p)-1});send_frame({len(p)});repeat(500)@(negedge clk);')
tb=r'''~timescale 1ns/1ps
module tb_ethernet;
reg clk=0,tx_clk=0,tx_clk90=0;always #4 clk=~clk;always #4 tx_clk=~tx_clk;
initial begin #2;forever #4 tx_clk90=~tx_clk90;end
reg rst=1,rxc=0,rxctl=0;reg [3:0] rxd=0;always #4 rxc=~rxc;
wire txc,txctl;wire [3:0] txd;wire [1:0] speed;
// PHY TX internal delay is disabled; the FPGA provides the clock phase.
wire phy_txc=txc;
wire cmdv,cmdr;wire [1023:0] cmd;wire [15:0] cmdlen;wire [31:0] bad;
wire hv,hr,v,r,last;wire [15:0] len;wire [7:0] data;
wire ihv,ihr,iv,ir,il;wire [7:0] idata;reg iqrun=0,sv=0;reg [15:0] si=0,sq=0;
wire [63:0] drops,ndg;
rfiq_packetizer pkt(.clk(clk),.rst(rst),.run(iqrun),
 .stream_id(32'd1),.capture_id(32'd7),.fs_hz(32'd25000000),.lo_hz(64'd2400000000),.gain_mdb(32'd10000),
 .sample_clipped(1'b0),.sample_valid(sv),.sample_i(si),.sample_q(sq),.hdr_valid(ihv),.hdr_ready(ihr),
 .data(idata),.valid(iv),.ready(ir),.last(il),.samples(),.datagrams(ndg),.dropped(drops),
 .occupied(),.idle(),.fifo_points());
network_core net(.clk(clk),.tx_clk(tx_clk),.tx_clk90(tx_clk90),.rst(rst),.rgmii_rxc(rxc),.rgmii_rx_ctl(rxctl),.rgmii_rxd(rxd),
 .rgmii_txc(txc),.rgmii_tx_ctl(txctl),.rgmii_txd(txd),.link_speed(speed),
 .command_valid(cmdv),.command_ready(cmdr),.command_bytes(cmd),.command_length(cmdlen),.bad_commands(bad),
 .ctl_hdr_valid(hv),.ctl_hdr_ready(hr),.ctl_length(len),.ctl_data(data),.ctl_valid(v),.ctl_ready(r),.ctl_last(last),
 .iq_hdr_valid(ihv),.iq_hdr_ready(ihr),.iq_data(idata),.iq_valid(iv),.iq_ready(ir),.iq_last(il),
 .rx_overflow(),.tx_underflow(),.arp_failed());
rfct_controller control(.clk(clk),.rst(rst),.boot_id(32'd42),.link_up(1'b1),
 .command_uart(1'b0),.reply_uart(),
 .command_valid(cmdv),.command_ready(cmdr),.command_bytes(cmd),.command_length(cmdlen),
 .hdr_valid(hv),.hdr_ready(hr),.reply_length(len),.data(data),.valid(v),.ready(r),.last(last),
 .radio_ready(1'b1),.radio_fault(1'b0),.radio_busy(1'b0),.radio_done(1'b0),.applied_mask(2'd0),.radio_fault_index(16'd0),.quad_warn(1'b0),.quad_mode(2'd0),
 .radio_apply(),.gate_start(),.radio_lo(),.requested_mask(),.digital_mask(),.attenuation1(),.attenuation2(),
 .dsp_config(),.dsp_toggle(),.dsp_ack(1'b0),.capture_run(),.decimate25(),.capture_id(),.fs_eff_hz(),
 .packet_idle(1'b1),.fifo_points(32'd0),.sample_count(64'd0),.datagrams(64'd0),.drop_windows(64'd0),.overflow_events(64'd0),
 .clip_count1(32'd0),.clip_count2(32'd0),.data_fault(1'b0));
reg [7:0] framebuf[0:2047];
task send_frame(input integer n);
 integer j;begin @(negedge rxc);#2;
  for(j=0;j<n;j=j+1)begin rxctl=1;rxd=framebuf[j][3:0];#4;rxd=framebuf[j][7:4];#4;end
  rxctl=0;rxd=0;#96;
 end
endtask
integer f,count=0,commands=0;reg [3:0] low;reg dv=0,was_dv=0;
integer point;
always @(posedge phy_txc)begin low=txd;dv=txctl;end
always @(negedge phy_txc)begin
 if(dv)begin $fwrite(f,"%02x",{txd,low});was_dv=1;end
 else if(was_dv)begin $fwrite(f,"\n");count=count+1;was_dv=0;end
end
always @(posedge clk)if(cmdv&&cmdr)commands=commands+1;
initial begin
 f=$fopen("frames.hex","w");repeat(50)@(negedge clk);rst=0;repeat(2000)@(negedge clk);
'''+''.join(blocks)+r'''
 @(negedge clk);iqrun=1;repeat(2)@(negedge clk);
 for(point=0;point<32768;point=point+1)begin
  sv=1;si=point;sq=~point;@(negedge clk);sv=0;repeat(4)@(negedge clk);
 end
 iqrun=0;repeat(30000)@(negedge clk);
 if(drops!=0||ndg!=128)$fatal(1,"25 MSPS stream drops=%d datagrams=%d",drops,ndg);
 if(commands!=1||bad!=1)$fatal(1,"network accepted=%d rejected=%d frames=%d",commands,bad,count);
 $fclose(f);$display("ETHERNET CHECKS PASSED");$finish;
end
initial begin #5000000;$fatal(1,"network timeout");end
endmodule'''
run_sim('ethernet',tb,design_sources(['network_core','rfct_controller','rfiq_packetizer']),unisim=True)
frames=[bytes.fromhex(x) for x in (out/'frames.hex').read_text().splitlines()]
replies=[];iq=[]
for f in frames:
    assert f[:8]==b'\x55'*7+b'\xd5',f[:8].hex()
    p=f[8:-4];assert zlib.crc32(p)==struct.unpack('<I',f[-4:])[0],'Ethernet CRC'
    if p[12:14]==b'\x08\x06':continue
    assert p[12:14]==b'\x08\x00' and csum(p[14:34])==0
    ip=p[14:34];u=p[34:];ulen=struct.unpack_from('>H',u,4)[0];u=u[:ulen]
    assert csum(ip[12:20]+b'\0\x11'+struct.pack('>H',ulen)+u)==0,'UDP checksum'
    if struct.unpack_from('>H',u)[0]==40000:
        h,raw=decode_iq(u[8:]);iq.append((h.window_seq,h.fragment_index))
        base=h.sample_index+h.fragment_index*256
        expected=b''.join(struct.pack('<HH',(base+j)&65535,(~(base+j))&65535) for j in range(256))
        assert raw==expected,'IQ content after complete Ethernet/UDP pipeline'
    else:replies.append(decode_control(u[8:]))
assert len(replies)==1 and replies[0].request_id==1 and replies[0].boot_id==42
assert iq==[(w,f) for w in range(32) for f in range(4)]
(out/'result.json').write_text(json.dumps({'passed':True,'physical_RGMII_simulation':True,'ethernet_FCS':True,'IPv4_checksum':True,'UDP_checksum':True,'RFCT_reply':True,'bad_UDP_rejected':True,'IQ_25MSPS_windows':32,'IQ_datagrams':len(iq),'hardware_verified':False},indent=2))
