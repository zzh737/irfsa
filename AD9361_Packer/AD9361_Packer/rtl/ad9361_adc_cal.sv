// SPDX-License-Identifier: BSD-3-Clause
// Specialized from Analog Devices no-OS ad9361.c ADC and TIA calibration.
`timescale 1ns/1ps
module ad9361_adc_cal(
 input wire clk,rst,start,input wire tia_only,input wire [2:0] profile,
 output reg done,fault,output wire busy,
 output reg spi_start,spi_write,output reg [9:0] spi_address,
 output reg [7:0] spi_write_data,input wire spi_done,input wire [7:0] spi_read_data
);
 reg [3:0] state;reg [5:0] index;
 reg [7:0] c3_msb,c3_lsb,r2346;
 reg [12:0] product;
 (* rom_style="block" *) reg [119:0] table_mem[0:65535];
 initial $readmemh("rx_cal_profiles.mem",table_mem);
 reg [119:0] table_data;
 reg [2:0] profile_l;
 reg [7:0] coefficient;
 always @* begin
  coefficient=0;
  case(index)
   6'd0:coefficient=8'h00;
   6'd1:coefficient=8'h00;
   6'd2:coefficient=8'h00;
   6'd3:coefficient=8'h24;
   6'd4:coefficient=8'h24;
   6'd5:coefficient=8'h00;
   6'd6:coefficient=8'h00;
   6'd7:coefficient=table_data[0+:8];
   6'd8:coefficient=table_data[8+:8];
   6'd9:coefficient=table_data[16+:8];
   6'd10:coefficient=table_data[24+:8];
   6'd11:coefficient=table_data[32+:8];
   6'd12:coefficient=table_data[40+:8];
   6'd13:coefficient=table_data[48+:8];
   6'd14:coefficient=8'h00;
   6'd15:coefficient=table_data[56+:8];
   6'd16:coefficient=table_data[64+:8];
   6'd17:coefficient=table_data[56+:8];
   6'd18:coefficient=table_data[72+:8];
   6'd19:coefficient=table_data[80+:8];
   6'd20:coefficient=table_data[72+:8];
   6'd21:coefficient=table_data[88+:8];
   6'd22:coefficient=table_data[96+:8];
   6'd23:coefficient=table_data[88+:8];
   6'd24:coefficient=8'h2e;
   6'd25:coefficient=8'h93;
   6'd26:coefficient=8'h16;
   6'd27:coefficient=8'h11;
   6'd28:coefficient=8'h93;
   6'd29:coefficient=8'h16;
   6'd30:coefficient=8'h11;
   6'd31:coefficient=8'h93;
   6'd32:coefficient=8'h16;
   6'd33:coefficient=8'h23;
   6'd34:coefficient=8'h23;
   6'd35:coefficient=8'h40;
   6'd36:coefficient=8'h40;
   6'd37:coefficient=8'h2c;
   6'd38:coefficient=8'h00;
   6'd39:coefficient=8'h00;
   6'd40:coefficient=(profile_l<5?8'he0:8'h60);
   6'd41:coefficient=table_data[104+:8];
   6'd42:coefficient=table_data[112+:8];
   6'd43:coefficient=table_data[104+:8];
   6'd44:coefficient=table_data[112+:8];
  endcase
 end
 always @(posedge clk)table_data<=table_mem[{profile_l,product}];
 assign busy=state!=0;
 always @(posedge clk)begin
  spi_start<=0;done<=0;
  if(rst)begin state<=0;fault<=0;index<=0;product<=0;spi_address<=0;spi_write<=0;spi_write_data<=0;end
  else case(state)
   0:if(start)begin fault<=0;profile_l<=profile;spi_address<=10'h1eb;spi_write<=0;state<=1;end
   1:begin spi_start<=1;state<=2;end
   2:if(spi_done)begin c3_msb<=spi_read_data;spi_address<=10'h1ec;state<=3;end
   3:begin spi_start<=1;state<=4;end
   4:if(spi_done)begin c3_lsb<=spi_read_data;spi_address<=10'h1e6;state<=5;end
   5:begin spi_start<=1;state<=6;end
   6:if(spi_done)begin
    r2346<=spi_read_data;
    if(c3_msb>63||c3_lsb>127||spi_read_data==0||spi_read_data>7)begin fault<=1;done<=1;state<=0;end
    else begin product<=spi_read_data*(16*c3_msb+c3_lsb+14);index<=tia_only?40:0;state<=7;end
   end
   7:state<=8;
   8:begin
    spi_address<=index<40?(10'h200+index):(10'h1db+index-40);
    spi_write_data<=coefficient;spi_write<=1;state<=9;
   end
   9:begin spi_start<=1;state<=10;end
   10:if(spi_done)begin
    if(index==(tia_only?44:39))begin done<=1;state<=0;end
    else begin index<=index+1;state<=7;end
   end
   default:begin fault<=1;done<=1;state<=0;end
  endcase
 end
endmodule
