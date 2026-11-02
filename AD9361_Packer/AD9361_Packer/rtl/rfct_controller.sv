// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// UDP RFCT v1 RX control / UART RFCT v2 TX control. Domains have independent
// request high-water marks; cache keys and deferred replies include transport.
// REG_DEBUG=1 enables RFCT v2 0x105 (UART only): one raw AD9361 SPI register
// read or write for bench interface tuning. Set 0 to lock it out (UNSUPPORTED).
module rfct_controller #(parameter CLOCK_HZ=125000000,CACHE_BITS=8,REG_DEBUG=0)(
 input wire clk,rst,input wire [31:0] boot_id,input wire link_up,input wire [1:0] link_speed,
 input wire command_valid,output wire command_ready,input wire [1023:0] command_bytes,input wire [15:0] command_length,
 input wire command_uart,output wire reply_uart,
 output wire hdr_valid,input wire hdr_ready,output wire [15:0] reply_length,
 output wire [7:0] data,output wire valid,input wire ready,output wire last,
 input wire radio_ready,radio_fault,radio_busy,radio_done,input wire [1:0] applied_mask,
 input wire [15:0] radio_fault_index,input wire [1023:0] hardware_diagnostics,
 input wire quad_warn,input wire [1:0] quad_mode,
 input wire [31:0] startup_diagnostics,
 output reg radio_apply,gate_start,output reg [63:0] radio_lo,
 output reg radio_rx_apply,output reg [63:0] radio_rx_lo,
 output reg [2:0] radio_rx_profile,output reg [1:0] radio_rx_gain_mode,output reg signed [31:0] radio_rx_gain,
 output reg radio_tx_apply,
 output reg [1:0] requested_mask,digital_mask,output reg [8:0] attenuation1,attenuation2,
 output reg [511:0] dsp_config,output reg dsp_toggle,input wire dsp_ack,
 output reg capture_run,output reg decimate25,output reg [31:0] capture_id,fs_eff_hz,
 input wire packet_idle,input wire [31:0] fifo_points,
 input wire [63:0] sample_count,datagrams,drop_windows,overflow_events,
 input wire [31:0] clip_count1,clip_count2,input wire data_fault,
 output reg reg_start,output reg reg_write,output reg [9:0] reg_address,output reg [7:0] reg_wdata,
 input wire reg_done,input wire [7:0] reg_rdata
);
 localparam CACHE_N=1<<CACHE_BITS;
 localparam IDLE=0,LOOKUP=1,DECIDE=2,EXECUTE=3,BUILD=4,CRC=5,HEADER=6,PAYLOAD=7,LOAD_CACHE=8;
 reg [3:0] state;
 reg [1023:0] request,pending_request;reg [15:0] req_length,pending_length;
 reg request_uart,pending_uart;
 reg [15:0] response_status;reg [1279:0] response;
 reg [7:0] response_size,pos;reg [31:0] crc_acc;
 reg cache_reply;reg [CACHE_BITS-1:0] reply_slot,pending_slot,head,scan_index,found_index;
 reg found,conflict,pending_duplicate;reg [CACHE_BITS-1:0] skipped;
 (* ram_style="block" *) reg [1023:0] cache_request[0:CACHE_N-1];
 (* ram_style="block" *) reg [1279:0] cache_response[0:CACHE_N-1];
 reg [15:0] cache_length[0:CACHE_N-1];reg [7:0] cache_size[0:CACHE_N-1];
 reg [31:0] cache_time[0:CACHE_N-1],cache_id[0:CACHE_N-1];
 reg [CACHE_N-1:0] occupied,completed;
 reg [CACHE_N-1:0] cache_uart;
 reg [31:0] seconds,second_ticks,request_high,uart_request_high;
 reg [31:0] stage_id,active_id,config_high,capture_high;
 reg stage_rf,stage_stream,has_active;
 reg [63:0] stage_lo,active_lo;
 reg [31:0] stage_bw,active_bw;reg signed [31:0] stage_gain,active_gain;
 reg [1:0] stage_gain_mode,active_gain_mode;reg [2:0] stage_profile;
 function automatic [3:0] bw_profile(input [31:0] bw);
  case(bw)
   200000:bw_profile=0;500000:bw_profile=1;1000000:bw_profile=2;2000000:bw_profile=3;
   5000000:bw_profile=4;10000000:bw_profile=5;15000000:bw_profile=6;20000000:bw_profile=7;
   default:bw_profile=15;
  endcase
 endfunction
 reg [31:0] stage_fs,active_fs;reg stage_decim;
 reg [2:0] rf_state;
 reg [31:0] last_error,tx_bandwidth,tx_snr;reg signed [31:0] noise_low,noise_high;
 reg [3:0] operation;
 reg [31:0] operation_timer,settle_timer;
 // Hard upper bound while a radio script is still running past its budget.
 reg [39:0] hard_timer;reg overrun;
 reg op_done_seen,wait_radio;reg [3:0] op_grace;
 reg [1:0] resume_mask;reg tx_retune;
 // 0x105 result, reported as tx_snapshot word 0 (schema stays 1 for others):
 // {8'h52('R'),write,5'd0,address[9:0],data[7:0]} (32 bits) of the completed access.
 reg [31:0] reg_result;
 wire [7:0] version=request[991-:8];
 wire [31:0] rid=request[959-:32],cfg_id=request[927-:32],req_boot=request[831-:32];
 wire [15:0] opcode=request[895-:16];
 wire [31:0] payload_bytes=request[863-:32];
 wire read_only=(version==1&&(opcode==5||opcode==6))||
                (version==2&&(opcode==16'h102||opcode==16'h103||opcode==16'h104));
 function automatic [31:0] u32(input integer offset);u32=request[1023-8*offset-:32];endfunction
 function automatic [15:0] u16(input integer offset);u16=request[1023-8*offset-:16];endfunction
 function automatic [63:0] u64(input integer offset);u64=request[1023-8*offset-:64];endfunction
 function automatic [31:0] crc_byte(input [31:0] c,input [7:0] b);
  reg [31:0] v;integer k;begin v=c^b;for(k=0;k<8;k=k+1)v=(v>>1)^(v[0]?32'hedb88320:0);crc_byte=v;end
 endfunction
 wire [15:0] flags={11'd0,active_gain_mode,(rf_state==2),link_up,radio_ready&&!radio_fault&&!data_fault};
 wire [767:0] snapshot={
  {5'd0,rf_state},24'd0,active_id,capture_id,(has_active?32'd1:32'd0),active_lo,
  (has_active?32'd25000000:32'd0),active_fs,(has_active?active_bw:32'd0),32'd0,
  (has_active?(active_gain_mode==0?active_gain:32'h80000000):32'd0),(has_active?(active_fs==1000000?32'd25:32'd1):32'd0),
  (has_active?32'd1024:32'd0),(has_active?16'd1024:16'd0),flags,last_error,fifo_points,
  sample_count,datagrams,drop_windows,overflow_events};
 reg [511:0] dsp_wire_order;
 always @*for(integer n=0;n<16;n=n+1)dsp_wire_order[511-32*n-:32]=dsp_config[32*n+:32];
 // Bit 6: last TX quadrature calibration did not converge (non-fatal);
 // bits 8:7: its mode (0 default phase, 1 last phase, 2 search, 3 none).
 wire [31:0] radio_flags={23'd0,quad_mode,quad_warn,(boot_id==0),data_fault,radio_fault,radio_busy,radio_ready,link_up};
 wire [31:0] tx_word0=(version==2&&opcode==16'h105&&response_status==0)?reg_result:32'd1;
 wire [1023:0] tx_snapshot={tx_word0,radio_lo,tx_bandwidth,tx_snr,30'd0,requested_mask,30'd0,applied_mask,
  7'd0,attenuation1,7'd0,attenuation2,radio_flags,16'd0,radio_fault_index,
  clip_count1,clip_count2,noise_low,noise_high,dsp_wire_order,uart_request_high,capture_high};
 // Optional RX-only discovery extension; legacy opcodes and snapshots stay v1.
 // A 100BASE-TX peer cannot carry the 25 MSPS IQ stream.  Enforce the
 // 1 MSPS decimated stream whenever the MAC reports speed=01; the 25 MSPS
 // path remains available on gigabit links for PC capture.  The discovery
 // field below remains the AD9361 ADC rate (25 MSPS), not the network rate.
 wire link_100m=(link_speed==2'b01);
 wire [255:0] rx_info={32'd1,request_high,config_high,capture_high,
  32'd25000000,32'd20000000,32'd10000,32'h0017001f}; // modes[31:16]: firmware 23
 // Firmware 13: MDIO read sampling fix (PHY now configurable over MDIO).
 // Firmware 15: RX LVDS sampling phase 166.5 deg; manual gain index written
 // after FDD and skipped in AGC (HW14 = 14 behaviour still reported 13).
 // Firmware 16: RFCT v2 0x105 single AD9361 register access (REG_DEBUG);
 // RX retune no longer checks 0x109 (fails after AGC).
 // Firmware 17: TX_DELAY 0x0A from the HW16 0x007 sweep; 0x105 locked (REG_DEBUG=0).
 // Firmware 18: SSB TX1 noise centred on the sideband (waveform_core cfg[4]); cfg[11]=0 disables TX1 noise.
 // Firmware 19: TX quadrature non-convergence is a warning (0x102 flags bit 6),
 // ADI tracking/quad setup around runtime TX calibration, 1 s live lock checks,
 // 30 s TX apply budget that waits for a running script, 0x100 accepted after HW_TIMEOUT.
 // Firmware 20: RX words +1 LSB before the FIFO (AD9361 -1.06 LSB DC); RTL8211F
 // PHYSR read from page 0xa43 reg 26 (MDIO link flag); diagnostics schema "HW20".
 // Firmware 21: TX1 offset (cfg[6]) is the centre of the occupied band for every
 // modulation; SSB rotates its carrier to cfg[6]-cfg[4] (waveform_core). Schema "HW21".
 // Firmware 22: replay-cache slots are reused once superseded on their transport
 // (the cache no longer fills during long command bursts), 256 slots (was 128);
 // IQ buffer 32 windows, RX FIFO 8192, Ethernet FIFOs doubled. Schema "HW22".
 // Firmware 23: 0x100 bandwidth is the one-sided baseband bandwidth B (5 kHz..10 MHz;
 // RF occupancy 2B, SSB B); cfg[6] is the carrier again for SSB (HW20 placement). Schema "HW23".
 // version_info word 4 bit 9 advertises 0x105.
 wire [1023:0] version_info={32'h4b553550,32'd23,32'd25000000,32'd20000000,
  (REG_DEBUG?32'h000003ff:32'h000001ff),32'd7,startup_diagnostics,800'd0};
 // A radio script reports its own per-step timeouts; never answer HW_TIMEOUT
 // while it is still running. Once the budget has expired under a running
 // script (overrun), the rest of the operation is bounded by the 60 s limit.
 wire op_expired=hard_timer==0||(operation_timer==0&&!radio_busy&&!overrun);
 wire finish_now=operation!=0 && (
  (operation==4 && (packet_idle||operation_timer==0)) ||
  (operation!=4 && (((radio_fault||data_fault)&&op_grace==0)||op_expired)) ||
  (operation==2 && settle_timer==0&&packet_idle) ||
  (operation==6 && dsp_ack==dsp_toggle) ||
  (operation==8 && (radio_done||op_done_seen)&&!radio_busy) ||
  (operation==11 && reg_done));
 // Startup identity failures must remain observable over either transport.
 // Commands with effects are rejected below until a committed epoch exists.
 assign command_ready=state==IDLE&&!finish_now;
 assign reply_uart=request_uart;
 assign hdr_valid=state==HEADER;
 assign reply_length={8'd0,response_size};
 assign data=response[1279-8*pos-:8];
 assign valid=state==PAYLOAD;
 assign last=pos==response_size-1;
 task automatic reply(input [15:0] status);
  begin response_status<=status;state<=BUILD;end
 endtask
 task automatic defer(input [3:0] op);
  begin
   pending_request<=request;pending_length<=req_length;pending_slot<=reply_slot;pending_uart<=request_uart;
   // A TX apply (9) chains gate, TX script, bandwidth and calibration scripts.
   operation<=op;operation_timer<=(op==5||op==9)?CLOCK_HZ*30:CLOCK_HZ*5;hard_timer<=CLOCK_HZ*40'd60;overrun<=0;
   op_done_seen<=0;op_grace<=15;state<=IDLE;
  end
 endtask
 task automatic finish_operation(input [15:0] status);
  begin
   request<=pending_request;req_length<=pending_length;reply_slot<=pending_slot;request_uart<=pending_uart;
   cache_reply<=1;operation<=0;response_status<=status;state<=BUILD;
   if(status!=0)last_error<=status;
  end
 endtask
 always @(posedge clk)begin
  radio_apply<=0;radio_rx_apply<=0;radio_tx_apply<=0;gate_start<=0;reg_start<=0;
  if(rst)begin
   reg_write<=0;reg_address<=0;reg_wdata<=0;reg_result<=32'd1;
   state<=IDLE;request<=0;pending_request<=0;req_length<=0;pending_length<=0;request_uart<=0;pending_uart<=0;cache_uart<=0;
   response_status<=0;response<=0;response_size<=128;pos<=0;crc_acc<=32'hffffffff;
   cache_reply<=0;reply_slot<=0;pending_slot<=0;head<=0;scan_index<=0;found_index<=0;
   found<=0;conflict<=0;pending_duplicate<=0;occupied<=0;completed<=0;
   seconds<=0;second_ticks<=0;request_high<=0;uart_request_high<=0;
   stage_id<=0;active_id<=0;config_high<=0;capture_high<=0;
   stage_rf<=0;stage_stream<=0;has_active<=0;stage_lo<=0;active_lo<=0;
   stage_bw<=20000000;active_bw<=20000000;stage_gain<=10000;active_gain<=10000;
   stage_gain_mode<=0;active_gain_mode<=0;stage_profile<=7;
   radio_rx_profile<=7;radio_rx_gain_mode<=0;radio_rx_gain<=10000;
   stage_fs<=0;active_fs<=0;stage_decim<=0;rf_state<=0;last_error<=0;
   operation<=0;operation_timer<=0;hard_timer<=0;overrun<=0;settle_timer<=0;op_done_seen<=0;wait_radio<=0;op_grace<=0;
   resume_mask<=0;tx_retune<=0;
   radio_lo<=64'd2400000000;radio_rx_lo<=64'd2400000000;requested_mask<=0;digital_mask<=0;attenuation1<=359;attenuation2<=359;
   dsp_config<=0;dsp_toggle<=0;capture_run<=0;decimate25<=1;capture_id<=0;fs_eff_hz<=1000000;
   tx_bandwidth<=1000000;tx_snr<=10000;noise_low<=-500000;noise_high<=500000;
  end else begin
   if(second_ticks==CLOCK_HZ-1)begin second_ticks<=0;seconds<=seconds+1;end else second_ticks<=second_ticks+1;
   if(operation_timer!=0)operation_timer<=operation_timer-1;
   if(hard_timer!=0)hard_timer<=hard_timer-1;
   if(operation!=0&&operation_timer==0&&radio_busy)overrun<=1;
   if(op_grace!=0)op_grace<=op_grace-1;
   if(settle_timer!=0)settle_timer<=settle_timer-1;
   if(operation!=0&&radio_done)op_done_seen<=1;
   if(radio_fault||data_fault)begin digital_mask<=0;capture_run<=0;if(rf_state==2)begin rf_state<=4;last_error<=8;end end
   case(state)
    IDLE:begin
     // Complete a deferred hardware operation before consuming another request.
     if(operation!=0)begin
      if(operation==4)begin // STOP drains all complete committed windows.
       if(packet_idle)begin rf_state<=0;finish_operation(0);end
       else if(operation_timer==0)begin rf_state<=4;finish_operation(7);end
      end else if(((radio_fault||data_fault)&&op_grace==0)||op_expired)begin
       capture_run<=0;digital_mask<=0;rf_state<=4;
       stage_id<=0;stage_rf<=0;stage_stream<=0;
       finish_operation(((radio_fault||data_fault)&&op_grace==0)?8:7);
      end else case(operation)
       1:begin // START: retune only if needed, then discard settling samples.
        if(radio_ready&&!radio_busy&&(!wait_radio||op_done_seen))begin settle_timer<=CLOCK_HZ/1000;operation<=2;end
       end
       2:if(settle_timer==0&&packet_idle)begin
        active_id<=stage_id;config_high<=stage_id;active_lo<=stage_lo;active_fs<=stage_fs;
        active_bw<=stage_bw;active_gain<=stage_gain;active_gain_mode<=stage_gain_mode;
        capture_id<=pending_request[767-:32];fs_eff_hz<=stage_fs;decimate25<=stage_decim;
        has_active<=1;stage_rf<=0;stage_stream<=0;stage_id<=0;
        capture_run<=1;rf_state<=2;finish_operation(0);
       end
       5:if(radio_ready&&!radio_busy&&op_done_seen)begin dsp_toggle<=~dsp_toggle;operation<=6;end
       6:if(dsp_ack==dsp_toggle)begin requested_mask<=resume_mask;operation<=7;end
       7:if(radio_ready&&!radio_busy)begin gate_start<=1;op_done_seen<=0;operation<=8;end
       8:if((radio_done||op_done_seen)&&!radio_busy)begin digital_mask<=applied_mask;finish_operation(0);end
       11:if(reg_done)begin
        reg_result<={8'h52,reg_write,5'd0,reg_address,reg_write?reg_wdata:reg_rdata};finish_operation(0);
       end
       9:if(radio_ready&&!radio_busy)begin gate_start<=1;op_done_seen<=0;operation<=10;end
       10:if(op_done_seen&&!radio_busy)begin
        op_done_seen<=0;
        if(tx_retune)begin radio_tx_apply<=1;operation<=5;end
        else begin dsp_toggle<=~dsp_toggle;operation<=6;end
       end
       default:begin end
      endcase
     end
     // Accept GET_STATUS while initialization/calibration/gating is pending.
     if(command_valid&&command_ready)begin
      // Completion has priority; a mailbox is accepted only on a free cycle.
      request<=command_bytes;req_length<=command_length;found<=0;conflict<=0;pending_duplicate<=0;
      request_uart<=command_uart;
      scan_index<=0;skipped<=0;cache_reply<=0;state<=LOOKUP;
     end
    end
    LOOKUP:begin
     if(occupied[scan_index]&&cache_id[scan_index]==rid&&cache_uart[scan_index]==request_uart)begin
      found<=1;found_index<=scan_index;
      conflict<=cache_request[scan_index]!=request||cache_length[scan_index]!=req_length;
      pending_duplicate<=!completed[scan_index];
     end
     if(scan_index==CACHE_N-1)state<=DECIDE;else scan_index<=scan_index+1;
    end
    DECIDE:begin
     if((request_uart&&version!=2)||(!request_uart&&version!=1))reply(5);
     else if(boot_id==0&&!read_only)reply(8);
     else if(req_boot!=boot_id&&!(cfg_id==0&&req_boot==0&&
       ((version==1&&(opcode==5||opcode==6))||(version==2&&opcode==16'h102))))reply(9);
     else if(found)begin
      if(conflict)reply(10);
      else if(pending_duplicate)state<=IDLE;
      else begin reply_slot<=found_index;state<=LOAD_CACHE;end
     end else if(read_only)begin
      // Queries have no hardware effects. Rebuild their current snapshot on
      // every retry, without occupying the 60-second command replay cache.
      if(request_uart)begin if(rid>uart_request_high)uart_request_high<=rid;end
      else if(rid>request_high)request_high<=rid;
      state<=EXECUTE;
     end else if(rid<=(request_uart?uart_request_high:request_high))reply(11);
     // HW22: a completed slot is reusable once a newer request (any opcode) has
     // been seen on its transport. Clients retry only their latest ID, so at
     // most the newest slot per transport plus the deferred operation stay
     // live, and the cache cannot fill however long commands keep coming.
     // (HW21 held every slot for 60 s; a batch with observation filled all
     // 128 in ~40 s.) A live slot at head is stepped over, one per cycle.
     else if(occupied[head]&&(!completed[head]||(seconds-cache_time[head]<60&&
       cache_id[head]>=(cache_uart[head]?uart_request_high:request_high))))begin
      // Report overload explicitly; do not execute or advance high-water.
      if(skipped==CACHE_N-1)reply(6);
      else begin head<=head+1;skipped<=skipped+1;end
     end else begin
      if(request_uart)uart_request_high<=rid;else request_high<=rid;
      cache_uart[head]<=request_uart;cache_request[head]<=request;cache_length[head]<=req_length;
      cache_id[head]<=rid;occupied[head]<=1;completed[head]<=0;
      reply_slot<=head;head<=head+1;cache_reply<=1;state<=EXECUTE;
     end
    end
    LOAD_CACHE:begin response<=cache_response[reply_slot];response_size<=cache_size[reply_slot];state<=HEADER;pos<=0;end
    EXECUTE:begin
     if(payload_bytes+32!=req_length)reply(2);
     else if(version==1)begin
      case(opcode)
       5,6:if(payload_bytes!=0)reply(2);else if(cfg_id!=0)reply(3);else reply(0);
       4:if(payload_bytes!=0)reply(2);else if(cfg_id!=0)reply(3);
         else if(operation!=0)reply(6);else begin
          capture_run<=0;stage_id<=0;stage_rf<=0;stage_stream<=0;rf_state<=3;defer(4);
         end
       1,2,3:begin
        if((opcode==1&&payload_bytes!=24)||(opcode==2&&payload_bytes!=28)||(opcode==3&&payload_bytes!=4))reply(2);
        else if(cfg_id==0)reply(3);
        else if(operation!=0)reply(6);
        else if(rf_state!=0)reply(4);
        else if(cfg_id<=config_high)reply(12);
        // A newer SET_RF replaces an abandoned staging sequence. Other
        // commands may never mix fields from two configuration IDs.
        else if(stage_id!=0&&stage_id!=cfg_id&&!(opcode==1&&cfg_id>stage_id))reply(12);
        else if(opcode==1)begin
         if(u64(32)<64'd300000000||u64(32)>64'd6000000000||u32(40)==0||u32(44)==0||u16(54)!=0||u16(52)>16'h0200||(u16(52)&16'h00ff)!=0)reply(3);
         else if(u32(40)!=25000000||bw_profile(u32(44))==15)reply(5);
         else if(u16(52)==0&&($signed(u32(48))%1000!=0||
          $signed(u32(48))<(u64(32)<=64'd1300000000 ?-1000:u64(32)<=64'd4000000000 ?-3000:-10000)||
          $signed(u32(48))>(u64(32)<=64'd1300000000 ?73000:u64(32)<=64'd4000000000 ?71000:62000)))reply(3);
         else begin
          if(stage_id!=cfg_id)stage_stream<=0;
          stage_lo<=u64(32);stage_rf<=1;stage_id<=cfg_id;reply(0);
          stage_bw<=u32(44);stage_gain<=u32(48);stage_gain_mode<=u16(52)>>8;stage_profile<=bw_profile(u32(44));
         end
        end else if(opcode==2)begin
         if(u32(32)!=1||u32(44)!=0||u32(48)!=1024||u16(52)!=1024||u16(54)!=0||u32(56)!=0)reply(5);
         else if(!((u32(36)==1000000&&u32(40)==25)||(u32(36)==25000000&&u32(40)==1)))reply(5);
         else if(link_100m&&u32(36)!=1000000)reply(5);
         else begin stage_fs<=u32(36);stage_decim<=u32(40)==25;stage_stream<=1;stage_id<=cfg_id;reply(0);end
        end else begin
         if(u32(32)==0)reply(3);
         else if(u32(32)<=capture_high)reply(13);
         else if(!stage_rf||!stage_stream||stage_id!=cfg_id)reply(12);
         else if(!packet_idle||radio_busy)reply(6);
         else if(!radio_ready||radio_fault||data_fault)reply(8);
         else begin
          // Identify an accepted START even if its deferred retune fails.
          capture_high<=u32(32);capture_id<=u32(32);rf_state<=1;
          wait_radio<=radio_rx_lo!=stage_lo||radio_rx_profile!=stage_profile||radio_rx_gain_mode!=stage_gain_mode||radio_rx_gain!=stage_gain;
          if(radio_rx_lo!=stage_lo||radio_rx_profile!=stage_profile||radio_rx_gain_mode!=stage_gain_mode||radio_rx_gain!=stage_gain)radio_rx_apply<=1;
          radio_rx_lo<=stage_lo;radio_rx_profile<=stage_profile;radio_rx_gain_mode<=stage_gain_mode;
          radio_rx_gain<=stage_gain;
          defer(1);
         end
        end
       end
       default:reply(1);
      endcase
     end else if(version==2)begin
      case(opcode)
       16'h102,16'h103,16'h104:if(payload_bytes!=0)reply(2);else if(cfg_id!=0)reply(3);else reply(0);
       16'h100:begin
        if(payload_bytes!=96)reply(2);
        else if(operation!=0)reply(6);
        // rf_state 4 (after HW_TIMEOUT or a fault) must stay recoverable over UART alone.
        else if(rf_state!=0&&rf_state!=2&&rf_state!=4)reply(4);
        else if(u64(32)<64'd300000000||u64(32)>64'd6000000000||u32(40)<5000||u32(40)>10000000||
         $signed(u32(44))< -10000||$signed(u32(44))>20000||u16(48)>359||u16(50)>359||
         $signed(u32(52))< -10000000||$signed(u32(56))>10000000||
         $signed(u32(56))-$signed(u32(52))<10000||$signed(u32(56))-$signed(u32(52))>20000000||
         u32(60)>8||u32(64)<1||u32(64)>8||
         (u32(60)==5&&!(u32(64)==4||u32(64)==6||u32(64)==8))||
         (u32(60)>=2&&u32(60)<=4&&u32(64)>4)||u32(112)==0||
         (u32(60)==0&&u32(116)>32768)||(u32(60)>=7&&u32(120)>1)||u32(124)!=0)reply(3);
        else if(radio_busy&&!radio_fault)reply(6);
        else begin
         digital_mask<=0;requested_mask<=0;radio_lo<=u64(32);
         resume_mask<=applied_mask;tx_retune<=radio_lo!=u64(32);
         attenuation1<=u16(48);attenuation2<=u16(50);tx_bandwidth<=u32(40);tx_snr<=u32(44);
         noise_low<=u32(52);noise_high<=u32(56);
         for(integer n=0;n<16;n=n+1)dsp_config[32*n+:32]<=u32(60+4*n);
         if(radio_fault||data_fault)begin
          // Explicit fault recovery resets the radio; a fault already revoked RX.
          capture_run<=0;rf_state<=0;stage_id<=0;stage_rf<=0;stage_stream<=0;
          radio_rx_lo<=u64(32);radio_apply<=1;resume_mask<=0;defer(5);
          radio_rx_profile<=7;radio_rx_gain_mode<=0;radio_rx_gain<=10000;
         end else begin
          // A timed-out operation already revoked RX; release the RX state.
          if(rf_state==4)begin rf_state<=0;stage_id<=0;stage_rf<=0;stage_stream<=0;end
          defer(9);
         end
        end
       end
       // Bench-only raw register access: payload {u16 address, u8 write, u8 data}.
       // Accepted only over UART, with RF ready and idle (no script running).
       16'h105:if(!REG_DEBUG||!request_uart)reply(5);
        else if(payload_bytes!=4)reply(2);
        else if(u16(32)>16'h03ff||request[1023-8*34-:8]>8'd1)reply(3);
        else if(operation!=0||radio_busy)reply(6);
        else if(!radio_ready||radio_fault||data_fault)reply(8);
        else begin
         reg_address<=u16(32);reg_write<=request[1023-8*34-7];reg_wdata<=request[1023-8*35-:8];
         reg_start<=1;defer(11);
        end
       16'h101:if(payload_bytes!=4)reply(2);
        else if(u32(32)>3)reply(3);
        else if(operation!=0)reply(6);
        else if(!radio_ready||radio_fault||data_fault||(u32(32)!=0&&dsp_config[13*32+:32]==0))reply(8);
        // Disable removed channels immediately; leave an unchanged channel live.
        // Newly enabled channels remain digitally muted until SPI readback.
        else begin requested_mask<=u32(32);digital_mask<=digital_mask&u32(32);defer(7);end
       default:reply(1);
      endcase
     end else reply(5);
    end
    BUILD:begin
     response<=0;response_size<=version==2?160:(opcode==6?64:128);pos<=0;crc_acc<=32'hffffffff;
     response[1279-:256]<={32'h52464354,version,8'd1,16'd32,rid,cfg_id,opcode,response_status,
       (version==2?32'd128:(opcode==6?32'd32:32'd96)),boot_id,32'd0};
     if(version==2)response[1023:0]<=opcode==16'h103 ? hardware_diagnostics : opcode==16'h104 ? version_info:tx_snapshot;
     else if(opcode==6)response[1023-:256]<=rx_info;
     else response[1023-:768]<=snapshot;
     state<=CRC;
    end
    CRC:begin
     crc_acc<=crc_byte(crc_acc,response[1279-8*pos-:8]);
     if(pos==response_size-1)begin
      response[1055-:32]<=~crc_byte(crc_acc,response[1279-8*pos-:8]);pos<=0;state<=HEADER;
     end else pos<=pos+1;
    end
    HEADER:begin
     if(cache_reply)begin
      cache_response[reply_slot]<=response;cache_size[reply_slot]<=response_size;
      cache_time[reply_slot]<=seconds;completed[reply_slot]<=1;cache_reply<=0;
     end
     if(hdr_ready)begin pos<=0;state<=PAYLOAD;end
    end
    PAYLOAD:if(ready)begin if(last)state<=IDLE;else pos<=pos+1;end
    default:state<=IDLE;
   endcase
  end
 end
endmodule
