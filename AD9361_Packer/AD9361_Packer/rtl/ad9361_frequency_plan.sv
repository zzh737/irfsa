// SPDX-License-Identifier: BSD-3-Clause
`timescale 1ns/1ps
// ADI RFPLL integer/fractional equations, fixed 40MHz XO and 80MHz PLL reference.
module ad9361_frequency_plan(
 input wire clk,rst,start,input wire [63:0] lo_hz,
 input wire use_fdd,
 output reg done,fault,output reg [143:0] values,output reg [1:0] band
);
 reg [3:0] state;reg [63:0] vco,num;reg [31:0] den;
 reg [3:0] divider;reg [15:0] integer_word;
 reg [22:0] fraction;reg [5:0] table_index;
 reg launch;wire div_done,div_busy;wire [63:0] quotient;wire [31:0] remainder;
 reg [87:0] vco_values[0:63],fdd_values[0:63];reg [15:0] thresholds[0:63];
 reg fdd_l;
 initial begin $readmemh("vco_values.mem",vco_values);$readmemh("vco_fdd_values.mem",fdd_values);$readmemh("vco_thresholds.mem",thresholds);end
 unsigned_divider divide(clk,rst,launch,num,den,div_done,div_busy,quotient,remainder);
 always @(posedge clk)begin
  done<=0;launch<=0;
  if(rst)begin state<=0;fault<=0;values<=0;band<=0;vco<=0;divider<=0;num<=0;den<=1;fdd_l<=0;end
  else case(state)
   0:if(start)begin
    if(lo_hz<64'd300000000||lo_hz>64'd6000000000)begin fault<=1;done<=1;end
    else begin
     vco<=lo_hz;divider<=4'hf;state<=1;fault<=0;fdd_l<=use_fdd;
     band <= lo_hz <= 64'd1300000000 ? 0 : (lo_hz <= 64'd4000000000 ? 1 : 2);
    end
   end
   1:if(vco<=64'd6000000000)begin vco<=vco<<1;divider<=divider+1;end
     else begin num<=vco;den<=80000000;launch<=1;state<=2;end
   2:if(div_done)begin integer_word<=quotient[15:0];num<=remainder*64'd8388593+64'd40000000;launch<=1;state<=3;end
   3:if(div_done)begin
    fraction<=quotient[22:0];table_index<=0;state<=4;
    if(quotient==8388593)begin fraction<=0;integer_word<=integer_word+1;end
   end
   4:if(table_index<52&&thresholds[table_index]*64'd1000000>vco)table_index<=table_index+1;
     else state<=5;
   5:begin
    values[87:0]<=fdd_l?fdd_values[table_index]:vco_values[table_index];
    values[95:88]<=fraction[7:0];values[103:96]<=fraction[15:8];values[111:104]<={1'b0,fraction[22:16]};
    values[119:112]<=integer_word[15:8];values[127:120]<=integer_word[7:0];
    values[135:128]<={4'b0,divider};values[143:136]<={divider,4'b0};
    done<=1;state<=0;
   end
   default:begin fault<=1;done<=1;state<=0;end
  endcase
 end
endmodule
