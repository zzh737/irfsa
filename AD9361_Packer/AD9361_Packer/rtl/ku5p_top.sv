// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
module ku5p_top(
 input wire sys_clk_p,sys_clk_n,reset_n,
 input wire uart_rx,output wire uart_tx,
 output wire [1:0] led,
 input wire rgmii_rxc,rgmii_rx_ctl,input wire [3:0] rgmii_rxd,
 output wire rgmii_txc,rgmii_tx_ctl,output wire [3:0] rgmii_txd,
 output wire phy_mdc,inout wire phy_mdio,eeprom_scl,eeprom_sda,
 input wire ad_data_clk_p,ad_data_clk_n,ad_rx_frame_p,ad_rx_frame_n,
 input wire [5:0] ad_rx_data_p,ad_rx_data_n,
 output wire ad_fb_clk_p,ad_fb_clk_n,ad_tx_frame_p,ad_tx_frame_n,
 output wire [5:0] ad_tx_data_p,ad_tx_data_n,
 output wire ad_enable,ad_txnrx,ad_en_agc,ad_sync_in,ad_resetb,
 output wire ad_spi_cs_n,ad_spi_clk,ad_spi_mosi,input wire ad_spi_miso
);
 wire sys_clock,feedback,feedback_buf,clock125_raw,clock_tx_raw,clk,tx_clk,tx_clk90,locked;
 wire delay_ref_raw,delay_ref,delay_ready;
 IBUFDS sys_ibuf(.I(sys_clk_p),.IB(sys_clk_n),.O(sys_clock));
 // VCO 1000 MHz: CLKOUT2 = 333.33 MHz IDELAYCTRL reference for RGMII RX.
 MMCME4_BASE #(.CLKIN1_PERIOD(5.0),.CLKFBOUT_MULT_F(5.0),.DIVCLK_DIVIDE(1),
  .CLKOUT0_DIVIDE_F(8.0),.CLKOUT1_DIVIDE(4),.CLKOUT1_PHASE(0.0),.CLKOUT2_DIVIDE(3)) mmcm(
  .CLKIN1(sys_clock),.CLKFBIN(feedback_buf),.CLKFBOUT(feedback),.CLKFBOUTB(),
  .CLKOUT0(clock125_raw),.CLKOUT0B(),.CLKOUT1(clock_tx_raw),.CLKOUT1B(),
  .CLKOUT2(delay_ref_raw),.CLKOUT2B(),.CLKOUT3(),.CLKOUT3B(),.CLKOUT4(),.CLKOUT5(),.CLKOUT6(),
  .LOCKED(locked),.PWRDWN(1'b0),.RST(!reset_n));
 BUFG fb_buf(.I(feedback),.O(feedback_buf));
 BUFG c0_buf(.I(clock125_raw),.O(clk));
 BUFG delay_ref_buf(.I(delay_ref_raw),.O(delay_ref));
 // Calibrates the fixed TIME-mode IDELAYE3 taps in us_ssio.sv (VT tracking).
 // Vivado replicates it per used bank; reset after MMCM lock (>=52 ns).
 (* ASYNC_REG="TRUE" *) reg [5:0] delay_ctrl_reset=6'h3f;
 always @(posedge delay_ref or negedge locked)
  if(!locked)delay_ctrl_reset<=6'h3f;else delay_ctrl_reset<={delay_ctrl_reset[4:0],1'b0};
 IDELAYCTRL #(.SIM_DEVICE("ULTRASCALE")) rgmii_delay_ctrl(
  .REFCLK(delay_ref),.RST(delay_ctrl_reset[5]),.RDY(delay_ready));
 // Both TX clocks share one MMCM output. Opposite 250 MHz input edges
 // produce 125 MHz clocks separated by 2 ns, without inter-output phase error.
 // Release both dividers just after a falling input edge so the data divider
 // starts first. A fresh MMCM lock or reset always re-establishes this order.
 (* ASYNC_REG="TRUE" *) reg [3:0] tx_div_reset=15;
 always @(negedge clock_tx_raw or negedge reset_n or negedge locked)
  if(!reset_n||!locked)tx_div_reset<=15;
  else tx_div_reset<={tx_div_reset[2:0],1'b0};
 BUFGCE_DIV #(.BUFGCE_DIVIDE(2)) tx_buf(
  .I(clock_tx_raw),.CE(1'b1),.CLR(tx_div_reset[3]),.O(tx_clk));
 BUFGCE_DIV #(.BUFGCE_DIVIDE(2),.IS_I_INVERTED(1'b1)) tx90_buf(
  .I(clock_tx_raw),.CE(1'b1),.CLR(tx_div_reset[3]),.O(tx_clk90));
 (* ASYNC_REG="TRUE" *) reg [3:0] reset_pipe=15;
 always @(posedge clk or negedge reset_n or negedge locked)
  if(!reset_n||!locked)reset_pipe<=15;else reset_pipe<={reset_pipe[2:0],1'b0};
 wire rst=reset_pipe[3];
 wire io_start,io_write,io_done,io_fault,io_busy;wire [12:0] io_address;wire [7:0] io_data,io_read;
 wire boot_ready,boot_fault;wire [31:0] boot_id;
 eeprom_i2c eeprom(clk,rst,io_start,io_write,io_address,io_data,io_done,io_fault,io_read,io_busy,eeprom_scl,eeprom_sda);
 boot_journal journal(clk,rst,boot_ready,boot_fault,boot_id,io_start,io_write,io_address,io_data,io_done,io_fault,io_read);
 wire phy_ready,phy_fault,phy_link;wire [1:0] speed;
 wire [255:0] phy_diagnostics,radio_diagnostics;
 wire [127:0] radio_interface_registers;
 wire [31:0] phy_wire_diagnostics;
 rtl8211f_init phy(clk,rst,phy_mdc,phy_mdio,phy_ready,phy_fault,phy_link,phy_diagnostics,phy_wire_diagnostics);
 // The 悟净 peer is 100-Mbps.  Keep the PHY/MDIO status valid for both
 // 100-Mbps (speed=01) and gigabit (speed=10) RGMII operation.
 wire link_up=phy_ready&&!phy_fault&&phy_link&&(speed==1||speed==2);
 wire command_valid,command_ready;wire [1023:0] command_bytes;wire [15:0] command_length;wire [31:0] bad_commands;
 wire chv,chr,cv,cr,cl;wire [7:0] cd;wire [15:0] clen;
 wire ctl_command_valid,ctl_command_ready,ctl_command_uart,ctl_reply_uart;
 wire [1023:0] ctl_command_bytes;wire [15:0] ctl_command_length;
 wire ctl_hv,ctl_hr,ctl_v,ctl_r,ctl_last;wire [7:0] ctl_data;wire [15:0] ctl_length;
 control_transport transports(.clk(clk),.rst(rst),.uart_rx(uart_rx),.uart_tx(uart_tx),
  .net_command_valid(command_valid),.net_command_ready(command_ready),.net_command_bytes(command_bytes),.net_command_length(command_length),
  .command_valid(ctl_command_valid),.command_ready(ctl_command_ready),.command_uart(ctl_command_uart),
  .command_bytes(ctl_command_bytes),.command_length(ctl_command_length),
  .reply_uart(ctl_reply_uart),.hdr_valid(ctl_hv),.hdr_ready(ctl_hr),.reply_length(ctl_length),
  .data(ctl_data),.valid(ctl_v),.ready(ctl_r),.last(ctl_last),
  .net_hdr_valid(chv),.net_hdr_ready(chr),.net_length(clen),.net_data(cd),.net_valid(cv),.net_ready(cr),.net_last(cl));
 wire ihv,ihr,iv,ir,il;wire [7:0] idata;wire net_overflow,net_underflow,arp_failed;
 network_core network(.clk(clk),.tx_clk(tx_clk),.tx_clk90(tx_clk90),.rst(rst),
  .rgmii_rxc(rgmii_rxc),.rgmii_rx_ctl(rgmii_rx_ctl),.rgmii_rxd(rgmii_rxd),
  .rgmii_txc(rgmii_txc),.rgmii_tx_ctl(rgmii_tx_ctl),.rgmii_txd(rgmii_txd),.link_speed(speed),
  .command_valid(command_valid),.command_ready(command_ready),.command_bytes(command_bytes),.command_length(command_length),.bad_commands(bad_commands),
  .ctl_hdr_valid(chv),.ctl_hdr_ready(chr),.ctl_length(clen),.ctl_data(cd),.ctl_valid(cv),.ctl_ready(cr),.ctl_last(cl),
  .iq_hdr_valid(ihv),.iq_hdr_ready(ihr),.iq_data(idata),.iq_valid(iv),.iq_ready(ir),.iq_last(il),
  .rx_overflow(net_overflow),.tx_underflow(net_underflow),.arp_failed(arp_failed));
 wire radio_ready,radio_fault,radio_done,radio_busy,radio_apply,gate_start;
 wire [63:0] radio_lo;wire [1:0] requested_mask,digital_mask,applied_mask;wire [8:0] attenuation1,attenuation2;
 wire radio_rx_apply,radio_tx_apply;wire [63:0] radio_rx_lo;
 wire [2:0] radio_rx_profile;wire [1:0] radio_rx_gain_mode;wire signed [31:0] radio_rx_gain;
 wire [15:0] radio_index;wire [7:0] rx_delay,tx_delay;wire [4:0] quad_phase;wire quad_warn;wire [1:0] quad_mode;
 wire fir_fault1,fir_fault2;
 wire reg_start,reg_write,reg_done;wire [9:0] reg_address;wire [7:0] reg_wdata,reg_rdata;
 wire data_fault=fir_fault1||fir_fault2;
 ad9361_radio radio(.clk(clk),.rst(rst),.apply(radio_apply),.lo_hz(radio_lo),.emergency_abort(data_fault),
  .rx_apply(radio_rx_apply),.rx_lo_hz(radio_rx_lo),
  .rx_profile(radio_rx_profile),.rx_gain_mode(radio_rx_gain_mode),.rx_gain_mdb(radio_rx_gain),
  .tx_apply(radio_tx_apply),
  .gate_start(gate_start),.requested_mask(requested_mask),.attenuation1(attenuation1),.attenuation2(attenuation2),
  .reg_start(reg_start),.reg_write(reg_write),.reg_address(reg_address),.reg_wdata(reg_wdata),
  .reg_done(reg_done),.reg_rdata(reg_rdata),
  .ready(radio_ready),.fault(radio_fault),.done(radio_done),.busy(radio_busy),.applied_mask(applied_mask),
  .resetb(ad_resetb),.spi_cs_n(ad_spi_cs_n),.spi_sclk(ad_spi_clk),.spi_mosi(ad_spi_mosi),.spi_miso(ad_spi_miso),
  .fault_index(radio_index),.rx_delay(rx_delay),.tx_delay(tx_delay),.quad_phase(quad_phase),
  .diagnostics(radio_diagnostics),.interface_registers(radio_interface_registers),
  .quad_warn(quad_warn),.quad_mode(quad_mode));
 assign ad_enable=1'b0;assign ad_txnrx=1'b0;assign ad_en_agc=1'b0;assign ad_sync_in=1'b0; // ENSM controlled through SPI
 wire data_clk,data_reset,rx_valid,frame_error,sample_strobe;wire [47:0] rx_iq,tx_iq;
 wire lvds_locked,lvds_reset_source,lvds_unlock_source;
 wire [1:0] rx_frame_pair;
 (* ASYNC_REG="TRUE" *)reg [1:0] lvds_lock_sync,lvds_reset_sync,lvds_unlock_sync;
 always @(posedge clk)begin
  lvds_lock_sync<={lvds_lock_sync[0],lvds_locked};
  lvds_reset_sync<={lvds_reset_sync[0],lvds_reset_source};
  lvds_unlock_sync<={lvds_unlock_sync[0],lvds_unlock_source};
  if(rst)begin lvds_lock_sync<=0;lvds_reset_sync<=3;lvds_unlock_sync<=3;end
 end
 wire [31:0] clock_diagnostics={lvds_lock_sync[1],(lvds_reset_sync[1]||lvds_unlock_sync[1]),30'd0};
 wire wave_valid;wire signed [11:0] wi1,wq1,wi2,wq2;
 wire [31:0] clips1,clips2;wire [511:0] dsp_config;wire dsp_toggle;reg dsp_ack;
 (* ASYNC_REG="TRUE" *) reg [1:0] req_sync,ready_sync,ack_sync;
 (* ASYNC_REG="TRUE" *) reg [1:0] mask0_sync,mask1_sync;
 wire fv1,fv2,fc1,fc2;wire signed [15:0] fi1,fq1,fi2,fq2;
 ad9361_lvds lvds(.reset_async(!ad_resetb),
  .data_clk_p(ad_data_clk_p),.data_clk_n(ad_data_clk_n),.rx_frame_p(ad_rx_frame_p),.rx_frame_n(ad_rx_frame_n),
  .rx_data_p(ad_rx_data_p),.rx_data_n(ad_rx_data_n),.fb_clk_p(ad_fb_clk_p),.fb_clk_n(ad_fb_clk_n),
  .tx_frame_p(ad_tx_frame_p),.tx_frame_n(ad_tx_frame_n),.tx_data_p(ad_tx_data_p),.tx_data_n(ad_tx_data_n),
  .clk(data_clk),.reset(data_reset),.rx_valid(rx_valid),.frame_error(frame_error),.rx_iq(rx_iq),
  .tx_iq(tx_iq),.tx_valid(wave_valid),.sample_strobe(sample_strobe),
  .clock_is_locked(lvds_locked),.rx_frame_pair(rx_frame_pair),
  .reset_source(lvds_reset_source),.unlock_source(lvds_unlock_source));
 reg [511:0] held_config;reg config_req;reg [20:0] warm_timer;reg [3:0] wave_reset;
 (* ASYNC_REG="TRUE" *)reg [3:0] mailbox_reset_pipe=15;
 always @(posedge data_clk or posedge rst)
  if(rst)mailbox_reset_pipe<=15;else mailbox_reset_pipe<={mailbox_reset_pipe[2:0],1'b0};
 wire mailbox_reset=mailbox_reset_pipe[3];
 reg ready_source;
 always @(posedge clk)if(rst)ready_source<=0;else ready_source<=radio_ready&&!radio_fault&&!data_fault;
 always @(posedge data_clk or posedge mailbox_reset)begin
  if(mailbox_reset)begin
   req_sync<=0;ready_sync<=0;mask0_sync<=0;mask1_sync<=0;
   held_config<=0;config_req<=0;dsp_ack<=0;warm_timer<=0;wave_reset<=15;
  end else begin
   req_sync<={req_sync[0],dsp_toggle};
   ready_sync<={ready_sync[0],ready_source};
   mask0_sync<={mask0_sync[0],digital_mask[0]};mask1_sync<={mask1_sync[0],digital_mask[1]};
   wave_reset<={wave_reset[2:0],1'b0};
   if(req_sync[1]!=config_req)begin
    held_config<=dsp_config;config_req<=req_sync[1];wave_reset<=15;warm_timer<=1000000;
   end else if(warm_timer!=0&&!data_reset)begin
    warm_timer<=warm_timer-1;if(warm_timer==1)dsp_ack<=config_req;
   end
   if(data_reset)wave_reset<=15;
  end
 end
 waveform_core wave(.clk(data_clk),.rst(data_reset||(|wave_reset)||held_config[13*32+:32]==0),
  .sample_strobe(sample_strobe),.config_words(held_config),
  .tx1_enable(mask0_sync[1]&&ready_sync[1]),.tx2_enable(mask1_sync[1]&&ready_sync[1]),
  .sample_valid(wave_valid),.tx1_i(wi1),.tx1_q(wq1),.tx2_i(wi2),.tx2_q(wq2),
  .clip_count1(clips1),.clip_count2(clips2),.debug_clean_i(),.debug_clean_q(),.debug_noise_i(),.debug_noise_q());
 assign tx_iq={wq2,wi2,wq1,wi1};
 // Rolling presence counts plus a live trace avoid losing evidence at saturation.
 // Each independent Gray counter crosses through its own two-stage chain.
 reg [15:0] frame_count[0:3],frame_gray[0:3];
 wire [31:0] frame_decoded[0:3];
 (* ASYNC_REG="TRUE" *)reg [15:0] frame_sync1[0:3],frame_sync2[0:3];
 generate for(genvar f=0;f<4;f=f+1)begin:frame_stats
  assign frame_decoded[f]=gray_decode({16'd0,frame_sync2[f]});
  always @(posedge data_clk or posedge data_reset)begin
   if(data_reset)begin frame_count[f]<=0;frame_gray[f]<=0;end
   else if(rx_frame_pair==f)begin
    frame_count[f]<=frame_count[f]+1;
    frame_gray[f]<=(frame_count[f]+16'd1)^((frame_count[f]+16'd1)>>1);
   end
  end
  always @(posedge clk)begin
   frame_sync1[f]<=frame_gray[f];frame_sync2[f]<=frame_sync1[f];
   if(rst)begin frame_sync1[f]<=0;frame_sync2[f]<=0;end
  end
 end endgenerate
 wire [31:0] rx_recent_frames,rx_frame_transitions;
 ad9361_rx_observer rx_observer(.data_clk(data_clk),.data_reset(data_reset),
  .frame_pair(rx_frame_pair),.clk(clk),.rst(rst),
  .recent_frames(rx_recent_frames),.transitions(rx_frame_transitions));
 // Passive wire-path evidence only: never gates RX/TX or adjusts any delay.
 reg [31:0] rx_samples,rx_errors,tx1_nonzero,tx2_nonzero;
 reg [31:0] rx_samples_gray,rx_errors_gray,tx1_nonzero_gray,tx2_nonzero_gray;
 always @(posedge data_clk or posedge data_reset)begin
  if(data_reset)begin
   rx_samples<=0;rx_errors<=0;tx1_nonzero<=0;tx2_nonzero<=0;
   rx_samples_gray<=0;rx_errors_gray<=0;tx1_nonzero_gray<=0;tx2_nonzero_gray<=0;
  end else begin
   if(rx_valid)begin rx_samples<=rx_samples+1;rx_samples_gray<=(rx_samples+32'd1)^((rx_samples+32'd1)>>1);end
   if(frame_error)begin rx_errors<=rx_errors+1;rx_errors_gray<=(rx_errors+32'd1)^((rx_errors+32'd1)>>1);end
   if(wave_valid&&(wi1!=0||wq1!=0))begin tx1_nonzero<=tx1_nonzero+1;tx1_nonzero_gray<=(tx1_nonzero+32'd1)^((tx1_nonzero+32'd1)>>1);end
   if(wave_valid&&(wi2!=0||wq2!=0))begin tx2_nonzero<=tx2_nonzero+1;tx2_nonzero_gray<=(tx2_nonzero+32'd1)^((tx2_nonzero+32'd1)>>1);end
  end
 end
 (* ASYNC_REG="TRUE" *)reg [31:0] rx_samples_sync1,rx_samples_sync2,rx_errors_sync1,rx_errors_sync2;
 (* ASYNC_REG="TRUE" *)reg [31:0] tx1_nonzero_sync1,tx1_nonzero_sync2,tx2_nonzero_sync1,tx2_nonzero_sync2;
 always @(posedge clk)begin
  rx_samples_sync1<=rx_samples_gray;rx_samples_sync2<=rx_samples_sync1;
  rx_errors_sync1<=rx_errors_gray;rx_errors_sync2<=rx_errors_sync1;
  tx1_nonzero_sync1<=tx1_nonzero_gray;tx1_nonzero_sync2<=tx1_nonzero_sync1;
  tx2_nonzero_sync1<=tx2_nonzero_gray;tx2_nonzero_sync2<=tx2_nonzero_sync1;
  if(rst)begin
   rx_samples_sync1<=0;rx_samples_sync2<=0;rx_errors_sync1<=0;rx_errors_sync2<=0;
   tx1_nonzero_sync1<=0;tx1_nonzero_sync2<=0;tx2_nonzero_sync1<=0;tx2_nonzero_sync2<=0;
  end
 end
 // FIFO congestion drops incoming points and reports an event; frame-core
 // resynchronization remains active. Neither event latches a radio-wide fault.
 wire fifo_in_ready;
 reg [31:0] overflow_count,overflow_gray;
 always @(posedge data_clk or posedge data_reset)begin
  if(data_reset)begin overflow_count<=0;overflow_gray<=0;end
  else if(rx_valid&&!fifo_in_ready&&overflow_count!=32'hffffffff)begin
   overflow_count<=overflow_count+1;
   overflow_gray<=(overflow_count+32'd1)^((overflow_count+32'd1)>>1);
  end
 end
 (* ASYNC_REG="TRUE" *)reg [31:0] overflow_count_sync1,overflow_count_sync2;
 wire [31:0] decoded_overflows=gray_decode(overflow_count_sync2);
 wire [63:0] overflows={32'd0,decoded_overflows};
 reg [31:0] clip_gray1,clip_gray2;
 (* ASYNC_REG="TRUE" *)reg [31:0] clip1_sync1,clip1_sync2,clip2_sync1,clip2_sync2;
 function automatic [31:0] gray_decode(input [31:0] g);
  integer k;begin gray_decode[31]=g[31];for(k=30;k>=0;k=k-1)gray_decode[k]=gray_decode[k+1]^g[k];end
 endfunction
 always @(posedge data_clk)begin clip_gray1<=clips1^(clips1>>1);clip_gray2<=clips2^(clips2>>1);end
 always @(posedge clk)begin
  ack_sync<={ack_sync[0],dsp_ack};
  overflow_count_sync1<=overflow_gray;overflow_count_sync2<=overflow_count_sync1;
  clip1_sync1<=clip_gray1;clip1_sync2<=clip1_sync1;clip2_sync1<=clip_gray2;clip2_sync2<=clip2_sync1;
  if(rst)begin
   ack_sync<=0;overflow_count_sync1<=0;overflow_count_sync2<=0;
   clip1_sync1<=0;clip1_sync2<=0;clip2_sync1<=0;clip2_sync2<=0;
  end
 end
 // HW20: the AD9361 RX words carry a fixed -1.06 LSB DC on both I and Q
 // (2026-10-30 board capture, identical at 25 MSPS raw and 1 MSPS, any gain/LO).
 // Add +1 before the FIFO so both output rates lose it; +2047 saturates.
 // The clip flag is still taken from the uncorrected words.
 function automatic [11:0] dc_correct(input [11:0] x);
  dc_correct=x==12'h7ff ? x : x+12'd1;
 endfunction
 wire [11:0] rx_i_dc=dc_correct(rx_iq[11:0]),rx_q_dc=dc_correct(rx_iq[23:12]);
 wire [31:0] fifo_iq;wire fifo_clipped;wire fifo_valid;
 axis_async_fifo #(.DEPTH(8192),  // HW22: was 4096
 .DATA_WIDTH(33),.KEEP_ENABLE(0),.KEEP_WIDTH(1),.LAST_ENABLE(0),.USER_ENABLE(0)) rx_fifo(
  .s_clk(data_clk),.s_rst(data_reset),.s_axis_tdata({(rx_iq[11:0]==12'h7ff||rx_iq[11:0]==12'h800||rx_iq[23:12]==12'h7ff||rx_iq[23:12]==12'h800),{4{rx_q_dc[11]}},rx_q_dc,{4{rx_i_dc[11]}},rx_i_dc}),
  .s_axis_tkeep(1'b1),.s_axis_tvalid(rx_valid),.s_axis_tready(fifo_in_ready),.s_axis_tlast(1'b0),
  .s_axis_tid(8'd0),.s_axis_tdest(8'd0),.s_axis_tuser(1'b0),
  .m_clk(clk),.m_rst(rst||!ad_resetb),.m_axis_tdata({fifo_clipped,fifo_iq}),.m_axis_tkeep(),.m_axis_tvalid(fifo_valid),
  .m_axis_tready(1'b1),.m_axis_tlast(),.m_axis_tid(),.m_axis_tdest(),.m_axis_tuser(),
  .s_pause_req(1'b0),.s_pause_ack(),.m_pause_req(1'b0),.m_pause_ack(),
  .s_status_depth(),.s_status_depth_commit(),.s_status_overflow(),.s_status_bad_frame(),.s_status_good_frame(),
  .m_status_depth(),.m_status_depth_commit(),.m_status_overflow(),.m_status_bad_frame(),.m_status_good_frame());
 fir_decimate5 fir1(clk,rst||!ad_resetb,fifo_valid,fifo_iq[15:0],fifo_iq[31:16],fv1,fi1,fq1,fir_fault1,fifo_clipped,fc1);
 fir_decimate5 #(.LOG_TAPS(8),.LANES(4),.ROM_FILE("decim2.mem")) fir2(
  clk,rst||!ad_resetb,fv1,fi1,fq1,fv2,fi2,fq2,fir_fault2,fc1,fc2);
 wire capture_run,decimate25,packet_idle;wire [31:0] capture_id,fs_eff_hz,fifo_points;
 wire [63:0] sample_count,datagrams,drop_windows;
 rfiq_packetizer packetizer(.clk(clk),.rst(rst),.run(capture_run),
  .stream_id(32'd1),.capture_id(capture_id),.fs_hz(fs_eff_hz),.lo_hz(radio_rx_lo),
  .gain_mdb(radio_rx_gain_mode==0?radio_rx_gain:32'sh80000000),
  .sample_valid(decimate25?fv2:fifo_valid),.sample_clipped(decimate25?fc2:fifo_clipped),.sample_i(decimate25?fi2:fifo_iq[15:0]),.sample_q(decimate25?fq2:fifo_iq[31:16]),
  .hdr_valid(ihv),.hdr_ready(ihr),.data(idata),.valid(iv),.ready(ir),.last(il),
  .samples(sample_count),.datagrams(datagrams),.dropped(drop_windows),.occupied(),.idle(packet_idle),.fifo_points(fifo_points));
 rfct_controller control(.clk(clk),.rst(rst),.boot_id(boot_ready?boot_id:32'd0),.link_up(link_up),.link_speed(speed),
  .command_valid(ctl_command_valid),.command_ready(ctl_command_ready),.command_uart(ctl_command_uart),.reply_uart(ctl_reply_uart),
  .command_bytes(ctl_command_bytes),.command_length(ctl_command_length),
  .hdr_valid(ctl_hv),.hdr_ready(ctl_hr),.reply_length(ctl_length),.data(ctl_data),.valid(ctl_v),.ready(ctl_r),.last(ctl_last),
  .radio_ready(radio_ready),.radio_fault(radio_fault),.radio_busy(radio_busy),.radio_done(radio_done),.applied_mask(applied_mask),.radio_fault_index(radio_index),
  .quad_warn(quad_warn),.quad_mode(quad_mode),
  .startup_diagnostics({boot_fault,boot_ready,io_busy,io_fault,io_write,6'd0,io_address,io_read}),
  .hardware_diagnostics({32'd1,32'h48573233,phy_diagnostics,radio_diagnostics,clock_diagnostics,
   gray_decode(rx_samples_sync2),gray_decode(rx_errors_sync2),gray_decode(tx1_nonzero_sync2),gray_decode(tx2_nonzero_sync2),
   phy_wire_diagnostics,
   frame_decoded[0][15:0],frame_decoded[1][15:0],frame_decoded[2][15:0],frame_decoded[3][15:0],
   rx_recent_frames,rx_frame_transitions,radio_interface_registers}),
  .radio_apply(radio_apply),.gate_start(gate_start),.radio_lo(radio_lo),.requested_mask(requested_mask),.digital_mask(digital_mask),.attenuation1(attenuation1),.attenuation2(attenuation2),
  .radio_rx_apply(radio_rx_apply),.radio_rx_lo(radio_rx_lo),
  .radio_rx_profile(radio_rx_profile),.radio_rx_gain_mode(radio_rx_gain_mode),.radio_rx_gain(radio_rx_gain),
  .radio_tx_apply(radio_tx_apply),
  .dsp_config(dsp_config),.dsp_toggle(dsp_toggle),.dsp_ack(ack_sync[1]),.capture_run(capture_run),.decimate25(decimate25),.capture_id(capture_id),.fs_eff_hz(fs_eff_hz),
  .packet_idle(packet_idle),.fifo_points(fifo_points),.sample_count(sample_count),.datagrams(datagrams),.drop_windows(drop_windows),.overflow_events(overflows),
  .clip_count1(gray_decode(clip1_sync2)),.clip_count2(gray_decode(clip2_sync2)),.data_fault(data_fault),
  .reg_start(reg_start),.reg_write(reg_write),.reg_address(reg_address),.reg_wdata(reg_wdata),
  .reg_done(reg_done),.reg_rdata(reg_rdata));
 assign led[0]=!(boot_ready&&radio_ready&&link_up);
 assign led[1]=!(boot_fault||phy_fault||radio_fault||data_fault);
endmodule
