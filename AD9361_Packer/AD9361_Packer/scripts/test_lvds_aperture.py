"""Independent 2R2T source with output delay, not an FPGA TX/RX loopback."""
from sim_utils import run_sim
from source_manifest import design_sources
import json

tb=r'''~timescale 1ns/1ps
module tb_lvds_aperture;
reg refclk=0;always #5 refclk=~refclk;
reg rst=1;reg [1:0] phase=0;
reg [5:0] rx=0;reg frame=0;
wire clk,reset,rv,fe,st;wire [47:0] iq;
wire [5:0] dp,dn;wire fp,fn,cp,cn;
localparam [47:0] EXPECTED=48'h123456789abc;
reg [5:0] rising_data,falling_data;
always @* case(phase)
 0:begin rising_data=EXPECTED[23:18];falling_data=EXPECTED[11:6];end
 1:begin rising_data=EXPECTED[17:12];falling_data=EXPECTED[5:0];end
 2:begin rising_data=EXPECTED[47:42];falling_data=EXPECTED[35:30];end
 3:begin rising_data=EXPECTED[41:36];falling_data=EXPECTED[29:24];end
endcase
// AD9361 launches data after each DATA_CLK edge. The current XDC assumes
// 0..1 ns output/board delay; 1 ns is a deterministic test of that budget.
always @(posedge refclk)begin rx<=#1 rising_data;frame<=#1 !phase[1];end
always @(negedge refclk)begin rx<=#1 falling_data;phase<=phase+1;end
ad9361_lvds dut(.reset_async(rst),.data_clk_p(refclk),.data_clk_n(!refclk),
 .rx_frame_p(frame),.rx_frame_n(!frame),.rx_data_p(rx),.rx_data_n(~rx),
 .fb_clk_p(cp),.fb_clk_n(cn),.tx_frame_p(fp),.tx_frame_n(fn),.tx_data_p(dp),.tx_data_n(dn),
 .clk(clk),.reset(reset),.rx_valid(rv),.frame_error(fe),.rx_iq(iq),
 .tx_iq(EXPECTED),.tx_valid(1'b1),.sample_strobe(st));
integer count=0,errors=0,mismatch=0;
// Independent AD9361 TX receiver: fixed internal FB_CLK delay, no use of
// the FPGA decoder or its private phase signals to validate the wire data.
reg [5:0] tx_rising;reg tx_fr;
reg [47:0] tx_word=0;integer tx_phase=4,tx_count=0,tx_errors=0;
always @(posedge cp)begin #2.5;tx_rising=dp;tx_fr=fp;end
always @(negedge cp)begin #2.5;
 if(!reset&&$time>15000)begin
  if(tx_fr!==fp)begin tx_errors=tx_errors+1;tx_phase=4;end
  else case(tx_phase)
   4:if(!fp)tx_phase=5;
   5:if(fp)begin tx_word[23:18]=tx_rising;tx_word[11:6]=dp;tx_phase=1;end
   1:if(fp)begin tx_word[17:12]=tx_rising;tx_word[5:0]=dp;tx_phase=2;end
     else begin tx_errors=tx_errors+1;tx_phase=4;end
   2:if(!fp)begin tx_word[47:42]=tx_rising;tx_word[35:30]=dp;tx_phase=3;end
     else begin tx_errors=tx_errors+1;tx_phase=4;end
   3:if(!fp)begin
      tx_word[41:36]=tx_rising;tx_word[29:24]=dp;
      if(tx_word!==EXPECTED)tx_errors=tx_errors+1;
      tx_count=tx_count+1;tx_phase=5;
     end else begin tx_errors=tx_errors+1;tx_phase=4;end
  endcase
 end
end
always @(posedge clk)begin #1;
 if(!reset&&$time>15000)begin
  if(fe)errors=errors+1;
  if(rv)begin count=count+1;if(iq!==EXPECTED)mismatch=mismatch+1;end
 end
end
initial begin
 #200;rst=0;#50000;
 $display("APERTURE result count=%0d frame_errors=%0d mismatch=%0d",count,errors,mismatch);
 if(count<500||mismatch)$fatal(1,"Independent source did not produce correct IQ");
 $display("TX APERTURE result count=%0d errors=%0d",tx_count,tx_errors);
 if(tx_count<500||tx_errors)$fatal(1,"Independent TX receiver did not decode correct IQ");
 $display("APERTURE PASSED");$finish;
end
endmodule'''
out=run_sim('lvds_aperture',tb,design_sources(['ad9361_lvds']),unisim=True)
(out/'result.json').write_text(json.dumps(dict(passed=True,independent_RX_source=True,
    independent_TX_receiver=True,source_output_delay_ns=1.0,TX_aperture_delay_ns=2.5,
    RX_sampling_phase_deg=90,TX_clock_phase_deg=0,hardware_verified=False),indent=2))
