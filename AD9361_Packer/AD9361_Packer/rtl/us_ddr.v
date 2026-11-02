// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Interface-compatible UltraScale+ replacements for verilog-ethernet wrappers.
module iddr #(parameter TARGET="XILINX", IODDR_STYLE="IODDR", WIDTH=1)
 (input wire clk, input wire [WIDTH-1:0] d,
  output wire [WIDTH-1:0] q1,q2);
 genvar k;
 generate for(k=0;k<WIDTH;k=k+1) begin:g
   IDDRE1 #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),.IS_CB_INVERTED(1'b1))
   ff(.C(clk),.CB(clk),.R(1'b0),.D(d[k]),.Q1(q1[k]),.Q2(q2[k]));
 end endgenerate
endmodule
module oddr #(parameter TARGET="XILINX", IODDR_STYLE="IODDR", WIDTH=1)
 (input wire clk, input wire [WIDTH-1:0] d1,d2, output wire [WIDTH-1:0] q);
 genvar k;
 generate for(k=0;k<WIDTH;k=k+1) begin:g
   ODDRE1 ff(.C(clk),.D1(d1[k]),.D2(d2[k]),.SR(1'b0),.Q(q[k]));
 end endgenerate
endmodule
