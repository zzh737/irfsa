"""Exercise a calibration lasting over 1 s and a permanently busy calibration.

Advance only the elapsed-time counter to avoid simulating 3 billion clocks;
SPI transfers, status polling, timeout decisions and reset behavior stay real.
"""
from sim_utils import *
from source_manifest import design_sources
import json

words=[int(x,16) for x in (R/'rtl/rom/radio_init.mem').read_text().split()]
bbdc=next(i for i,w in enumerate(words[:2048]) if w>>60==1 and (w>>48)&1023==0x16 and (w>>40)&255==1)
poll=words[bbdc+1]
assert (words[bbdc-1]>>48)&1023==0x17 and (words[bbdc-1]>>40)&255==5
assert poll>>60==2 and poll&0xffffffff==3000000000

tb=r'''~timescale 1ns/1ps
module tb_calibration_timeout;
reg clk=0;always #4 clk=~clk;
reg rst=1;wire ready,fault,done,busy,resetb,cs,sck,mosi;wire [1:0] applied;
reg miso=0,cal_busy=1;integer bits=0;reg [15:0] header;
ad9361_radio dut(.clk(clk),.rst(rst),.apply(1'b0),.lo_hz(64'd2400000000),
 .emergency_abort(1'b0),.rx_apply(1'b0),.rx_lo_hz(64'd2400000000),.tx_apply(1'b0),
 .gate_start(1'b0),.requested_mask(2'd0),.attenuation1(9'd359),.attenuation2(9'd359),
 .ready(ready),.fault(fault),.done(done),.busy(busy),.applied_mask(applied),
 .resetb(resetb),.spi_cs_n(cs),.spi_sclk(sck),.spi_mosi(mosi),.spi_miso(miso),
 .result_toggle(1'b0),.measure_passed(1'b0));
always @(negedge cs)begin bits=0;header=0;end
always @(posedge sck)if(!cs)miso=bits==23&&!header[15]?cal_busy:0;
always @(negedge sck)if(!cs)begin
 if(bits<16)header={header[14:0],mosi};bits=bits+1;
end
task start_case;
 begin
 @(negedge clk);rst=1;repeat(4)@(negedge clk);rst=0;
 wait(dut.state==1);force dut.timer=0;
 wait(dut.state==3);@(negedge clk);release dut.timer;
 dut.qualified=15;
 end
endtask
integer bank;
initial begin
 #1;
 for(bank=0;bank<3;bank=bank+1)begin
  dut.rom[bank*2048]=64'h101601ff00000000;
  dut.rom[bank*2048+1]=64'h20160001b2d05e00;
  dut.rom[bank*2048+2]=64'hf000000000000000;
 end
 start_case();
 wait(dut.index==1&&dut.state==7);@(negedge clk);dut.elapsed=125000001;
 wait(dut.index==1&&dut.state==6);@(negedge clk);
 if(fault||!resetb)$fatal(1,"calibration was rejected at the old 1 s limit");
 cal_busy=0;wait(ready||fault);#1;
 if(fault||!ready)$fatal(1,"late calibration completion failed");
 cal_busy=1;start_case();
 wait(dut.index==1&&dut.state==7);@(negedge clk);dut.elapsed=3000000001;
 wait(fault);#1;
 if(ready||resetb||applied!=0)$fatal(1,"stuck calibration did not fail closed");
 $display("CALIBRATION TIMEOUT CHECKS PASSED");$finish;
end
initial begin #2000000;$fatal(1,"calibration test timed out");end
endmodule'''
out=run_sim('calibration_timeout',tb,design_sources(['ad9361_radio']))
(out/'result.json').write_text(json.dumps(dict(passed=True,alert_checked_before_bbdc=True,
    completion_after_old_limit=True,stuck_calibration_resets=True,hardware_verified=False),indent=2))
