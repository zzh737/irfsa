// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
module ad9361_lvds(
 input wire reset_async,
 input wire data_clk_p,data_clk_n,rx_frame_p,rx_frame_n,
 input wire [5:0] rx_data_p,rx_data_n,
 output wire fb_clk_p,fb_clk_n,tx_frame_p,tx_frame_n,
 output wire [5:0] tx_data_p,tx_data_n,
 output wire clk,reset,rx_valid,frame_error,output wire [47:0] rx_iq,
 input wire [47:0] tx_iq,input wire tx_valid,output wire sample_strobe,
 output wire clock_is_locked,reset_source,unlock_source,
 output wire [1:0] rx_frame_pair
);
 wire clock_input,frame_input;wire [5:0] data_input,rise,fall;
 wire clock_raw,tx_clock_raw,tx_clock,clock_fb_raw,clock_fb,clock_locked;
 wire fr,ff;wire [5:0] dr,df;wire tf,frame_ddr,fb_ddr;wire [5:0] data_ddr;
 assign rx_frame_pair={fr,ff};
 IBUFDS #(.DIFF_TERM("TRUE")) clock_ibuf(.I(data_clk_p),.IB(data_clk_n),.O(clock_input));
 assign clock_is_locked=clock_locked;
 // Fixed sampling phase, no training. The selected 25 MSPS 2R2T profile
 // supplies a 100 MHz DATA_CLK (one DDR slot = 5 ns = 180 degrees).
 // HW14 board capture at 90 degrees: the edge sat on the data transition
 // (10-50 % per-lane bit errors, Q bits near-random), i.e. data arrives
 // later than the 0..1 ns budget once 0x006=0x04 Rx data delay is added.
 // The board eye centre is therefore ~180 degrees. Routed STA with the
 // datasheet window (tDDRx 0.25..1.25 ns, no 0x006 delay) centres at ~150.
 // 166.5 degrees (VCO 1 GHz / 10 -> 4.5 degree steps) keeps >1 ns STA margin
 // on both sides and ~0.4 ns from the measured board centre.
 MMCME4_BASE #(.CLKIN1_PERIOD(10.0),.CLKFBOUT_MULT_F(10.0),
  .CLKOUT0_DIVIDE_F(10.0),.CLKOUT0_PHASE(166.5),
  .CLKOUT1_DIVIDE(10),.CLKOUT1_PHASE(0.0),
  .DIVCLK_DIVIDE(1),.STARTUP_WAIT("FALSE")) rx_mmcm(
  .CLKIN1(clock_input),.CLKFBIN(clock_fb),.CLKFBOUT(clock_fb_raw),
  .CLKOUT0(clock_raw),.CLKOUT1(tx_clock_raw),
  .LOCKED(clock_locked),.RST(reset_async),.PWRDWN(1'b0));
 BUFG feedback_buf(.I(clock_fb_raw),.O(clock_fb));
 BUFG clock_buf(.I(clock_raw),.O(clk));
 // Keep TX data and the returned FB_CLK on their original zero-degree phase.
 // The frame core uses the related 90-degree clock; STA checks this transfer.
 BUFG tx_clock_buf(.I(tx_clock_raw),.O(tx_clock));
 // Synchronize each reset source before combining them. Both paths assert
 // without a running DATA_CLK and release only on destination clock edges.
 // Combining asynchronous sources before a synchronizer obscures its CDC
 // structure and puts combinational logic on the synchronizer's preset.
 (* ASYNC_REG="TRUE", SHREG_EXTRACT="NO" *)reg [3:0] reset_pipe=15;
 (* ASYNC_REG="TRUE", SHREG_EXTRACT="NO" *)reg [3:0] unlock_pipe=15;
 always @(posedge clk or posedge reset_async)
  if(reset_async)reset_pipe<=15;else reset_pipe<={reset_pipe[2:0],1'b0};
 always @(posedge clk or negedge clock_locked)
  if(!clock_locked)unlock_pipe<=15;else unlock_pipe<={unlock_pipe[2:0],1'b0};
 assign reset=reset_pipe[3]||unlock_pipe[3];
 assign reset_source=reset_pipe[3];assign unlock_source=unlock_pipe[3];
 IBUFDS #(.DIFF_TERM("TRUE")) frame_ibuf(.I(rx_frame_p),.IB(rx_frame_n),.O(frame_input));
 IDDRE1 #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),.IS_CB_INVERTED(1'b1)) frame_iddr(
 .C(clk),.CB(clk),.R(reset),.D(frame_input),.Q1(fr),.Q2(ff));
 genvar k;
 generate for(k=0;k<6;k=k+1)begin:g
  IBUFDS #(.DIFF_TERM("TRUE")) data_ibuf(.I(rx_data_p[k]),.IB(rx_data_n[k]),.O(data_input[k]));
  IDDRE1 #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),.IS_CB_INVERTED(1'b1)) data_iddr(
   .C(clk),.CB(clk),.R(reset),.D(data_input[k]),.Q1(rise[k]),.Q2(fall[k]));
  ODDRE1 data_oddr(.C(tx_clock),.D1(dr[k]),.D2(df[k]),.SR(reset),.Q(data_ddr[k]));
  OBUFDS data_obuf(.I(data_ddr[k]),.O(tx_data_p[k]),.OB(tx_data_n[k]));
 end endgenerate
 ODDRE1 frame_oddr(.C(tx_clock),.D1(tf),.D2(tf),.SR(reset),.Q(frame_ddr));
 OBUFDS frame_obuf(.I(frame_ddr),.O(tx_frame_p),.OB(tx_frame_n));
 ODDRE1 clock_oddr(.C(tx_clock),.D1(1'b1),.D2(1'b0),.SR(reset),.Q(fb_ddr));
 OBUFDS clock_obuf(.I(fb_ddr),.O(fb_clk_p),.OB(fb_clk_n));
 ad9361_frame_core frame_core(clk,reset,rise,fall,{fr,ff},rx_valid,rx_iq,frame_error,
  tx_iq,tx_valid,sample_strobe,dr,df,tf);
endmodule
