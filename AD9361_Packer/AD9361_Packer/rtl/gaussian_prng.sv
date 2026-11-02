// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// xoshiro128** with a quantized inverse-CDF Gaussian transform (4096 bins).
// Independent nonzero states are used for each I/Q lane and each TX source.
module gaussian_prng #(parameter [31:0] LANE=1)(
 input wire clk,rst,input wire [31:0] seed,
 output wire [31:0] uniform_word,output reg signed [15:0] gaussian
);
 reg [31:0] a,b,c,d;
 reg signed [15:0] table_mem[0:4095];
 initial $readmemh("gaussian.mem",table_mem);
 wire [31:0] b5=b*32'd5;
 wire [31:0] result={b5[24:0],b5[31:25]}*32'd9;
 wire [31:0] next_d=d^b;
 assign uniform_word=result;
 always @(posedge clk)begin
  if(rst)begin
   a<=seed^(32'h9e3779b9*LANE);b<=32'h85ebca6b^LANE;
   c<=32'hc2b2ae35^(LANE<<16);d<=32'h27d4eb2f^seed^LANE;gaussian<=0;
  end else begin
   a<=a^next_d;b<=b^c^a;c<=c^a^(b<<9);d<={next_d[20:0],next_d[31:21]};
   gaussian<=table_mem[result[31:20]];
  end
 end
endmodule
