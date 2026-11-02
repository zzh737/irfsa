`timescale 1ns/1ps
// 7-series style primitives are used by the vendor's mapped 30TAI flow.
module tmds_serializer(input wire pixel_clk,serial_clk,rst,
 input wire [9:0] word_in, output wire tx_p,tx_n);
 wire shift1,shift2,serial;
 OSERDESE2 #(.DATA_RATE_OQ("DDR"),.DATA_RATE_TQ("SDR"),.DATA_WIDTH(10),
   .SERDES_MODE("MASTER"),.TRISTATE_WIDTH(1)) master (
   .CLK(serial_clk),.CLKDIV(pixel_clk),.RST(rst),.OCE(1'b1),
   .D1(word_in[0]),.D2(word_in[1]),.D3(word_in[2]),.D4(word_in[3]),
   .D5(word_in[4]),.D6(word_in[5]),.D7(word_in[6]),.D8(word_in[7]),
   .SHIFTIN1(shift1),.SHIFTIN2(shift2),.SHIFTOUT1(),.SHIFTOUT2(),.OQ(serial),
   .T1(1'b0),.T2(1'b0),.T3(1'b0),.T4(1'b0),.TCE(1'b0),.TBYTEIN(1'b0),
   .OFB(),.TQ(),.TFB(),.TBYTEOUT());
 OSERDESE2 #(.DATA_RATE_OQ("DDR"),.DATA_RATE_TQ("SDR"),.DATA_WIDTH(10),
   .SERDES_MODE("SLAVE"),.TRISTATE_WIDTH(1)) slave (
   .CLK(serial_clk),.CLKDIV(pixel_clk),.RST(rst),.OCE(1'b1),
   .D1(1'b0),.D2(1'b0),.D3(word_in[8]),.D4(word_in[9]),
   .D5(1'b0),.D6(1'b0),.D7(1'b0),.D8(1'b0),
   .SHIFTIN1(1'b0),.SHIFTIN2(1'b0),.SHIFTOUT1(shift1),.SHIFTOUT2(shift2),.OQ(),
   .T1(1'b0),.T2(1'b0),.T3(1'b0),.T4(1'b0),.TCE(1'b0),.TBYTEIN(1'b0),
   .OFB(),.TQ(),.TFB(),.TBYTEOUT());
 OBUFDS #(.IOSTANDARD("TMDS_33")) out_buf(.I(serial),.O(tx_p),.OB(tx_n));
endmodule
