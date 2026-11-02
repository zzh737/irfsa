// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Lane order follows ADI axi_ad9361_lvds_if with PP_RX/TX_SWAP_IQ enabled.
// Four DATA_CLK cycles per 2R2T complex sample, even with one TX disabled.
module ad9361_frame_core(
 input wire clk,rst,input wire [5:0] rx_rise,rx_fall,input wire [1:0] rx_frame,
 output reg rx_valid,output reg [47:0] rx_iq,output reg frame_error,
 input wire [47:0] tx_iq,input wire tx_valid,
 output wire sample_strobe,output reg [5:0] tx_rise,tx_fall,output wire tx_frame
);
 reg [2:0] rx_phase;reg [47:0] assembled;
 reg [1:0] tx_phase;reg [47:0] held_tx,pending_tx;
 assign sample_strobe=tx_phase==0;
 assign tx_frame=!tx_phase[1];
 always @*begin
  case(tx_phase)
   0:begin tx_fall=held_tx[11:6];tx_rise=held_tx[23:18];end
   1:begin tx_fall=held_tx[5:0];tx_rise=held_tx[17:12];end
   2:begin tx_fall=held_tx[35:30];tx_rise=held_tx[47:42];end
   3:begin tx_fall=held_tx[29:24];tx_rise=held_tx[41:36];end
  endcase
 end
 always @(posedge clk)begin
  if(rst)begin tx_phase<=0;held_tx<=0;pending_tx<=0;rx_phase<=4;rx_valid<=0;frame_error<=0;rx_iq<=0;assembled<=0;end
  else begin
   tx_phase<=tx_phase+1;
   if(tx_valid)pending_tx<=tx_iq;
   if(tx_phase==3)held_tx<=tx_valid?tx_iq:pending_tx;
   rx_valid<=0;frame_error<=0;
   case(rx_phase)
    0:if(rx_frame==3)begin assembled[11:6]<=rx_fall;assembled[23:18]<=rx_rise;rx_phase<=1;end
      else begin rx_phase<=4;frame_error<=1;end
    1:if(rx_frame==3)begin assembled[5:0]<=rx_fall;assembled[17:12]<=rx_rise;rx_phase<=2;end
      else begin rx_phase<=4;frame_error<=1;end
    2:if(rx_frame==0)begin assembled[35:30]<=rx_fall;assembled[47:42]<=rx_rise;rx_phase<=3;end
      else begin rx_phase<=4;frame_error<=1;end
    3:if(rx_frame==0)begin rx_iq<={assembled[47:42],rx_rise,assembled[35:30],rx_fall,assembled[23:0]};rx_valid<=1;rx_phase<=0;end
      else begin rx_phase<=4;frame_error<=1;end
    // Search a low->high frame transition, then capture the upper halves.
    4:if(rx_frame==0)rx_phase<=5;
    5:if(rx_frame==3)begin assembled[11:6]<=rx_fall;assembled[23:18]<=rx_rise;rx_phase<=1;end
   endcase
  end
 end
endmodule
