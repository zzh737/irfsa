"""UNISIM clock manager + differential DDR loopback; not an RF loopback test."""
from sim_utils import *
from source_manifest import design_sources
import json
tb=r'''~timescale 1ns/1ps
module tb_lvds;
reg refclk=0;always #5 refclk=~refclk;reg rst=1;
wire clk,reset,rv,fe,st;wire [47:0] iq;wire [5:0] dp,dn;
wire fp,fn,cp,cn;reg [47:0] tx=48'hfedcba987654;
// Source launches 1 ns after its edge; the FPGA supplies the fixed RX phase.
reg [5:0] rp;wire [5:0] rn=~rp;reg rfp;wire rfn=~rfp;
always @(dp)rp<=#1 dp;
always @(fp)rfp<=#1 fp;
ad9361_lvds dut(.reset_async(rst),.data_clk_p(refclk),.data_clk_n(!refclk),
 .rx_frame_p(rfp),.rx_frame_n(rfn),.rx_data_p(rp),.rx_data_n(rn),
 .fb_clk_p(cp),.fb_clk_n(cn),.tx_frame_p(fp),.tx_frame_n(fn),.tx_data_p(dp),.tx_data_n(dn),
 .clk(clk),.reset(reset),.rx_valid(rv),.frame_error(fe),.rx_iq(iq),
 .tx_iq(tx),.tx_valid(1'b1),.sample_strobe(st));
integer valid_count=0,errors=0;reg check_data=1;
realtime last_edge;
always @(posedge clk)last_edge=$realtime;
always @(negedge reset)if($time>100&&$realtime!=last_edge)
 $fatal(1,"reset released away from a destination rising edge");
always @(posedge clk)begin #1;
 if(check_data&&$time>15000&&!reset)begin
  if(rv)begin
   if(iq!==tx)$fatal(1,"physical DDR loopback word=%h expected=%h held=%h rise=%h fall=%h dp=%h rp=%h tr=%h tf=%h",iq,tx,dut.frame_core.held_tx,dut.rise,dut.fall,dp,rp,dut.dr,dut.df);
   valid_count=valid_count+1;
  end
  if(fe)errors=errors+1;
 end
end
initial begin
 #200;rst=0;#50000;
 if(valid_count<500||errors)$fatal(1,"LVDS count=%d errors=%d",valid_count,errors);
 check_data=0;
 // Stop the destination clock, then assert each source independently.
 // Preset assertion must not depend on a future destination edge.
 @(negedge clk);force dut.clock_raw=0;
 #2;rst=1;#0.1;if(!reset)$fatal(1,"external reset needs a running clock");
 #11;rst=0;#20;if(!reset)$fatal(1,"external reset released with clock stopped");
 release dut.clock_raw;wait(!reset);
 @(negedge clk);force dut.clock_raw=0;
 #2;force dut.clock_locked=0;
 #0.1;if(!reset)$fatal(1,"loss of lock needs a running clock");
 #11;force dut.clock_locked=1;
 #20;if(!reset)$fatal(1,"lock reset released with clock stopped");
 release dut.clock_raw;
 repeat(3)begin @(posedge clk);#0.1;if(!reset)$fatal(1,"lock reset released too early");end
 @(posedge clk);#0.1;if(reset)$fatal(1,"lock reset did not release after four edges");
 release dut.clock_locked;
 $display("LVDS CHECKS PASSED");$finish;
end
initial begin #200000;$fatal(1,"LVDS timeout");end
endmodule'''
out=run_sim('lvds',tb,design_sources(['ad9361_lvds']),unisim=True)
(out/'result.json').write_text(json.dumps(dict(passed=True,UNISIM_MMCM=True,differential_DDR_loopback=True,independent_reset_sources=True,assertion_with_clock_stopped=True,synchronous_four_edge_release=True,hardware_verified=False,RF_loopback=False),indent=2))
