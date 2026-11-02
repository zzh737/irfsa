`timescale 1ns/1ps
module hdmi_tx(input wire pixel_clk,serial_clk,rst,de,hsync,vsync,
 input wire [23:0] rgb,output wire HDMI_CLK_P,HDMI_CLK_N,
 output wire [2:0] HDMI_TX_P,HDMI_TX_N);
 // Candidate: use the delivered encoder/serializer that passed the independent
 // board color-bar test. Product integration still requires board acceptance.
 uihdmitx #(.FAMILY("7FAMILY")) vendor_tx(
  .RSTn_i(!rst),.HS_i(hsync),.VS_i(vsync),.VDE_i(de),.RGB_i(rgb),
  .PCLKX1_i(pixel_clk),.PCLKX2_5_i(1'b0),.PCLKX5_i(serial_clk),
  .TMDS_TX_CLK_P(HDMI_CLK_P),.TMDS_TX_CLK_N(HDMI_CLK_N),
  .TMDS_TX_P(HDMI_TX_P),.TMDS_TX_N(HDMI_TX_N));
endmodule
