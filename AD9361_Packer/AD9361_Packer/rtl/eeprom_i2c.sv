// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// AT24C64D byte read/write, 100 kHz. Both wires are open drain.
// Includes clock stretching and a bounded transaction timeout.
module eeprom_i2c #(parameter QUARTER=312)(
 input wire clk,rst,start,write,input wire [12:0] address,input wire [7:0] write_data,
 output reg done,fault,output reg [7:0] read_data,output wire busy,
 inout wire scl,sda
);
 reg scl_low,sda_low;assign scl=scl_low?1'b0:1'bz;assign sda=sda_low?1'b0:1'bz;
 (* ASYNC_REG="TRUE" *) reg [1:0] scl_sync,sda_sync;
 reg [5:0] state;reg [15:0] tick_count;reg [21:0] watchdog;
 reg wr_l;reg [12:0] addr_l;reg [7:0] data_l,shift;reg [2:0] bit_index,byte_index;
 assign busy=state!=0;
 task automatic fail;begin fault<=1;done<=1;state<=0;scl_low<=0;sda_low<=0;end endtask
 always @(posedge clk)begin
  done<=0;scl_sync<={scl_sync[0],scl};sda_sync<={sda_sync[0],sda};
  if(rst)begin
   state<=0;scl_low<=0;sda_low<=0;done<=0;fault<=0;read_data<=0;
   tick_count<=0;watchdog<=0;wr_l<=0;addr_l<=0;data_l<=0;shift<=0;bit_index<=7;byte_index<=0;
   scl_sync<=3;sda_sync<=3;
  end else begin
   if(state==0)begin
    if(start)begin
     wr_l<=write;addr_l<=address;data_l<=write_data;fault<=0;
     watchdog<=0;tick_count<=0;byte_index<=0;state<=1;
    end
   end else begin
    watchdog<=watchdog+1;
    if(tick_count!=0)tick_count<=tick_count-1;
    else begin
     tick_count<=QUARTER-1;
     case(state)
      1:if(scl_sync[1]&&sda_sync[1])begin sda_low<=1;state<=2;end
      2:begin scl_low<=1;shift<=8'ha0;bit_index<=7;state<=3;end
      3:begin sda_low<=!shift[bit_index];state<=4;end
      4:begin scl_low<=0;state<=5;end
      5:if(scl_sync[1])state<=6;
      6:begin scl_low<=1;if(bit_index==0)state<=7;else begin bit_index<=bit_index-1;state<=3;end end
      7:begin sda_low<=0;state<=8;end
      8:begin scl_low<=0;state<=9;end
      9:if(scl_sync[1])begin if(sda_sync[1])fail();else state<=10;end
      10:begin
       scl_low<=1;bit_index<=7;
       case(byte_index)
        0:begin shift<={3'b0,addr_l[12:8]};byte_index<=1;state<=3;end
        1:begin shift<=addr_l[7:0];byte_index<=2;state<=3;end
        2:if(wr_l)begin shift<=data_l;byte_index<=3;state<=3;end else state<=11;
        3:state<=25;
        4:begin shift<=0;state<=16;end
       endcase
      end
      11:begin sda_low<=0;state<=12;end
      12:begin scl_low<=0;state<=13;end
      13:if(scl_sync[1])begin sda_low<=1;state<=14;end
      14:begin scl_low<=1;shift<=8'ha1;byte_index<=4;state<=3;end
      16:begin sda_low<=0;state<=17;end
      17:begin scl_low<=0;state<=18;end
      18:if(scl_sync[1])begin shift[bit_index]<=sda_sync[1];state<=19;end
      19:begin scl_low<=1;if(bit_index==0)begin read_data<=shift;state<=20;end
         else begin bit_index<=bit_index-1;state<=16;end end
      20:begin sda_low<=0;state<=21;end
      21:begin scl_low<=0;state<=22;end
      22:if(scl_sync[1])state<=23;
      23:begin scl_low<=1;state<=25;end
      25:begin sda_low<=1;state<=26;end
      26:begin scl_low<=0;state<=27;end
      27:if(scl_sync[1])begin sda_low<=0;state<=28;end
      28:begin done<=1;state<=0;end
      default:fail();
     endcase
    end
    if(watchdog==22'd2499999)fail(); // 20 ms, includes missing pullups/stuck bus
   end
  end
 end
endmodule
