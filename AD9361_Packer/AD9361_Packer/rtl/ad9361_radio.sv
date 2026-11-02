// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Pure PL radio supervisor. No calibration failure can publish RF_READY.
module ad9361_radio(
 input wire clk,rst,apply,input wire [63:0] lo_hz,input wire emergency_abort,
 input wire rx_apply,input wire [63:0] rx_lo_hz,
 input wire [2:0] rx_profile,input wire [1:0] rx_gain_mode,input wire signed [31:0] rx_gain_mdb,
 input wire tx_apply,
 input wire gate_start,input wire [1:0] requested_mask,input wire [8:0] attenuation1,attenuation2,
 // Bench-only single SPI transaction (RFCT v2 0x105 over UART). Runs only from
 // IDLE with RF ready; never touches scripts, masks or fault state.
 input wire reg_start,reg_write,input wire [9:0] reg_address,input wire [7:0] reg_wdata,
 output reg reg_done,output reg [7:0] reg_rdata,
 output reg ready,fault,done,output wire busy,output reg [1:0] applied_mask,
 output reg resetb,output wire spi_cs_n,spi_sclk,spi_mosi,input wire spi_miso,
 output reg [15:0] fault_index,output wire [7:0] rx_delay,tx_delay,output wire [4:0] quad_phase,
 output wire [255:0] diagnostics,
 output reg [127:0] interface_registers,
 // Last TX quadrature calibration: warn = not converged (non-fatal, as ADI).
 output wire quad_warn,output wire [1:0] quad_mode
);
 localparam RESET_BEGIN=0,RESET_HOLD=1,RESET_RELEASE=2,FETCH=3,DECODE=4,
  SEND=5,WAIT_SPI=6,CHECK=7,DELAY=8,RMW_SEND=9,RMW_WAIT=10,CALL_WAIT=11,RX_PLAN=12,
  REG_SEND=13,REG_WAIT=14,IDLE=20,FAILED=31;
 reg [4:0] state;
 reg [63:0] rom[0:6143];initial $readmemh("radio_init.mem",rom);
 reg [63:0] rx_rom[0:6143];initial $readmemh("radio_rx.mem",rx_rom);
 reg [63:0] tx_rom[0:2047];initial $readmemh("radio_tx.mem",tx_rom);
 reg [63:0] bw_rom[0:1023];initial $readmemh("radio_bw.mem",bw_rom);
 reg bw_script;reg [2:0] profile_l;reg tx_cal_pending,tx_restore_pending;
 // Keep the division signed: an unsigned 8'd40 arm would turn -1 dB into index 57.
 wire signed [31:0] manual_index=$signed(rx_gain_mdb)/32'sd1000+(rx_lo_hz<=64'd1300000000 ?32'sd3:rx_lo_hz<=64'd4000000000 ?32'sd5:32'sd14);
 wire [7:0] gain_index=rx_gain_mode==0 ? manual_index[7:0] : 8'd40;
 wire [7:0] gain_control=rx_gain_mode==1?8'd2:rx_gain_mode==2?8'd1:8'd0;
 reg [10:0] index;reg [63:0] cmd;
 reg [31:0] timer,elapsed;reg plan_start,plan_latched;
 wire plan_done,plan_fault;wire [143:0] pll_values;wire [1:0] band;
 reg rx_script,tx_script,rx_plan_start,rx_plan_latched,plans_issued;
 reg apply_pending,rx_pending,tx_pending,gate_pending,reg_pending;
 wire rx_plan_done,rx_plan_fault;wire [143:0] rx_pll_values;wire [1:0] rx_band;
 ad9361_frequency_plan planner(clk,rst,plan_start,lo_hz,(rx_script||tx_script)&&(lo_hz!=rx_lo_hz),plan_done,plan_fault,pll_values,band);
 ad9361_frequency_plan rx_planner(clk,rst,rx_plan_start,rx_lo_hz,lo_hz!=rx_lo_hz,rx_plan_done,rx_plan_fault,rx_pll_values,rx_band);
 reg main_start,main_write;reg [9:0] main_address;reg [7:0] main_data,last_read;
 wire spi_done,spi_busy;wire [7:0] spi_read_data;
 reg cal_start,tune_start;wire cal_busy,cal_done,cal_fault,tune_busy,tune_done,tune_fault;
 wire cal_spi_start,cal_spi_write,tune_spi_start,tune_spi_write;
 wire [9:0] cal_address,tune_address;wire [7:0] cal_data,tune_data;
 reg [1:0] special;reg [3:0] qualified;
 wire [31:0] tune_diagnostics;reg [31:0] tune_failure;
 wire [31:0] quad_pass_map;wire [7:0] quad_status1,quad_status2;
 ad9361_adc_cal calibrator(clk,rst||!resetb,cal_start,special==1,bw_script?profile_l:3'd7,
  cal_done,cal_fault,cal_busy,cal_spi_start,cal_spi_write,cal_address,cal_data,spi_done,spi_read_data);
 ad9361_tune tuner(clk,rst||!resetb,tune_start,special==3,tune_done,tune_fault,tune_busy,
  tune_spi_start,tune_spi_write,tune_address,tune_data,spi_done,spi_read_data,
  rx_delay,tx_delay,quad_phase,tune_diagnostics,
  quad_warn,quad_mode,quad_pass_map,quad_status1,quad_status2);
 ad9361_spi #(.HALF_PERIOD(16)) spi(.clk(clk),.rst(rst||fault),
  .start(cal_busy?cal_spi_start:(tune_busy?tune_spi_start:main_start)),
  .write(cal_busy?cal_spi_write:(tune_busy?tune_spi_write:main_write)),
  .address(cal_busy?cal_address:(tune_busy?tune_address:main_address)),
  .write_data(cal_busy?cal_data:(tune_busy?tune_data:main_data)),
  .read_data(spi_read_data),.done(spi_done),.busy(spi_busy),
  .cs_n(spi_cs_n),.sclk(spi_sclk),.mosi(spi_mosi),.miso(spi_miso));
 assign busy=state!=IDLE;
 reg gate_script;
 reg [1:0] gate_mask;reg [8:0] atten1_l,atten2_l;
 reg [63:0] gate_command;
 always @*begin
  gate_command={4'h1,12'h000,8'h00,8'hff,32'd1250000};
  case(index)
   // Same order as ADI ad9361_set_tx_atten(immed): clear 0x07C[6], write
   // bit 8 (0x074/0x076) before bits 7:0 (0x073/0x075), then set 0x07C[6].
   0:gate_command={4'h4,12'h07c,8'h00,8'h40,32'd1250000};
   1:gate_command={4'h1,12'h074,7'd0,atten1_l[8],8'hff,32'd1250000};
   2:gate_command={4'h1,12'h073,atten1_l[7:0],8'hff,32'd1250000};
   3:gate_command={4'h1,12'h076,7'd0,atten2_l[8],8'hff,32'd1250000};
   4:gate_command={4'h1,12'h075,atten2_l[7:0],8'hff,32'd1250000};
   5:gate_command={4'h4,12'h07c,8'h40,8'h40,32'd1250000};
   // Keep both physical TX paths enabled with the fixed 2R2T interface.
   // A single physical TX path stops RX_FRAME on this board. Logical gates
   // use zero IQ plus maximum attenuation on each disabled transmitter.
   6:gate_command={4'h1,12'h002,8'hdc,8'hff,32'd1250000};
   7:gate_command={4'h2,12'h002,8'hc0,8'hc0,32'd1250000};
   8:gate_command={4'h2,12'h073,atten1_l[7:0],8'hff,32'd1250000};
   9:gate_command={4'h2,12'h074,7'd0,atten1_l[8],8'h01,32'd1250000};
   10:gate_command={4'h2,12'h075,atten2_l[7:0],8'hff,32'd1250000};
   11:gate_command={4'h2,12'h076,7'd0,atten2_l[8],8'h01,32'd1250000};
  endcase
 end
 wire [143:0] selected_pll=(rx_script||tx_script)&&cmd[57:48]<10'h270&&
  (cmd[57:48]!=5||cmd[47:40]==16)?rx_pll_values:pll_values;
 // 13 = write a value chosen by the live RX LO band. Selector 0 is ADI's
 // tx_quad_lpf_tia_match (0x0AA) from the RX gain table: 0x24/0x25/0x28.
 wire [7:0] rx_band_value=rx_lo_hz<=64'd1300000000 ? 8'h24 : rx_lo_hz<=64'd4000000000 ? 8'h25 : 8'h28;
 wire [7:0] command_value=(cmd[63:60]>=10&&cmd[63:60]<=12)?(cmd[47:40]==0?gain_control:cmd[47:40]==1?gain_index:rx_gain_mode==2?8'd2:8'd9):
  (cmd[63:60]==6||cmd[63:60]==7||cmd[63:60]==8)?selected_pll[8*cmd[47:40]+:8]:
  cmd[63:60]==13?rx_band_value:cmd[47:40];
 // Schema HW19: word 0 = TX quadrature per-phase pass map of the last search,
 // word 1 bits 23:16 = {quad_phase,quad_mode,quad_warn}, word 6 bits 31:16 =
 // last 0x0A7/0x0A8 (TX1/TX2 LO+SSB convergence bits 1:0).
 assign diagnostics={quad_pass_map,{8'd0,quad_phase,quad_mode,quad_warn,ready,fault,busy,qualified,special,state,tx_script,rx_script},
  {index,3'd0,main_address,last_read},cmd,elapsed,{quad_status1,quad_status2,fault_index},
  (fault&&special>=2 ? tune_failure : timer)};
 task automatic fail;
  begin resetb<=0;fault<=1;ready<=0;applied_mask<=0;done<=1;fault_index<={5'd0,index};state<=FAILED;
   if(state==CALL_WAIT&&special>=2)tune_failure<=tune_diagnostics;end
 endtask
 task automatic advance;
  begin
   if(gate_script&&index==11)begin applied_mask<=gate_mask;done<=1;state<=IDLE;end
   else if(index==2047)fail();
   else begin index<=index+1;state<=FETCH;end
  end
 endtask
 always @(posedge clk or posedge rst)begin
  main_start<=0;cal_start<=0;tune_start<=0;plan_start<=0;rx_plan_start<=0;done<=0;reg_done<=0;
  if(rst)begin
   reg_rdata<=0;
   state<=RESET_BEGIN;resetb<=0;ready<=0;fault<=0;applied_mask<=0;fault_index<=0;
   index<=0;cmd<=0;timer<=0;elapsed<=0;plan_latched<=0;gate_script<=0;
   main_write<=0;main_address<=0;main_data<=0;last_read<=0;special<=0;qualified<=0;tune_failure<=0;
   gate_mask<=0;atten1_l<=359;atten2_l<=359;
   interface_registers<=0;
   rx_script<=0;tx_script<=0;rx_plan_latched<=0;plans_issued<=0;bw_script<=0;profile_l<=7;tx_cal_pending<=0;tx_restore_pending<=0;
   apply_pending<=0;rx_pending<=0;tx_pending<=0;gate_pending<=0;reg_pending<=0;
  end else begin
   // Keep requests until IDLE so an operation completion cannot lose a pulse.
   if(apply)apply_pending<=1;
   if(rx_apply)rx_pending<=1;
   if(tx_apply)tx_pending<=1;
   if(gate_start)gate_pending<=1;
   if(reg_start)reg_pending<=1;
   if(timer!=0)timer<=timer-1;
   if(state!=FAILED&&elapsed!=32'hffffffff)elapsed<=elapsed+1;
   if(plan_done)plan_latched<=1;
   if(rx_plan_done)rx_plan_latched<=1;
   case(state)
    RESET_BEGIN:begin
     resetb<=0;
     // A fault inside the RX filter/gain script must not leave bw_script set:
     // FETCH would then run bw_rom on a freshly reset chip and fail forever.
     fault<=0;ready<=0;applied_mask<=0;qualified<=0;index<=0;gate_script<=0;rx_script<=0;tx_script<=0;tune_failure<=0;
     bw_script<=0;profile_l<=7;tx_cal_pending<=0;tx_restore_pending<=0;reg_pending<=0;
     timer<=1250000;plan_start<=1;plan_latched<=0;state<=RESET_HOLD;
    end
    RESET_HOLD:if(timer==0&&plan_latched)begin resetb<=1;timer<=125000;state<=RESET_RELEASE;end
    RESET_RELEASE:if(timer==0)state<=FETCH;
    FETCH:begin
     cmd<=bw_script?bw_rom[{profile_l,index[6:0]}]:tx_script?tx_rom[index]:(rx_script?rx_rom[{rx_band,index}]:(gate_script?gate_command:rom[{band,index}]));
     state<=DECODE;elapsed<=0;
    end
    DECODE:begin
     main_address<=cmd[57:48];main_data<=command_value;
     // AGC owns the gain index: like ADI, never write/check 0x109 outside MGC.
     if(cmd[63:60]>=10&&cmd[63:60]<=12&&cmd[47:40]==1&&rx_gain_mode!=0)advance();
     else case(cmd[63:60])
      1,2,4,6,7,8,9,10,11,12,13:begin main_write<=cmd[63:60]==1||cmd[63:60]==6||cmd[63:60]==10||cmd[63:60]==13;state<=SEND;end
      3:begin timer<=cmd[31:0];state<=DELAY;end
      5:begin
       special<=cmd[41:40];if(cmd[41:40]<2)cal_start<=1;else tune_start<=1;
       timer<=cmd[31:0];state<=CALL_WAIT;
      end
      15:if(&qualified)begin
       if(bw_script&&tx_cal_pending)begin
        bw_script<=0;tx_script<=1;tx_cal_pending<=0;tx_restore_pending<=1;index<=0;state<=FETCH;
       end else if(tx_script&&tx_restore_pending)begin
        tx_script<=0;bw_script<=1;profile_l<=rx_profile;tx_restore_pending<=0;index<=0;state<=FETCH;
       end else if(rx_script)begin rx_script<=0;bw_script<=1;profile_l<=rx_profile;index<=0;state<=FETCH;end
       else begin ready<=1;done<=1;rx_script<=0;tx_script<=0;bw_script<=0;state<=IDLE;end
      end else fail();
      default:fail();
     endcase
    end
    SEND:if(!spi_busy)begin main_start<=1;state<=WAIT_SPI;end
    WAIT_SPI:if(spi_done)begin last_read<=spi_read_data;state<=CHECK;end
    CHECK:begin
     if(cmd[63:60]==9)begin interface_registers[8*cmd[43:40]+:8]<=last_read;advance();end
     else if(cmd[63:60]==1||cmd[63:60]==6||cmd[63:60]==10||cmd[63:60]==13)advance();
     else if(cmd[63:60]==4||cmd[63:60]==7||cmd[63:60]==12)begin
      main_data<=(last_read&~cmd[39:32])|(command_value&cmd[39:32]);main_write<=1;state<=RMW_SEND;
     end else if((last_read&cmd[39:32])==(command_value&cmd[39:32]))advance();
     else if(elapsed>=cmd[31:0])fail();else state<=SEND;
    end
    REG_SEND:if(!spi_busy)begin main_start<=1;state<=REG_WAIT;end
    REG_WAIT:if(spi_done)begin reg_rdata<=spi_read_data;reg_done<=1;state<=IDLE;end
    RMW_SEND:if(!spi_busy)begin main_start<=1;state<=RMW_WAIT;end
    RMW_WAIT:if(spi_done)advance();
    DELAY:if(timer==0)advance();
    CALL_WAIT:begin
     if((special<2&&cal_done)||(special>=2&&tune_done))begin
      if((special<2&&cal_fault)||(special>=2&&tune_fault))fail();
      else begin qualified[special]<=1;advance();end
     end else if(timer==0)fail();
    end
    IDLE:begin
     if(apply||apply_pending)begin apply_pending<=0;state<=RESET_BEGIN;end
     else if(rx_apply||tx_apply||rx_pending||tx_pending)begin
      rx_script<=rx_apply||rx_pending;tx_script<=tx_apply||tx_pending;
      rx_pending<=0;tx_pending<=0;gate_script<=0;index<=0;
      plan_latched<=0;rx_plan_latched<=0;plans_issued<=0;state<=RX_PLAN;
     end
     else if(reg_start||reg_pending)begin
      // One raw transaction on the shared SPI master; scripts are idle here.
      reg_pending<=0;
      main_write<=reg_write;main_address<=reg_address;main_data<=reg_wdata;state<=REG_SEND;
     end
     else if(gate_start||gate_pending)begin
      gate_pending<=0;
      if(attenuation1>359||attenuation2>359)fail();
      else begin
       gate_script<=1;gate_mask<=requested_mask;
       atten1_l<=requested_mask[0]?attenuation1:9'd359;
       atten2_l<=requested_mask[1]?attenuation2:9'd359;index<=0;state<=FETCH;
      end
     end
    end
    RX_PLAN:begin
     // Launch after rx_script has selected the correct TDD/FDD table policy.
     if(!plans_issued)begin plan_start<=1;rx_plan_start<=1;plans_issued<=1;end
     if(plan_latched&&rx_plan_latched)begin
      // ADI widens RX before TX quadrature calibration when its NCO falls
      // outside the requested RX passband, then restores the RX filter.
      if(tx_script&&rx_profile!=7)begin
       tx_script<=0;bw_script<=1;profile_l<=7;tx_cal_pending<=1;
      end
      state<=FETCH;
     end
    end
    FAILED:if(apply||apply_pending)begin apply_pending<=0;state<=RESET_BEGIN;end
    default:fail();
   endcase
   // A failed frequency plan must win over every state transition.
   if(plan_done&&plan_fault)fail();
   if(rx_plan_done&&rx_plan_fault)fail();
   if(emergency_abort)fail();
  end
 end
endmodule
