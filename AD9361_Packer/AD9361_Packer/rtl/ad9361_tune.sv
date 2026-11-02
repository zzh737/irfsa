// SPDX-License-Identifier: BSD-3-Clause
`timescale 1ns/1ps
// TX quadrature calibration plus fixed LVDS timing; no digital eye scan or PN gate.
module ad9361_tune #(parameter SETTLE_CYCLES=125000,
 // Per-phase cal-done limit: 50 ms, about 6x the UG-570 worst case (7.6 ms).
 // Kept well below the CALL budget so a stuck engine reports reason 1 itself.
 parameter QUAD_CAL_TIMEOUT=6250000,
 // TX_DELAY 0x0A = FB_CLK delay 0, TX data delay 10: HW16 bench sweep of all 256
 // 0x007 values (pure tone image/spurs + 4PSK EVM). Data delay 0 fails, 1 is marginal,
 // 2..15 clean; 8..12 deepest image. ADI default 0x70 corrupted TX (EVM 65%).
 parameter [7:0] RX_DELAY=8'h04, TX_DELAY=8'h0a)(
 input wire clk,rst,start,input wire fixed_interface,
 output reg done,fault,output wire busy,
 output reg spi_start,spi_write,output reg [9:0] spi_address,
 output reg [7:0] spi_write_data,input wire spi_done,input wire [7:0] spi_read_data,
 output reg [7:0] rx_delay,tx_delay,output reg [4:0] quad_phase,
 output wire [31:0] diagnostics,
 // Last TX quadrature result. quad_warn: no phase converged, or the chosen
 // phase did not re-converge; like ADI this is a warning, never a fault.
 // quad_mode: 0 default 0x1F, 1 last good phase, 2 phase search, 3 no convergence.
 output reg quad_warn,output reg [1:0] quad_mode,output reg [31:0] quad_pass_map,
 output reg [7:0] quad_status1,quad_status2
);
 reg [6:0] state,return_state;
 reg [31:0] timer;
 // attempt: 0 default phase, 1 last good phase, 2 search, 3 final at chosen phase.
 reg [5:0] phase;reg [1:0] attempt;reg [4:0] last_phase;reg last_valid;
 reg [6:0] scan,run_len,run_start,best_len,best_start;
 reg [7:0] quad_status;
 reg [31:0] fault_detail;
 wire quad_pass=(quad_status&3)==3&&(spi_read_data&3)==3;
 // ad9361_find_opt over the 64-entry wrapped field: longest passing run.
 wire [6:0] opt_len=run_len>best_len?run_len:best_len;
 wire [6:0] opt_start=run_len>best_len?run_start:best_start;
 wire [6:0] opt_center=opt_start+(opt_len>>1);
 assign diagnostics=fault ? fault_detail : {4'd0,state,21'd0};
 assign busy=state!=0;
 task automatic issue(input bit wr,input [9:0] addr,input [7:0] val,input [6:0] next_state);
  begin spi_write<=wr;spi_address<=addr;spi_write_data<=val;return_state<=next_state;state<=60;end
 endtask
 task automatic fail(input [3:0] reason);
  begin fault_detail<={reason,state,21'd0};
   fault<=1;done<=1;state<=0;end
 endtask
 task automatic finish_quad(input warn,input [1:0] mode);
  begin quad_phase<=phase[4:0];quad_warn<=warn;quad_mode<=mode;done<=1;state<=0;
   if(!warn)begin last_phase<=phase[4:0];last_valid<=1;end end
 endtask
 always @(posedge clk)begin
  spi_start<=0;done<=0;
  if(rst)begin
   state<=0;fault<=0;fault_detail<=0;
   spi_write<=0;spi_address<=0;spi_write_data<=0;rx_delay<=0;tx_delay<=0;quad_phase<=0;
   phase<=0;attempt<=0;last_phase<=0;last_valid<=0;quad_status<=0;
   scan<=0;run_len<=0;run_start<=0;best_len<=0;best_start<=0;
   quad_warn<=0;quad_mode<=0;quad_pass_map<=0;quad_status1<=0;quad_status2<=0;
   timer<=0;
  end else begin
   if(timer!=0)timer<=timer-1;
   case(state)
    0:if(start)begin
     fault<=0;
     // ADI ad9361_tx_quad_calib: try the default phase first.
     if(fixed_interface)state<=20;else begin attempt<=0;phase<=6'h1f;quad_pass_map<=0;state<=1;end
    end
    1:issue(1,10'h0a0,8'h40|phase[4:0],2);
    2:issue(1,10'h0a1,8'h7f,3);
    3:issue(1,10'h0a1,8'h7b,4);
    4:issue(1,10'h016,8'h10,5);
    5:begin timer<=QUAD_CAL_TIMEOUT;state<=6;end
    6:issue(0,10'h016,0,7);
    7:if(!spi_read_data[4])issue(0,10'h0a7,0,8);
      else if(timer==0)fail(1);else state<=6;
    8:begin quad_status<=spi_read_data;issue(0,10'h0a8,0,9);end
    9:begin
     quad_status1<=quad_status;quad_status2<=spi_read_data;
     case(attempt)
      0:if(quad_pass)finish_quad(0,0);
        else if(last_valid&&last_phase!=5'h1f)begin attempt<=1;phase<=last_phase;state<=1;end
        else begin attempt<=2;phase<=0;state<=1;end
      1:if(quad_pass)finish_quad(0,1);
        else begin attempt<=2;phase<=0;state<=1;end
      2:begin
       quad_pass_map[phase[4:0]]<=quad_pass;
       if(phase==31)state<=10;else begin phase<=phase+1;state<=1;end
      end
      // The calibration result in the chip is the one from this final run.
      default:finish_quad(!quad_pass,quad_mode);
     endcase
    end
    10:begin scan<=0;run_len<=0;run_start<=0;best_len<=0;best_start<=0;state<=11;end
    11:if(scan==64)state<=12;
     else begin
      if(quad_pass_map[scan[4:0]])begin
       if(run_len==0)run_start<=scan;run_len<=run_len+1;
      end else begin
       if(run_len>best_len)begin best_len<=run_len;best_start<=run_start;end
       run_len<=0;
      end
      scan<=scan+1;
     end
    // No converging phase: fall back to the default phase and warn, like ADI.
    12:begin
     attempt<=3;state<=1;
     if(opt_len==0)begin phase<=6'h1f;quad_mode<=3;end
     else begin phase<={1'b0,opt_center[4:0]};quad_mode<=2;end
    end
    // Apply the existing board profile once. No RX/TX tap search and no
    // external data/PN acknowledgement can hold initialization here.
    20:issue(1,10'h006,RX_DELAY,21);
    21:issue(1,10'h007,TX_DELAY,22);
    22:issue(1,10'h03d,8'h00,23);
    23:issue(1,10'h03e,8'h00,24);
    24:issue(1,10'h3f4,8'h00,25); // normal RX data
    25:issue(1,10'h3f5,8'h00,26); // no digital loopback
    26:issue(1,10'h3f6,8'h00,27); // no test masks
    27:begin timer<=SETTLE_CYCLES;state<=28;end
    28:if(timer==0)begin
     rx_delay<=RX_DELAY;tx_delay<=TX_DELAY;done<=1;state<=0;
    end
    60:begin spi_start<=1;state<=61;end
    61:if(spi_done)state<=return_state;
    default:fail(15);
   endcase
  end
 end
endmodule
