from sim_utils import *
from source_manifest import design_sources
import json
tb=r'''~timescale 1ns/1ps
module tb_radio_supervisor;
reg clk=0;always #4 clk=~clk;
reg rst=1,apply=0,gate=0,abort_now=0,rxapply=0,txapply=0;reg [63:0] lo=64'd2400000000,rxlo=64'd2400000000;
reg [1:0] mask=0;reg [8:0] a1=80,a2=120;wire ready,fault,done,busy,resetb,cs,sck,mosi;
reg [2:0] profile=7;reg [1:0] gainmode=0;reg signed [31:0] gain=10000;
reg rs=0,rw=0;reg [9:0] ra=0;reg [7:0] rwd=0;wire rdone;wire [7:0] rrd;
wire [1:0] applied;reg miso=0;
wire [15:0] fault_index;wire [7:0] rxdelay,txdelay;wire [4:0] phase;
wire [127:0] iface;wire qwarn;wire [1:0] qmode;wire [255:0] diag;
ad9361_radio dut(.clk(clk),.rst(rst),.apply(apply),.lo_hz(lo),.emergency_abort(abort_now),
 .rx_apply(rxapply),.rx_lo_hz(rxlo),.tx_apply(txapply),
 .rx_profile(profile),.rx_gain_mode(gainmode),.rx_gain_mdb(gain),
 .gate_start(gate),.requested_mask(mask),.attenuation1(a1),.attenuation2(a2),
 .reg_start(rs),.reg_write(rw),.reg_address(ra),.reg_wdata(rwd),.reg_done(rdone),.reg_rdata(rrd),
 .ready(ready),.fault(fault),.done(done),.busy(busy),.applied_mask(applied),
 .resetb(resetb),.spi_cs_n(cs),.spi_sclk(sck),.spi_mosi(mosi),.spi_miso(miso),
 .fault_index(fault_index),.rx_delay(rxdelay),.tx_delay(txdelay),.quad_phase(phase),.interface_registers(iface),
 .diagnostics(diag),.quad_warn(qwarn),.quad_mode(qmode));
reg [7:0] regs[0:1023];reg [15:0] header;integer bits=0;reg [7:0] rxbyte;
// Shorten only the fixed interface settling interval in simulation.
defparam dut.tuner.SETTLE_CYCLES=125;
// 50 ms per phase would take 6 M cycles per stuck run; 20 us keeps reason 1 real.
defparam dut.tuner.QUAD_CAL_TIMEOUT=2500;
reg fail_gate=0,fail_id=0;
// Quadrature model: quad_never = no phase converges; quad_stuck = cal-done never clears.
reg quad_never=0,quad_stuck=0;integer quad_runs=0;
// atten_ordered: the latest 0x07C[6] set closed a correctly ordered attenuation update.
reg atten_ordered=0,atten_open=0,order_ok=0,seen74=0,seen76=0,recovering=0,gain_write_in_alert=0;
reg agc_index_written=0;
function [7:0] readreg(input [9:0] addr);
 begin
  case(addr)
   10'h037:readreg=fail_id?8'hff:8'h0a;
   10'h017:readreg=(regs['h14][2]||(regs['h14][0]&&!(regs['h14]&8'h60)))?5:
    (regs['h14][5]?10:(regs['h14][6]?8:0));
   10'h05e,10'h244,10'h284:readreg=8'h80;
   10'h247,10'h287:readreg=2;
   10'h016:readreg=quad_stuck&&dut.tune_busy?8'h10:0;
   10'h1eb:readreg=32;10'h1ec:readreg=70;10'h1e6:readreg=5;
   10'h0a7,10'h0a8:readreg=!quad_never&&regs['ha0][4:0]>=8&&regs['ha0][4:0]<=19?3:0;
   10'h002:readreg=fail_gate?0:regs[addr];
   // In AGC the chip reports its live gain index, not the last written one (HW15: 0x28).
   10'h109:readreg=regs['hfa][1:0]!=0?8'h28:regs[addr];
   default:readreg=regs[addr];
  endcase
 end
endfunction
always @(negedge cs)begin bits=0;header=0;rxbyte=0;end
always @(posedge sck)if(!cs)begin
 if(bits>=16&&!header[15])miso=readreg(header[9:0])>>(23-bits);
 else miso=0;
end
always @(negedge sck)if(!cs)begin
 if(bits<16)header={header[14:0],mosi};
 else rxbyte={rxbyte[6:0],mosi};
 if(bits==23&&header[15])begin
  if(header[9:0]=='h016&&rxbyte==1&&(regs['h14]&8'h60))
   $fatal(1,"BBDC started outside ALERT");
  if(header[9:0]=='h016&&rxbyte==8'h10&&readreg(10'h017)!=5)
   $fatal(1,"TX quadrature calibration started outside ALERT");
  // ADI do_calib_run: RX BB/RF DC tracking is off and the quad setup is current.
  if(header[9:0]=='h016&&rxbyte==8'h10)begin quad_runs=quad_runs+1;
   if(regs['h18b]&8'h28)$fatal(1,"TX quadrature calibration with RX DC tracking on %h",regs['h18b]);
   if(dut.tx_script&&regs['haa]!=(dut.rx_lo_hz<=1300000000?8'h24:dut.rx_lo_hz<=4000000000?8'h25:8'h28))
    $fatal(1,"0x0AA %h does not follow RX LO %0d",regs['haa],dut.rx_lo_hz);
  end
  // ADI ad9361_set_tx_atten: clear 0x07C[6], write 0x074/0x076 before 0x073/0x075, set 0x07C[6].
  if(header[9:0]=='h07c&&!rxbyte[6])begin atten_open=1;order_ok=1;seen74=0;seen76=0;end
  if(header[9:0]=='h074)seen74=1;if(header[9:0]=='h076)seen76=1;
  if((header[9:0]=='h073&&(!atten_open||!seen74))||(header[9:0]=='h075&&(!atten_open||!seen76)))order_ok=0;
  if(header[9:0]=='h07c&&rxbyte[6])begin atten_ordered=atten_open&&order_ok;atten_open=0;end
  // The bw/gain script's runtime index write (the one HW14 lost) must land in FDD.
  // ADI init/retune traces also touch 0x109 inside their own calibrations.
  if(header[9:0]=='h109&&readreg(10'h017)==5&&dut.bw_script)gain_write_in_alert=1;
  // In AGC the gain script must leave 0x109 to the AGC; the RX retune trace
  // restores ADI's table index on its own (independent of gain mode).
  if(header[9:0]=='h109&&dut.bw_script&&gainmode!=0)agc_index_written=1;
  regs[header[9:0]]=rxbyte;
 end
 bits=bits+1;
end
task wait_ready;
 begin repeat(3)@(negedge clk);wait(ready||fault);#1;if(fault)$fatal(1,"init failed index=%d state=%d",fault_index,dut.state);end
endtask
task gate_mask(input [1:0] m);
 begin wait(!busy);@(negedge clk);mask=m;gate=1;@(negedge clk);gate=0;
 wait(done);#1;
 if(fault||applied!=m||regs[2]!=8'hdc)$fatal(1,"logical gate changed fixed 2R2T paths %d",m);
 if(regs[3]!=8'hdc||regs['h10]!=8'hcc)$fatal(1,"TX gate changed RX paths or pulse framing");
 if({regs['h74][0],regs['h73]}!=(m[0]?a1:9'd359))$fatal(1,"TX1 attenuation");
 if({regs['h76][0],regs['h75]}!=(m[1]?a2:9'd359))$fatal(1,"TX2 attenuation");
 if(!regs['h7c][6]||!atten_ordered)$fatal(1,"TX attenuation update order differs from ADI");
 end
endtask
// A radio fault inside the RX filter/gain script must not leave that script selected for re-init.
always @(posedge clk)if(recovering&&dut.state==2&&dut.bw_script)$fatal(1,"re-init would run the RX filter script");
integer j;
reg watch_live=0;
always @(negedge resetb)if(watch_live)$fatal(1,"live retune reset AD9361");
initial begin
 for(j=0;j<1024;j=j+1)regs[j]=0;
 repeat(5)@(negedge clk);rst=0;wait_ready();
 if(regs['h3d]!=0||regs['h3e]!=0||regs['h3f4]!=0||regs['h3f5]!=0||regs['h3f6]!=0)$fatal(1,"normal IQ interface not selected");
 if(applied!=0||regs[2]!=8'hdc||{regs['h74][0],regs['h73]}!=359||
    {regs['h76][0],regs['h75]}!=359)$fatal(1,"startup not muted with fixed 2R2T paths");
 if(iface[7:0]!=8'hdc||iface[15:8]!=8'h04||iface[23:16]!=8'h0a||
    iface[31:24]!=8'hcc||iface[47:40]!=8'h10||iface[79:72]!=8'h0a)
  $fatal(1,"read-only interface snapshot mismatch %h",iface);
 // Init: default 0x1F fails in the model (pass 8..19), search picks the centre.
 if(qwarn||qmode!=2||diag[255:224]!=32'h000fff00)$fatal(1,"init quad search warn=%d mode=%d map=%h",qwarn,qmode,diag[255:224]);
 if(phase!=14||rxdelay!=8'h04||txdelay!=8'h0a)$fatal(1,"fixed delay/quad phase %h %h %h",phase,rxdelay,txdelay);
 // Bench register access: write then read back 0x007 via one SPI each, no other side effects.
 wait(!busy);@(negedge clk);ra=10'h007;rwd=8'h5a;rw=1;rs=1;@(negedge clk);rs=0;wait(rdone);#1;
 if(regs[7]!=8'h5a||fault||!ready||applied!=0)$fatal(1,"register write");
 wait(!busy);@(negedge clk);ra=10'h007;rw=0;rs=1;@(negedge clk);rs=0;wait(rdone);#1;
 if(rrd!=8'h5a||regs[7]!=8'h5a||fault||!ready)$fatal(1,"register read %h",rrd);
 wait(!busy);@(negedge clk);ra=10'h007;rwd=8'h0a;rw=1;rs=1;@(negedge clk);rs=0;wait(rdone);#1;
 gate_mask(1);gate_mask(2);gate_mask(3);gate_mask(0);
 gate_mask(3);watch_live=1;
 wait(!busy);@(negedge clk);rxlo=915000000;rxapply=1;@(negedge clk);rxapply=0;
 wait(done);#1;if(fault||applied!=3||regs[2][7:6]!=3||regs[6]!=8'h04||regs[7]!=8'h0a)
  $fatal(1,"RX retune changed TX enables or LVDS");
 if(regs['h231]!=8'h5b||regs[5][3:0]!=2)$fatal(1,"RX frequency not applied: %h %h",regs['h231],regs[5]);
 gate_mask(0);
 wait(!busy);@(negedge clk);lo=915000000;txapply=1;@(negedge clk);txapply=0;
 wait(done);#1;if(fault||regs['h231]!=8'h5b||regs['h271]!=8'h5b||regs[5]!=8'h22||regs[6]!=8'h04||regs[7]!=8'h0a)
  $fatal(1,"TX live retune damaged RX frequency or interface");
 if(readreg(10'h017)!=10||regs['h14]!=8'h29||regs[2]!=8'hdc||regs[3]!=8'hdc)
  $fatal(1,"TX calibration did not restore fixed 2R2T FDD");
 if(regs['h18b]!=8'had||regs['h169]!=8'hcf)$fatal(1,"tracking not restored %h %h",regs['h18b],regs['h169]);
 if(qwarn||qmode!=1)$fatal(1,"converging retune reported warn=%d mode=%d",qwarn,qmode);
 // Calibration at the last good phase: no search, no warning.
 quad_runs=0;wait(!busy);@(negedge clk);lo=64'd2420000000;txapply=1;@(negedge clk);txapply=0;
 wait(done);#1;if(fault||qwarn||qmode!=1||quad_runs!=2)$fatal(1,"last-phase retry runs=%0d mode=%d",quad_runs,qmode);
 // HW18: no phase converges at 2420/3500 MHz. ADI keeps going with a warning;
 // the chip must not be reset and the TX gate must be restorable.
 quad_never=1;quad_runs=0;
 wait(!busy);@(negedge clk);lo=64'd3500000000;txapply=1;@(negedge clk);txapply=0;
 wait(done);#1;
 if(fault||!resetb||!ready||!qwarn||qmode!=3||phase!=5'h1f||quad_runs!=35)
  $fatal(1,"non-converging TX quad cal fault=%d warn=%d mode=%d phase=%d runs=%0d",fault,qwarn,qmode,phase,quad_runs);
 if(diag[255:224]!=0||diag[215:208]!={5'h1f,2'd3,1'b1}||diag[63:48]!=0)$fatal(1,"quad diagnostics %h",diag[255:192]);
 if(readreg(10'h017)!=10||regs['h18b]!=8'had)$fatal(1,"FDD/tracking not restored after warning");
 gate_mask(3);quad_never=0;
 wait(!busy);@(negedge clk);lo=915000000;txapply=1;@(negedge clk);txapply=0;
 wait(done);#1;if(fault||qwarn)$fatal(1,"warning not cleared by a converging calibration");
 gate_mask(3);watch_live=0;
 for(j=0;j<8;j=j+1)begin
  wait(!busy);@(negedge clk);profile=j;gainmode=j%3;gain=20000;agc_index_written=0;gain_write_in_alert=0;rxapply=1;@(negedge clk);rxapply=0;
  wait(done);#1;
  if(fault||readreg(10'h017)!=10||regs[2]!=8'hdc||regs[3]!=8'hdc||applied!=3)
   $fatal(1,"RX filter/gain changed paths or failed profile=%d",j);
  if(regs['hfa][1:0]!=(gainmode==1?2:gainmode==2?1:0))$fatal(1,"AGC mode");
  // MGC sets the index (20 dB at 915 MHz = 23); AGC modes leave 0x109 untouched.
  if(gainmode==0&&regs['h109][6:0]!=23)$fatal(1,"manual gain index %d j=%d lo=%d",regs['h109][6:0],j,rxlo);
  if(gainmode!=0&&agc_index_written)$fatal(1,"AGC mode wrote the manual gain index from the gain script");
  // 0x109 is written after leaving ALERT (FDD), as ad9361_set_rx_gain() does.
  if(gain_write_in_alert)$fatal(1,"manual gain index written in ALERT");
  if(regs['h1f8]!=(j==0?60:j==1?253:j==2?127:j==3?64:j==4?26:j==5?13:j==6?9:7))
   $fatal(1,"RX BW divider profile=%d value=%d",j,regs['h1f8]);
 end
 // Lowest manual gain at 915 MHz is -1 dB = table index 2 (must stay signed).
 wait(!busy);@(negedge clk);profile=7;gainmode=0;gain=-1000;rxapply=1;@(negedge clk);rxapply=0;
 wait(done);#1;if(fault||regs['h109][6:0]!=2)$fatal(1,"negative manual gain index %d",regs['h109][6:0]);
 // Abort inside the RX filter/gain script, then recover with a full apply.
 wait(!busy);@(negedge clk);profile=3;gain=20000;rxapply=1;@(negedge clk);rxapply=0;
 wait(dut.bw_script);@(negedge clk);abort_now=1;@(negedge clk);abort_now=0;#1;
 if(!fault)$fatal(1,"abort inside RX filter script");
 recovering=1;@(negedge clk);apply=1;@(negedge clk);apply=0;wait_ready();recovering=0;
 gate_mask(3);
 wait(!busy);@(negedge clk);profile=2;gainmode=1;rxapply=1;@(negedge clk);rxapply=0;wait(done);
 wait(!busy);@(negedge clk);lo=64'd2400000000;txapply=1;@(negedge clk);txapply=0;wait(done);#1;
 if(fault||regs['h1f8]!=127||regs['hfa][1:0]!=2||regs[2]!=8'hdc||regs[3]!=8'hdc||applied!=3)
  $fatal(1,"TX calibration restore fault=%d index=%d bw=%d agc=%h tx=%h rx=%h applied=%d",fault,fault_index,regs['h1f8],regs['hfa],regs[2],regs[3],applied);
 wait(!busy);@(negedge clk);mask=3;gate=1;fail_gate=1;@(negedge clk);gate=0;
 wait(fault);#1;if(resetb||applied!=0||ready)$fatal(1,"readback failure did not mute/reset");
 fail_gate=0;@(negedge clk);apply=1;@(negedge clk);apply=0;wait_ready();
 @(negedge clk);abort_now=1;@(negedge clk);abort_now=0;
 #1;if(!fault||ready||resetb||applied!=0)$fatal(1,"emergency abort");
 // A calibration engine that never finishes is still fatal (reason 1).
 fail_gate=0;@(negedge clk);apply=1;@(negedge clk);apply=0;wait_ready();
 wait(!busy);@(negedge clk);quad_stuck=1;lo=64'd2400000000;txapply=1;@(negedge clk);txapply=0;
 wait(fault);#1;quad_stuck=0;
 if(resetb||ready||diag[31:28]!=1)$fatal(1,"stuck TX quad cal reason=%d resetb=%d",diag[31:28],resetb);
 $display("RADIO SUPERVISOR CHECKS PASSED");$finish;
end
initial begin #1000000000;$fatal(1,"radio timeout state=%d index=%d",dut.state,dut.index);end
endmodule'''
out=run_sim('radio_supervisor',tb,design_sources(['ad9361_radio']))
(out/'result.json').write_text(json.dumps({'passed':True,'behavioral_spi_init':True,'fixed_delays':{'rx':'0x04','tx':'0x0a'},'no_pn_ack_required':True,'all_tx_masks':True,'readback_failure_mutes':True,'live_rx_retune_preserves_tx':True,'live_tx_retune_preserves_rx':True,'hardware_verified':False},indent=2))
