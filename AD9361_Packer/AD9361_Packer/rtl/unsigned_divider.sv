// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
module unsigned_divider(
 input wire clk,rst,start,input wire [63:0] numerator,input wire [31:0] denominator,
 output reg done,busy,output reg [63:0] quotient,output reg [31:0] remainder
);
 reg [63:0] q;reg [32:0] r;reg [31:0] d;reg [6:0] count;
 wire [32:0] shifted={r[31:0],q[63]};
 wire subtract=shifted>={1'b0,d};
 wire [32:0] next_r=subtract?shifted-{1'b0,d}:shifted;
 wire [63:0] next_q={q[62:0],subtract};
 always @(posedge clk)begin
  done<=0;
  if(rst)begin busy<=0;quotient<=0;remainder<=0;q<=0;r<=0;d<=0;count<=0;end
  else if(start&&!busy)begin busy<=1;q<=numerator;r<=0;d<=denominator;count<=0;end
  else if(busy)begin
   q<=next_q;r<=next_r;count<=count+1;
   if(count==63)begin quotient<=next_q;remainder<=next_r[31:0];busy<=0;done<=1;end
  end
 end
endmodule
