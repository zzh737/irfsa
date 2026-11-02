// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Fixed-rate full-duplex 8N1. RX has a three-flop synchronizer and mid-bit sampling.
module uart_phy #(parameter CLOCK_HZ=125000000,BAUD=115200)(
 input wire clk,rst,rx,output reg tx,
 output reg [7:0] rx_data,output reg rx_valid,rx_error,
 input wire [7:0] tx_data,input wire tx_valid,output wire tx_ready
);
 localparam TICKS=(CLOCK_HZ+BAUD/2)/BAUD;
 (* ASYNC_REG="TRUE" *) reg [2:0] rx_sync=7;
 reg [15:0] rx_timer,tx_timer;
 reg [3:0] rx_state,tx_left;
 reg [2:0] rx_bit;
 reg [7:0] rx_shift;
 reg [9:0] tx_shift;
 assign tx_ready=tx_left==0;
 always @(posedge clk)begin
  rx_sync<={rx_sync[1:0],rx};rx_valid<=0;rx_error<=0;
  if(rst)begin
   rx_sync<=7;rx_timer<=0;tx_timer<=0;rx_state<=0;rx_bit<=0;rx_shift<=0;
   rx_data<=0;rx_valid<=0;rx_error<=0;tx<=1;tx_left<=0;tx_shift<=10'h3ff;
  end else begin
   case(rx_state)
    0:if(!rx_sync[2])begin rx_timer<=TICKS/2-1;rx_state<=1;end
    1:if(rx_timer!=0)rx_timer<=rx_timer-1;
      else if(rx_sync[2])rx_state<=0;
      else begin rx_state<=2;rx_timer<=TICKS-1;rx_bit<=0;end
    2:if(rx_timer!=0)rx_timer<=rx_timer-1;
      else begin
       rx_shift[rx_bit]<=rx_sync[2];rx_timer<=TICKS-1;
       if(rx_bit==7)rx_state<=3;else rx_bit<=rx_bit+1;
      end
    3:if(rx_timer!=0)rx_timer<=rx_timer-1;
      else begin
       if(rx_sync[2])begin rx_data<=rx_shift;rx_valid<=1;rx_state<=0;end
       else begin rx_error<=1;rx_state<=4;end
      end
    4:if(rx_sync[2])rx_state<=0; // a break is one error, not a stream of zero bytes
    default:rx_state<=0;
   endcase
   if(tx_ready)begin
    if(tx_valid)begin
     tx_shift<={1'b1,tx_data,1'b0};tx<=0;tx_left<=10;tx_timer<=TICKS-1;
    end
   end else if(tx_timer!=0)tx_timer<=tx_timer-1;
   else begin
    tx_shift<={1'b1,tx_shift[9:1]};tx<=tx_shift[1];
    tx_timer<=TICKS-1;tx_left<=tx_left-1;
   end
  end
 end
endmodule
