from sim_utils import *
from source_manifest import design_sources
import sys,struct,zlib,json
sys.path.insert(0,str(R/'host'));from waveform_config import WaveformConfig
sys.path.insert(0,r'D:\FPGA_programs\FPAI_30T\ps\udp')
from rf_protocol import ControlMessage,RFConfig,StreamConfig,decode_control
def v2(rid,op,body=b'',boot=42):
    h=struct.pack('>4sBBHIIHHIII',b'RFCT',2,0,32,rid,0,op,0,len(body),boot,0)
    p=h+body;return p[:28]+struct.pack('>I',zlib.crc32(p))+p[32:]
def v1(rid,op,cfg=0,body=b'',boot=42):return ControlMessage(0,rid,cfg,op,0,boot,body).pack()
rf=RFConfig(2400000000,25000000,20000000,10000,0,0).pack()
stream=StreamConfig(1,1000000,25,0,1024,1024,0,0,0).pack()
w=WaveformConfig(center_hz=915000000);regs=w.plan()['registers']
txbody=struct.pack('>QIiHHii16II',w.center_hz,w.bandwidth_hz,10000,80,120,-500000,500000,*regs,0)
cases=[
 (v1(1,5),0),(v1(2,1,1,rf),0),(v1(3,2,1,stream),0),(v1(4,3,1,struct.pack('>I',1)),0),
 (v1(4,3,1,struct.pack('>I',1)),0),(v1(5,5),0),(v1(5,5,1),3),
 (v1(2,1,1,rf,43),9),(v1(6,4),0),(v1(7,3,1,struct.pack('>I',2)),12),
 (v1(8,1,2,rf),0),(v1(9,2,2,stream),0),(v1(10,3,2,struct.pack('>I',1)),13),
 (v2(11,0x100,txbody),0),(v2(12,0x101,struct.pack('>I',1)),0),(v2(12,0x101,struct.pack('>I',1)),0),
 (v2(13,0x101,struct.pack('>I',2)),0),(v2(14,0x101,struct.pack('>I',3)),0),
 (v2(15,0x101,struct.pack('>I',0)),0),
 (v2(16,0x100,txbody[:12]+struct.pack('>i',20001)+txbody[16:]),3),(v2(17,0x102),0)]
blocks=[]
for idx,(p,status) in enumerate(cases):
    padded=p.ljust(128,b'\0')
    blocks.append(f"""
    @(negedge clk);cmd=1024'h{padded.hex()};cl={len(p)};cv=1;
    do @(posedge clk);while(!cr);
    @(negedge clk);cv=0;wait(responses=={idx+1});repeat(2)@(negedge clk);
    """)
def send_only(p):
    return f"""
    @(negedge clk);cmd=1024'h{p.ljust(128,bytes(1)).hex()};cl={len(p)};cv=1;
    do @(posedge clk);while(!cr);
    @(negedge clk);cv=0;
    """
blocks.append("rf=1;rr=0;rb=1;")
blocks.append(send_only(v2(18,0x100,txbody)))
blocks.append(send_only(v1(19,5)))
blocks.append("wait(responses==23);repeat(3)@(negedge clk);")
# Status replies while the earlier RF hardware operation is still pending.
cases.extend([(v1(19,5),0),(v2(18,0x100,txbody),0)])
blocks.append(send_only(v2(20,0x103)))
blocks.append("wait(responses==24);repeat(3)@(negedge clk);")
cases.append((v2(20,0x103),0))
blocks.append('if(applies!=2||gates!=7||digital!=0||applied!=0)$fatal(1,"side effect duplication");')
# Abandon a partially valid configuration, then replace it with a newer one.
extra=[(v1(21,1,3,rf),0),(v1(22,2,3,bytes(28)),5),
       (v1(23,1,4,rf),0),(v1(24,3,4,struct.pack('>I',3)),12),
       (v1(25,2,4,stream),0)]
for p,status in extra:
    cases.append((p,status));blocks.append(send_only(p)+f'wait(responses=={len(cases)});')
# Accepted START identifies this attempt even when its deferred work fails.
p=v1(26,3,4,struct.pack('>I',3))
blocks.append(send_only(p)+'wait(dut.operation!=0);repeat(30)@(negedge clk);df=1;')
cases.append((p,8));blocks.append(f'wait(responses=={len(cases)});')
failed_reply=len(cases)-1
for p,status in [(v1(27,5),0),(v1(28,4),0)]:
    cases.append((p,status));blocks.append(send_only(p)+f'wait(responses=={len(cases)});')
blocks.append('if(dut.rf_state!=0||dut.stage_id!=0)$fatal(1,"STOP did not clear fault staging");')
# Exercise UART radio recovery from a faulted RX state.
blocks.append('@(negedge clk);dut.rf_state=4;')
p=v2(29,0x100,txbody)
cases.append((p,0));blocks.append(send_only(p)+f'wait(responses=={len(cases)});')

# An unavailable EEPROM epoch must allow diagnostics, and reject every effect.
boot_failure_start=len(cases)
blocks.append('@(negedge clk);boot=0;saved_applies=applies;saved_gates=gates;')
for p,status in [(v2(1000,0x102,boot=0),0),(v2(1001,0x104,boot=0),0),
                 (v1(1002,6,boot=0),0),(v2(1003,0x101,struct.pack('>I',3),boot=0),8),
                 (v1(1004,1,99,rf,boot=0),8),(v2(1005,0x103,boot=0),0)]:
    cases.append((p,status));blocks.append(send_only(p)+f'wait(responses=={len(cases)});')
blocks.append('if(applies!=saved_applies||gates!=saved_gates||requested!=0||digital!=0||run)$fatal(1,"boot fault caused effects");')
blocks.append('@(negedge clk);boot=42;')
p=v2(1006,0x102)
cases.append((p,0));blocks.append(send_only(p)+f'wait(responses=={len(cases)});')
# Bench register access 0x105 (UART only): write 0x007=0x5a, read it back,
# identical retry replays the cached reply without a second SPI access.
reg_cases=len(cases)
blocks.append('saved_applies=applies;saved_gates=gates;')
for p,status in [(v2(1100,0x105,struct.pack('>HBB',0x007,1,0x5a)),0),
                 (v2(1101,0x105,struct.pack('>HBB',0x007,0,0)),0),
                 (v2(1101,0x105,struct.pack('>HBB',0x007,0,0)),0),
                 (v2(1102,0x105,struct.pack('>HBB',0x400,0,0)),3),
                 (v2(1103,0x105,struct.pack('>HBB',0x007,2,0)),3),
                 (v2(1104,0x105,b'\0\x07\0'),2),
                 (v2(1105,0x102),0)]:
    cases.append((p,status));blocks.append(send_only(p)+f'wait(responses=={len(cases)});')
blocks.append('if(reg_ops!=2||chip[7]!=8\'h5a||applies!=saved_applies||gates!=saved_gates)$fatal(1,"0x105 side effects ops=%0d chip7=%h applies=%0d/%0d gates=%0d/%0d",reg_ops,chip[7],applies,saved_applies,gates,saved_gates);')
# The same command over Ethernet (v1 transport) must be refused without access.
p=v2(1106,0x105,struct.pack('>HBB',0x007,1,0x11))
cases.append((p,5));blocks.append("@(negedge clk);uart_override=0;"+send_only(p)+f'wait(responses=={len(cases)});uart_override=1;')
blocks.append('if(reg_ops!=2||chip[7]!=8\'h5a)$fatal(1,"0x105 over Ethernet reached SPI");')
# HW19 C3: a TX retune whose radio script outlives the 30 s budget must not
# answer HW_TIMEOUT while the script is still running; it completes with OK.
def txlo(hz):return struct.pack('>Q',hz)+txbody[8:]
p=v2(2000,0x100,txlo(2420000000))
blocks.append('wait(!rb);'+send_only(p)+
 'wait(dut.operation==5&&rb);@(negedge clk);hold=1;dut.operation_timer=1;repeat(200)@(negedge clk);'
 f'if(responses!={len(cases)})$fatal(1,"HW_TIMEOUT while radio script still running");'
 'if(dut.operation!=5)$fatal(1,"operation abandoned under a running script");hold=0;')
cases.append((p,0));blocks.append(f'wait(responses=={len(cases)});')
# The 60 s hard limit still ends a script that never finishes.
p=v2(2001,0x100,txlo(3500000000))
blocks.append('wait(!rb);'+send_only(p)+
 'wait(dut.operation==5&&rb);@(negedge clk);hold=1;dut.operation_timer=1;dut.hard_timer=1;')
cases.append((p,7));blocks.append(f'wait(responses=={len(cases)});hold=0;')
blocks.append('if(dut.rf_state!=4)$fatal(1,"HW_TIMEOUT did not mark rf_state 4");')
# HW19 C4: after HW_TIMEOUT (no radio fault) UART 0x100 is accepted again.
p=v2(2002,0x100,txlo(2400000000))
blocks.append('wait(!rb);repeat(3)@(negedge clk);'+send_only(p))
cases.append((p,0));blocks.append(f'wait(responses=={len(cases)});')
timeout_cases=len(cases)-3
tb=r'''~timescale 1ns/1ps
module tb_controller;
reg clk=0;always #4 clk=~clk;
reg rst=1,cv=0;reg [1023:0] cmd;reg [15:0] cl;
reg [31:0] boot=42;integer saved_applies,saved_gates;reg uart_override=1;
wire regs_start,regs_write;wire [9:0] regs_addr;wire [7:0] regs_wdata;reg regs_done=0;reg [7:0] regs_rdata=0;
wire cr,hv,v,last;wire [15:0] len;wire [7:0] d;
reg rr=1,rf=0,rb=0,rd=0,df=0,hold=0;reg [1:0] applied=0;
wire apply,rxapply,txapply,gate;wire [63:0] lo;wire [1:0] requested,digital;
wire [8:0] at1,at2;wire [511:0] dsp;wire tog;reg ack=0;wire run,dec;
wire [31:0] capture,fs;reg [31:0] rng=32'hc1352e7f;wire ready=rng[2:0]!=0;
rfct_controller #(.CLOCK_HZ(1000000),.REG_DEBUG(1)) dut(
 .clk(clk),.rst(rst),.boot_id(boot),.link_up(1'b1),.startup_diagnostics(32'h90001f00),
 .command_uart(cmd[991-:8]==2&&uart_override),.reply_uart(),
 .command_valid(cv),.command_ready(cr),.command_bytes(cmd),.command_length(cl),
 .hdr_valid(hv),.hdr_ready(1'b1),.reply_length(len),.data(d),.valid(v),.ready(ready),.last(last),
 .radio_ready(rr),.radio_fault(rf),.radio_busy(rb),.radio_done(rd),.applied_mask(applied),.radio_fault_index(16'd0),
 .quad_warn(1'b1),.quad_mode(2'd3),
 .hardware_diagnostics({32'hc01dcafe,992'd0}),
 .radio_apply(apply),.gate_start(gate),.radio_lo(lo),.requested_mask(requested),.digital_mask(digital),
 .radio_rx_apply(rxapply),.radio_tx_apply(txapply),.radio_rx_lo(),
 .attenuation1(at1),.attenuation2(at2),.dsp_config(dsp),.dsp_toggle(tog),.dsp_ack(ack),
 .capture_run(run),.decimate25(dec),.capture_id(capture),.fs_eff_hz(fs),
 .packet_idle(!run),.fifo_points(32'd0),.sample_count(64'd4096),.datagrams(64'd16),
 .drop_windows(64'd0),.overflow_events(64'd0),.clip_count1(32'd0),.clip_count2(32'd0),.data_fault(df),
 .reg_start(regs_start),.reg_write(regs_write),.reg_address(regs_addr),.reg_wdata(regs_wdata),
 .reg_done(regs_done),.reg_rdata(regs_rdata));
// Fake AD9361 register file behind the bench-only 0x105 port.
reg [7:0] chip[0:1023];integer reg_ops=0,reg_wait=0;
reg [9:0] lat_addr;reg lat_write;reg [7:0] lat_data;
initial for(integer a=0;a<1024;a=a+1)chip[a]=a[7:0]^8'h3c;
always @(posedge clk)begin
 regs_done<=0;
 // Latch the request on reg_start, like ad9361_radio's single SPI transaction.
 if(regs_start)begin reg_wait<=20;reg_ops<=reg_ops+1;lat_addr<=regs_addr;lat_write<=regs_write;lat_data<=regs_wdata;end
 if(reg_wait>0)begin reg_wait<=reg_wait-1;
  if(reg_wait==1)begin regs_done<=1;regs_rdata<=chip[lat_addr];if(lat_write)chip[lat_addr]<=lat_data;end
 end
end
integer timer=0,applies=0,gates=0,responses=0;reg gate_pending=0;
always @(posedge clk)begin
 rng<={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};ack<=tog;rd<=0;
 if(apply||txapply||rxapply)begin timer<=600;applies<=applies+1;rr<=0;rf<=0;df<=0;rb<=1;gate_pending<=0;if(apply)applied<=0;end
 if(gate)begin timer<=80;gates<=gates+1;rb<=1;gate_pending<=1;end
 if(timer>0&&!hold)begin timer<=timer-1;
  if(timer==1)begin rr<=1;rb<=0;rd<=1;if(gate_pending)applied<=requested;end
 end
end
integer f;reg stalled=0;reg [7:0] old_d;reg old_last;
always @(posedge clk)begin
 if(stalled&&(d!=old_d||last!=old_last||!v))$fatal(1,"response changed under stall");
 stalled<=v&&!ready;old_d<=d;old_last<=last;
 if(v&&ready)begin $fwrite(f,"%02x",d);if(last)begin $fwrite(f,"\n");responses=responses+1;end end
end
initial begin f=$fopen("responses.hex","w");repeat(5)@(negedge clk);rst=0;
'''+''.join(blocks)+r'''
if(dut.rf_state!=0||dut.stage_id!=0)$fatal(1,"radio recovery left RX locked");
$fclose(f);$display("CONTROLLER CHECKS PASSED");$finish;
end
initial begin #10000000;$fatal(1,"controller timeout state=%d op=%d",dut.state,dut.operation);end
endmodule'''
# Release builds keep the bench-only 0x105 locked (enabled above only for this test).
_src=(R/'rtl/rfct_controller.sv').read_text(encoding='utf-8')
assert 'REG_DEBUG=0)(' in _src and 'REG_DEBUG' not in (R/'rtl/ku5p_top.sv').read_text(encoding='utf-8')
out=run_sim('controller',tb,design_sources(['rfct_controller']))
responses=[bytes.fromhex(x) for x in (out/'responses.hex').read_text().splitlines()]
for index,((request,status),p) in enumerate(zip(cases,responses,strict=True)):
    fields=struct.unpack_from('>4sBBHIIHHIII',p)
    assert fields[7]==status,(fields,status)
    assert fields[4:7]==struct.unpack_from('>4sBBHIIHHIII',request)[4:7]
    assert fields[9]==(0 if boot_failure_start<=index<boot_failure_start+6 else 42) and zlib.crc32(p[:28]+bytes(4)+p[32:])==fields[10]
    if p[4]==1 and fields[9]:decode_control(p)
    elif p[4]==1:assert len(p)==(64 if fields[6]==6 else 128)
    else:assert len(p)==160
assert responses[3]==responses[4] and responses[14]==responses[15]
running=decode_control(responses[5]).payload
assert running[0]==2 and struct.unpack_from('>I',running,4)[0]==1
assert struct.unpack_from('>I',responses[14],32+24)[0]==1
assert struct.unpack_from('>I',responses[16],32+24)[0]==2
assert struct.unpack_from('>I',responses[17],32+24)[0]==3
assert responses[23][32:]==bytes.fromhex('c01dcafe')+bytes(124)
failed=decode_control(responses[failed_reply]).payload
assert failed[0]==4 and struct.unpack_from('>I',failed,8)[0]==3
assert struct.unpack_from('>I',responses[boot_failure_start],64)[0]&32
assert struct.unpack_from('>I',responses[boot_failure_start+1],56)[0]==0x90001f00
# 0x105 result word: {'R',write,address,data}; read returns the value just written.
w,r,retry=(struct.unpack_from('>I',responses[reg_cases+k],32)[0] for k in range(3))
assert w==0x5280075a and r==0x5200075a and responses[reg_cases+1]==responses[reg_cases+2],(hex(w),hex(r))
assert struct.unpack_from('>I',responses[reg_cases+6],32)[0]==1  # other v2 replies keep schema 1
assert struct.unpack_from('>I',responses[boot_failure_start+1],32+16)[0]&0x200  # 0x104 advertises 0x105
# radio_flags (tx_snapshot word 8): bit 6 quad_warn, bits 8:7 quad_mode.
assert (struct.unpack_from('>I',responses[timeout_cases],32+32)[0]>>6)&7==0b111
(out/'result.json').write_text(json.dumps({'passed':True,'replies':len(responses),'identical_retries':True,'all_four_tx_states':True,'GET_STATUS_during_calibration':True,'fault_recovery':True,'startup_failure_diagnostics':True,'zero_epoch_no_effects':True,'hardware_verified':False},indent=2))

# Release (REG_DEBUG=0, default parameter): 0x105 over UART is UNSUPPORTED, no SPI,
# and 0x104 no longer advertises it.
locked_cases=[(v2(1,0x104),0),(v2(2,0x105,struct.pack('>HBB',0x007,1,0x11)),5),(v2(3,0x105,struct.pack('>HBB',0x007,0,0)),5)]
lb=''.join(f"""
    @(negedge clk);cmd=1024'h{p.ljust(128,bytes(1)).hex()};cl={len(p)};cv=1;
    do @(posedge clk);while(!cr);
    @(negedge clk);cv=0;wait(responses=={i+1});
    """ for i,(p,_) in enumerate(locked_cases))
tb_locked=tb.replace("rfct_controller #(.CLOCK_HZ(1000000),.REG_DEBUG(1)) dut(","rfct_controller #(.CLOCK_HZ(1000000)) dut(")
head,rest=tb_locked.split("initial begin f=$fopen",1)
tail='$fclose(f);'+rest.split('$fclose(f);',1)[1]
tb_locked=head+'initial begin f=$fopen("responses.hex","w");repeat(5)@(negedge clk);rst=0;\n'+lb+\
 '\nif(reg_ops!=0)$fatal(1,"locked 0x105 reached SPI");\n'+tail
tb_locked=tb_locked.replace('CONTROLLER CHECKS PASSED','CONTROLLER LOCKED CHECKS PASSED').replace('module tb_controller;','module tb_controller_locked;')
out=run_sim('controller_locked',tb_locked,design_sources(['rfct_controller']))
lr=[bytes.fromhex(x) for x in (out/'responses.hex').read_text().splitlines()]
assert [struct.unpack_from('>4sBBHIIHHIII',p)[7] for p in lr]==[s for _,s in locked_cases],lr
assert struct.unpack_from('>I',lr[0],32+4)[0]==23 and not struct.unpack_from('>I',lr[0],32+16)[0]&0x200
print('LOCKED BUILD: 0x105 refused (5), no SPI, version 23, discovery bit clear')
