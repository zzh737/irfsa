"""Physical UART + UDP mailbox + RFCT + RFIQ: TX changes never restart RX."""
from sim_utils import *
from source_manifest import design_sources
import struct,zlib,sys,json,hashlib
sys.path.insert(0,str(R/'host'))
from ku5p import pack_request,unpack_response
from waveform_config import WaveformConfig
from rf_protocol import ControlMessage,RFConfig,StreamConfig,decode_control,decode_iq

def txbody(**kw):
    c=WaveformConfig(**kw);p=c.plan()
    return struct.pack('>QIiHHii16II',c.center_hz,c.bandwidth_hz,round(c.snr_db*1000),
        round(c.tx1_attenuation_db*4),round(c.tx2_attenuation_db*4),c.noise_low_hz,c.noise_high_hz,*p['registers'],0)

def uart(rid,op,body=b''):
    return pack_request(2,rid,0,op,0 if op==0x102 else 42,body)
def net(rid,op,cfg=0,body=b'',boot=42):
    return ControlMessage(0,rid,cfg,op,0,boot,body).pack()

commands=[];blocks=[];expected_uart=[];expected_net=[]
def serial(p,status=0,reply=True):
    index=len(commands);commands.append(p)
    blocks.append(f'load_serial({index},{len(p)});')
    if reply:
        expected_uart.append((p,status));blocks.append(f'wait(ur_count=={len(expected_uart)});repeat(5)@(negedge clk);')
def udp(p,status=0):
    expected_net.append((p,status))
    blocks.append(f"send_net(1024'h{p.ljust(128,bytes(1)).hex()},{len(p)});wait(nr_count=={len(expected_net)});")

serial(uart(1,0x102))  # No Ethernet link: UART-only operation must work.
serial(uart(2,0x100,txbody()))
serial(uart(3,0x101,struct.pack('>I',3)))
udp(net(1,5,boot=0))  # Same numeric ID in the other domain is legal.
blocks.append('link_up=1;')
udp(net(2,1,1,RFConfig(2400000000,25000000,20000000,10000,0,0).pack()))
udp(net(3,2,1,StreamConfig(1,1000000,25,0,1024,1024,0,0,0).pack()))
udp(net(4,3,1,struct.pack('>I',1)))
blocks.append('watch_rx=1;samples_before=samples;')
live=uart(4,0x100,txbody(center_hz=915000000,modulation='FM',bandwidth_hz=2000000,snr_db=-5))
serial(live)
serial(live)  # Must return exact cached reply without retune or DSP reset.
serial(uart(5,0x100,txbody(center_hz=915000000,modulation='16PSK',bandwidth_hz=500000,snr_db=20)))
serial(uart(6,0x101,struct.pack('>I',1)))
bad=bytearray(uart(7,0x101,struct.pack('>I',0)));bad[-1]^=1
serial(bytes(bad),reply=False)
serial(net(7,4),reply=False)  # RX command is never executed via UART.
serial(uart(7,0x102))
udp(net(5,5))
udp(net(6,6,boot=0))
blocks.append('if(samples<=samples_before||applies!=0||txapplies!=1||rxapplies!=0||digital!=1||applied!=1)$fatal(1,"live TX/RX invariant");watch_rx=0;')
udp(net(7,4))
blocks.append('repeat(40000)@(negedge clk);')

out=R/'reports/split_control';out.mkdir(parents=True,exist_ok=True)
for i,p in enumerate(commands):(out/f'command{i}.mem').write_text('\n'.join(f'{v:02x}' for v in p),encoding='ascii')
tb=r'''~timescale 1ns/1ps
module tb_split_control;
reg clk=0;always #4 clk=~clk;
reg rst=1,serial_rx=1,net_cv=0,link_up=0;wire serial_tx,net_cr;
reg [1023:0] net_cmd;reg [15:0] net_len;
wire cv,cr,cu,ru,hv,hr,v,r,last;wire [7:0] data;wire [15:0] len,clen;wire [1023:0] cmd;
wire nhv,nv,nlast;wire [7:0] nd;wire [15:0] nlen;
control_transport #(.CLOCK_HZ(1000000),.BAUD(100000)) transport(
 .clk(clk),.rst(rst),.uart_rx(serial_rx),.uart_tx(serial_tx),
 .net_command_valid(net_cv),.net_command_ready(net_cr),.net_command_bytes(net_cmd),.net_command_length(net_len),
 .command_valid(cv),.command_ready(cr),.command_uart(cu),.command_bytes(cmd),.command_length(clen),
 .reply_uart(ru),.hdr_valid(hv),.hdr_ready(hr),.reply_length(len),.data(data),.valid(v),.ready(r),.last(last),
 .net_hdr_valid(nhv),.net_hdr_ready(1'b1),.net_length(nlen),.net_data(nd),.net_valid(nv),.net_ready(1'b1),.net_last(nlast));
wire [7:0] ur_data;wire ur_valid,ur_error;
uart_phy #(.CLOCK_HZ(1000000),.BAUD(100000)) peer(
 .clk(clk),.rst(rst),.rx(serial_tx),.tx(),.rx_data(ur_data),.rx_valid(ur_valid),.rx_error(ur_error),
 .tx_data(8'd0),.tx_valid(1'b0),.tx_ready());
wire apply,rxapply,txapply,gate;wire [63:0] txlo,rxlo;wire [1:0] requested,digital;
wire [8:0] att1,att2;wire [511:0] dsp;wire toggle;reg ack=0;
reg rr=1,rb=0,rd=0;reg [1:0] applied=0;
wire run,dec;wire [31:0] capture,fs,fifo;wire idle;
wire [63:0] samples,datagrams,drops;wire ihv,iv,il;wire [7:0] idata;
rfct_controller #(.CLOCK_HZ(1000000)) controller(
 .clk(clk),.rst(rst),.boot_id(32'd42),.link_up(link_up),
 .command_valid(cv),.command_ready(cr),.command_uart(cu),.reply_uart(ru),.command_bytes(cmd),.command_length(clen),
 .hdr_valid(hv),.hdr_ready(hr),.reply_length(len),.data(data),.valid(v),.ready(r),.last(last),
 .radio_ready(rr),.radio_fault(1'b0),.radio_busy(rb),.radio_done(rd),.applied_mask(applied),.radio_fault_index(16'd0),.quad_warn(1'b0),.quad_mode(2'd0),
 .radio_apply(apply),.radio_rx_apply(rxapply),.radio_tx_apply(txapply),.radio_lo(txlo),.radio_rx_lo(rxlo),
 .gate_start(gate),.requested_mask(requested),.digital_mask(digital),.attenuation1(att1),.attenuation2(att2),
 .dsp_config(dsp),.dsp_toggle(toggle),.dsp_ack(ack),.capture_run(run),.decimate25(dec),.capture_id(capture),.fs_eff_hz(fs),
 .packet_idle(idle),.fifo_points(fifo),.sample_count(samples),.datagrams(datagrams),.drop_windows(drops),
 .overflow_events(64'd0),.clip_count1(32'd0),.clip_count2(32'd0),.data_fault(1'b0));
integer divider=0;reg sv=0;reg [15:0] point=0;
always @(posedge clk)begin
 sv<=0;if(divider==4)begin divider<=0;sv<=1;point<=point+1;end else divider<=divider+1;
end
rfiq_packetizer packetizer(.clk(clk),.rst(rst),.run(run),.stream_id(32'd1),.capture_id(capture),
 .fs_hz(fs),.lo_hz(rxlo),.gain_mdb(32'd10000),.sample_clipped(1'b0),.sample_valid(sv),.sample_i(point),.sample_q(~point),
 .hdr_valid(ihv),.hdr_ready(1'b1),.data(idata),.valid(iv),.ready(1'b1),.last(il),
 .samples(samples),.datagrams(datagrams),.dropped(drops),.occupied(),.idle(idle),.fifo_points(fifo));
integer timer=0,applies=0,txapplies=0,rxapplies=0;reg gate_op=0;
always @(posedge clk)begin
 rd<=0;ack<=toggle;
 if(apply||rxapply||txapply)begin timer<=1000;rb<=1;gate_op<=0;
  if(apply)applies<=applies+1;if(rxapply)rxapplies<=rxapplies+1;if(txapply)txapplies<=txapplies+1;
 end
 if(gate)begin timer<=200;rb<=1;gate_op<=1;end
 if(timer>0)begin timer<=timer-1;if(timer==1)begin rb<=0;rd<=1;if(gate_op)applied<=requested;end end
end
integer uf,nf,iqf,ur_count=0,nr_count=0,ur_pos=0;reg watch_rx=0;reg [63:0] samples_before;
always @(posedge clk)begin
 if(ur_error)$fatal(1,"UART output framing error");
 if(ur_valid)begin $fwrite(uf,"%02x",ur_data);if(ur_pos==159)begin ur_pos=0;ur_count=ur_count+1;$fwrite(uf,"\n");end else ur_pos=ur_pos+1;end
 if(nv)begin $fwrite(nf,"%02x",nd);if(nlast)begin nr_count=nr_count+1;$fwrite(nf,"\n");end end
 if(iv)begin $fwrite(iqf,"%02x",idata);if(il)$fwrite(iqf,"\n");end
 if(watch_rx&&(!run||capture!=1||rxlo!=2400000000||fs!=1000000))$fatal(1,"TX control restarted or retuned RX");
end
reg [7:0] bytes_in[0:127];
task load_serial(input integer index,input integer length);
 integer j,k;begin
 $readmemh($sformatf("command%0d.mem",index),bytes_in,0,length-1);
 for(j=0;j<length;j=j+1)begin
  @(negedge clk);serial_rx=0;repeat(10)@(negedge clk);
  for(k=0;k<8;k=k+1)begin serial_rx=bytes_in[j][k];repeat(10)@(negedge clk);end
  serial_rx=1;repeat(10)@(negedge clk);
 end
 end
endtask
task send_net(input [1023:0] bytes,input [15:0] length);
 begin @(negedge clk);net_cmd=bytes;net_len=length;net_cv=1;
 do @(posedge clk);while(!net_cr);@(negedge clk);net_cv=0;end
endtask
initial begin
 uf=$fopen("uart.hex","w");nf=$fopen("net.hex","w");iqf=$fopen("iq.hex","w");
 repeat(5)@(negedge clk);rst=0;
'''+''.join(blocks)+r'''
 $fclose(uf);$fclose(nf);$fclose(iqf);$display("SPLIT LIVE CONTROL PASSED");$finish;
end
initial begin #10000000;$fatal(1,"split control timeout uart=%d net=%d state=%d operation=%d",ur_count,nr_count,controller.state,controller.operation);end
endmodule'''
run_sim('split_control',tb,design_sources(['control_transport','rfct_controller','rfiq_packetizer']))
uart_replies=[bytes.fromhex(s) for s in (out/'uart.hex').read_text().splitlines()]
net_replies=[bytes.fromhex(s) for s in (out/'net.hex').read_text().splitlines()]
for expected,replies in ((expected_uart,uart_replies),(expected_net,net_replies)):
    for (request,status),p in zip(expected,replies,strict=True):
        h=struct.unpack_from('>4sBBHIIHHIII',p)
        assert h[7]==status and h[4:7]==struct.unpack_from('>4sBBHIIHHIII',request)[4:7]
        assert zlib.crc32(p[:28]+bytes(4)+p[32:])==h[10]
assert uart_replies[3]==uart_replies[4]
for p in uart_replies[3:]:assert struct.unpack_from('>I',p,32+24)[0] in (1,3)
snapshot=decode_control(net_replies[-3]).payload
assert snapshot[0]==2 and struct.unpack_from('>II',snapshot,4)==(1,1)
assert struct.unpack_from('>Q',snapshot,16)[0]==2400000000
info=struct.unpack('>8I',net_replies[-2][32:]);assert info[:4]==(1,6,1,1)
iq=[decode_iq(bytes.fromhex(s))[0] for s in (out/'iq.hex').read_text().splitlines()]
assert len(iq)>16 and len(iq)%4==0
for i,h in enumerate(iq):
    assert (h.capture_id,h.lo_hz,h.fs_eff_hz,h.window_seq,h.fragment_index,h.sample_index)==(1,2400000000,1000000,i//4,i%4,(i//4)*1024)
sources=design_sources(['control_transport','rfct_controller','rfiq_packetizer'])
vectors=R/'protocol/vectors_uart_rx';vectors.mkdir(parents=True,exist_ok=True)
for domain,expected,replies in (('uart',expected_uart,uart_replies),('udp',expected_net,net_replies)):
    for i,((request,status),response) in enumerate(zip(expected,replies,strict=True)):
        (vectors/f'{domain}_{i:02d}_request.bin').write_bytes(request)
        (vectors/f'{domain}_{i:02d}_response.bin').write_bytes(response)
(vectors/'rfiq_first.bin').write_bytes(bytes.fromhex((out/'iq.hex').read_text().splitlines()[0]))
(vectors/'manifest.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in vectors.glob('*.bin')},indent=2))
(out/'result.json').write_text(json.dumps(dict(passed=True,hardware_verified=False,
    physical_uart_8n1=True,uart_without_ethernet=True,independent_request_domains=True,
    identical_retry_no_side_effects=True,uart_bad_crc_and_rx_command_rejected=True,
    live_tx_reconfigure_preserves_rx=True,iq_datagrams=len(iq),rx_discovery_extension=True,
    sources_sha256={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}),indent=2))
