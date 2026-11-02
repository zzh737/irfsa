// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// RGMII source-synchronous input clock path.
//
// The previous version forced the RX clock through an MMCM programmed for
// 125 MHz.  That made the receiver effectively gigabit-only: when the PHY
// negotiated 100 Mbps, RGMII supplied a 25 MHz clock and the fixed MMCM
// could not provide a valid clock for the IDDR/MAC path.  RGMII already
// provides a source-synchronous clock, so pass it through a BUFG.  This is
// also the implementation used by the upstream verilog-ethernet wrapper and
// supports the 10/100/1000 Mbps clock rates selected by the MAC.
//
// The BUFG insertion delay is not compensated, so at 125 MHz the IDDR clock
// arrives late and the PHY's next DDR transition violates hold.  Each data
// input therefore passes a fixed, VT-compensated IDELAYE3 (TIME mode; needs
// the IDELAYCTRL in ku5p_top).  DATA_DELAY_PS is chosen by STA against the
// RGMII v2.0 receiver budget in ku5p_timing.xdc together with the
// USER_CLOCK_ROOT set in ku5p_post_opt.tcl; change them together.
module ssio_ddr_in #(
 parameter TARGET="XILINX",IODDR_STYLE="IODDR",CLOCK_INPUT_STYLE="BUFG",WIDTH=1,
 // 2026-10-27 GUI impl (root X0Y1): 600 ps gave hold -0.097 / setup +0.356;
 // the ~0.26 ns total window is centred near 780 ps.
 parameter integer DATA_DELAY_PS=780,
 parameter real REFCLK_MHZ=333.333
)(input wire input_clk,input wire [WIDTH-1:0] input_d,
 output wire output_clk,output wire [WIDTH-1:0] output_q1,output_q2);
 wire clk_buf;wire [WIDTH-1:0] delayed;
 BUFG input_buf(.I(input_clk),.O(clk_buf));
 assign output_clk=clk_buf;
 genvar k;
 generate for(k=0;k<WIDTH;k=k+1)begin:dly
  IDELAYE3 #(.CASCADE("NONE"),.DELAY_FORMAT("TIME"),.DELAY_SRC("IDATAIN"),.DELAY_TYPE("FIXED"),
   .DELAY_VALUE(DATA_DELAY_PS),.REFCLK_FREQUENCY(REFCLK_MHZ),.SIM_DEVICE("ULTRASCALE_PLUS"),
   .UPDATE_MODE("ASYNC"),.IS_CLK_INVERTED(1'b0),.IS_RST_INVERTED(1'b0)) data_delay(
   .IDATAIN(input_d[k]),.DATAOUT(delayed[k]),.DATAIN(1'b0),.CASC_IN(1'b0),.CASC_RETURN(1'b0),.CASC_OUT(),
   .CLK(1'b0),.CE(1'b0),.INC(1'b0),.LOAD(1'b0),.CNTVALUEIN(9'd0),.CNTVALUEOUT(),.EN_VTC(1'b1),.RST(1'b0));
 end endgenerate
 iddr #(.TARGET(TARGET),.IODDR_STYLE(IODDR_STYLE),.WIDTH(WIDTH))
  data_iddr_inst(.clk(clk_buf),.d(delayed),.q1(output_q1),.q2(output_q2));
endmodule
