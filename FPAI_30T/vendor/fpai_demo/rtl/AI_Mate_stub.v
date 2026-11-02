// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Mon Sep 14 16:26:57 2026
// Host        : DESKTOP-PKO9EB8 running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub AI_Mate_stub.v
// Design      : AI_Mate
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z030ffg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module AI_Mate(hp_clk, ui_clk, reg_clk, sys_rst_n, img_ready_0, 
  img_data_0, img_valid_0, img_start_0, app_addr, app_cmd, app_en, app_wdf_data, app_wdf_end, 
  app_wdf_mask, app_wdf_wren, app_rd_data, app_rd_data_end, app_rd_data_valid, app_rdy, 
  app_wdf_rdy, ddr3_init_done, M_AXI_GP0_ARVALID, M_AXI_GP0_AWVALID, M_AXI_GP0_BREADY, 
  M_AXI_GP0_RREADY, M_AXI_GP0_WLAST, M_AXI_GP0_WVALID, M_AXI_GP0_ARID, M_AXI_GP0_AWID, 
  M_AXI_GP0_WID, M_AXI_GP0_ARBURST, M_AXI_GP0_ARLOCK, M_AXI_GP0_ARSIZE, M_AXI_GP0_AWBURST, 
  M_AXI_GP0_AWLOCK, M_AXI_GP0_AWSIZE, M_AXI_GP0_ARPROT, M_AXI_GP0_AWPROT, M_AXI_GP0_ARADDR, 
  M_AXI_GP0_AWADDR, M_AXI_GP0_WDATA, M_AXI_GP0_ARCACHE, M_AXI_GP0_ARLEN, M_AXI_GP0_ARQOS, 
  M_AXI_GP0_AWCACHE, M_AXI_GP0_AWLEN, M_AXI_GP0_AWQOS, M_AXI_GP0_WSTRB, M_AXI_GP0_ARREADY, 
  M_AXI_GP0_AWREADY, M_AXI_GP0_BVALID, M_AXI_GP0_RLAST, M_AXI_GP0_RVALID, M_AXI_GP0_WREADY, 
  M_AXI_GP0_BID, M_AXI_GP0_RID, M_AXI_GP0_BRESP, M_AXI_GP0_RRESP, M_AXI_GP0_RDATA, 
  M_AXI_GP1_ARVALID, M_AXI_GP1_AWVALID, M_AXI_GP1_BREADY, M_AXI_GP1_RREADY, 
  M_AXI_GP1_WLAST, M_AXI_GP1_WVALID, M_AXI_GP1_ARID, M_AXI_GP1_AWID, M_AXI_GP1_WID, 
  M_AXI_GP1_ARBURST, M_AXI_GP1_ARLOCK, M_AXI_GP1_ARSIZE, M_AXI_GP1_AWBURST, 
  M_AXI_GP1_AWLOCK, M_AXI_GP1_AWSIZE, M_AXI_GP1_ARPROT, M_AXI_GP1_AWPROT, M_AXI_GP1_ARADDR, 
  M_AXI_GP1_AWADDR, M_AXI_GP1_WDATA, M_AXI_GP1_ARCACHE, M_AXI_GP1_ARLEN, M_AXI_GP1_ARQOS, 
  M_AXI_GP1_AWCACHE, M_AXI_GP1_AWLEN, M_AXI_GP1_AWQOS, M_AXI_GP1_WSTRB, M_AXI_GP1_ARREADY, 
  M_AXI_GP1_AWREADY, M_AXI_GP1_BVALID, M_AXI_GP1_RLAST, M_AXI_GP1_RVALID, M_AXI_GP1_WREADY, 
  M_AXI_GP1_BID, M_AXI_GP1_RID, M_AXI_GP1_BRESP, M_AXI_GP1_RRESP, M_AXI_GP1_RDATA, 
  S0_AXI_HP_HC_ARREADY, S0_AXI_HP_HC_AWREADY, S0_AXI_HP_HC_BVALID, S0_AXI_HP_HC_RLAST, 
  S0_AXI_HP_HC_RVALID, S0_AXI_HP_HC_WREADY, S0_AXI_HP_HC_BRESP, S0_AXI_HP_HC_RRESP, 
  S0_AXI_HP_HC_BID, S0_AXI_HP_HC_RID, S0_AXI_HP_HC_RDATA, S0_AXI_HP_HC_ARVALID, 
  S0_AXI_HP_HC_AWVALID, S0_AXI_HP_HC_BREADY, S0_AXI_HP_HC_RREADY, S0_AXI_HP_HC_WLAST, 
  S0_AXI_HP_HC_WVALID, S0_AXI_HP_HC_ARBURST, S0_AXI_HP_HC_ARLOCK, S0_AXI_HP_HC_ARSIZE, 
  S0_AXI_HP_HC_AWBURST, S0_AXI_HP_HC_AWLOCK, S0_AXI_HP_HC_AWSIZE, S0_AXI_HP_HC_ARPROT, 
  S0_AXI_HP_HC_AWPROT, S0_AXI_HP_HC_ARADDR, S0_AXI_HP_HC_AWADDR, S0_AXI_HP_HC_ARCACHE, 
  S0_AXI_HP_HC_ARLEN, S0_AXI_HP_HC_ARQOS, S0_AXI_HP_HC_AWCACHE, S0_AXI_HP_HC_AWLEN, 
  S0_AXI_HP_HC_AWQOS, S0_AXI_HP_HC_ARID, S0_AXI_HP_HC_AWID, S0_AXI_HP_HC_WID, 
  S0_AXI_HP_HC_WDATA, S0_AXI_HP_HC_WSTRB, S1_AXI_HP_HC_ARREADY, S1_AXI_HP_HC_AWREADY, 
  S1_AXI_HP_HC_BVALID, S1_AXI_HP_HC_RLAST, S1_AXI_HP_HC_RVALID, S1_AXI_HP_HC_WREADY, 
  S1_AXI_HP_HC_BRESP, S1_AXI_HP_HC_RRESP, S1_AXI_HP_HC_BID, S1_AXI_HP_HC_RID, 
  S1_AXI_HP_HC_RDATA, S1_AXI_HP_HC_ARVALID, S1_AXI_HP_HC_AWVALID, S1_AXI_HP_HC_BREADY, 
  S1_AXI_HP_HC_RREADY, S1_AXI_HP_HC_WLAST, S1_AXI_HP_HC_WVALID, S1_AXI_HP_HC_ARBURST, 
  S1_AXI_HP_HC_ARLOCK, S1_AXI_HP_HC_ARSIZE, S1_AXI_HP_HC_AWBURST, S1_AXI_HP_HC_AWLOCK, 
  S1_AXI_HP_HC_AWSIZE, S1_AXI_HP_HC_ARPROT, S1_AXI_HP_HC_AWPROT, S1_AXI_HP_HC_ARADDR, 
  S1_AXI_HP_HC_AWADDR, S1_AXI_HP_HC_ARCACHE, S1_AXI_HP_HC_ARLEN, S1_AXI_HP_HC_ARQOS, 
  S1_AXI_HP_HC_AWCACHE, S1_AXI_HP_HC_AWLEN, S1_AXI_HP_HC_AWQOS, S1_AXI_HP_HC_ARID, 
  S1_AXI_HP_HC_AWID, S1_AXI_HP_HC_WID, S1_AXI_HP_HC_WDATA, S1_AXI_HP_HC_WSTRB, 
  S2_AXI_HP_HC_ARREADY, S2_AXI_HP_HC_AWREADY, S2_AXI_HP_HC_BVALID, S2_AXI_HP_HC_RLAST, 
  S2_AXI_HP_HC_RVALID, S2_AXI_HP_HC_WREADY, S2_AXI_HP_HC_BRESP, S2_AXI_HP_HC_RRESP, 
  S2_AXI_HP_HC_BID, S2_AXI_HP_HC_RID, S2_AXI_HP_HC_RDATA, S2_AXI_HP_HC_ARVALID, 
  S2_AXI_HP_HC_AWVALID, S2_AXI_HP_HC_BREADY, S2_AXI_HP_HC_RREADY, S2_AXI_HP_HC_WLAST, 
  S2_AXI_HP_HC_WVALID, S2_AXI_HP_HC_ARBURST, S2_AXI_HP_HC_ARLOCK, S2_AXI_HP_HC_ARSIZE, 
  S2_AXI_HP_HC_AWBURST, S2_AXI_HP_HC_AWLOCK, S2_AXI_HP_HC_AWSIZE, S2_AXI_HP_HC_ARPROT, 
  S2_AXI_HP_HC_AWPROT, S2_AXI_HP_HC_ARADDR, S2_AXI_HP_HC_AWADDR, S2_AXI_HP_HC_ARCACHE, 
  S2_AXI_HP_HC_ARLEN, S2_AXI_HP_HC_ARQOS, S2_AXI_HP_HC_AWCACHE, S2_AXI_HP_HC_AWLEN, 
  S2_AXI_HP_HC_AWQOS, S2_AXI_HP_HC_ARID, S2_AXI_HP_HC_AWID, S2_AXI_HP_HC_WID, 
  S2_AXI_HP_HC_WDATA, S2_AXI_HP_HC_WSTRB, S3_AXI_HP_HC_ARREADY, S3_AXI_HP_HC_AWREADY, 
  S3_AXI_HP_HC_BVALID, S3_AXI_HP_HC_RLAST, S3_AXI_HP_HC_RVALID, S3_AXI_HP_HC_WREADY, 
  S3_AXI_HP_HC_BRESP, S3_AXI_HP_HC_RRESP, S3_AXI_HP_HC_BID, S3_AXI_HP_HC_RID, 
  S3_AXI_HP_HC_RDATA, S3_AXI_HP_HC_ARVALID, S3_AXI_HP_HC_AWVALID, S3_AXI_HP_HC_BREADY, 
  S3_AXI_HP_HC_RREADY, S3_AXI_HP_HC_WLAST, S3_AXI_HP_HC_WVALID, S3_AXI_HP_HC_ARBURST, 
  S3_AXI_HP_HC_ARLOCK, S3_AXI_HP_HC_ARSIZE, S3_AXI_HP_HC_AWBURST, S3_AXI_HP_HC_AWLOCK, 
  S3_AXI_HP_HC_AWSIZE, S3_AXI_HP_HC_ARPROT, S3_AXI_HP_HC_AWPROT, S3_AXI_HP_HC_ARADDR, 
  S3_AXI_HP_HC_AWADDR, S3_AXI_HP_HC_ARCACHE, S3_AXI_HP_HC_ARLEN, S3_AXI_HP_HC_ARQOS, 
  S3_AXI_HP_HC_AWCACHE, S3_AXI_HP_HC_AWLEN, S3_AXI_HP_HC_AWQOS, S3_AXI_HP_HC_ARID, 
  S3_AXI_HP_HC_AWID, S3_AXI_HP_HC_WID, S3_AXI_HP_HC_WDATA, S3_AXI_HP_HC_WSTRB, pl_awaddr, 
  pl_awdata, pl_awen, pl_awinfo, pl_awlast, pl_awvalid, pl_awready, pl_araddr, pl_arinfo, 
  pl_arlast, pl_arvalid, pl_arready, pl_rdata, pl_rvalid, pl_rlast, pl_rready, pl_bvalid, 
  pl_bready, pl_ra_awaddr, pl_ra_awdata, pl_ra_awvalid, pl_ra_awready, pl_ra_araddr, 
  pl_ra_arvalid, pl_ra_arready, pl_ra_rdata, pl_ra_rvalid, pl_ra_rready, pl_exhs, pl_exhs_vld, 
  pl_exhs_ack, pl_int_info, pl_int_valid, pl_int_ready, pl_ra_clk, pl_itf_clk, pl_rst_n, 
  pl_clk_en_b, pl_row_en_b, pl_col_en_b, pl_bist_clk, pl_bist_rstn, pl_bist_en, pl_bist_err, 
  pl_bist_err_inv, pl_bist_done, pl_repair_done, pl_repair_fail, pl_buyi_error, 
  pl_clk_div_out, pl_scan_mode_b, pl_scan_en, pl_scan_clk, pl_scan_rst_n, pl_scan_pipe_clk, 
  pl_scan_i, pl_scan_o, UserCustomOp_0_awwaddr, UserCustomOp_0_awwdata, 
  UserCustomOp_0_awwinfo, UserCustomOp_0_awwvalid, UserCustomOp_0_awwready, 
  UserCustomOp_0_araddr, UserCustomOp_0_arvalid, UserCustomOp_0_arinfo, 
  UserCustomOp_0_arready, UserCustomOp_0_rdata, UserCustomOp_0_rvalid, 
  UserCustomOp_0_rinfo, UserCustomOp_0_rready, customop_irq, ai_irq)
/* synthesis syn_black_box black_box_pad_pin="hp_clk,ui_clk,reg_clk,sys_rst_n,img_ready_0,img_data_0[63:0],img_valid_0,img_start_0,app_addr[28:0],app_cmd[2:0],app_en,app_wdf_data[511:0],app_wdf_end,app_wdf_mask[63:0],app_wdf_wren,app_rd_data[511:0],app_rd_data_end,app_rd_data_valid,app_rdy,app_wdf_rdy,ddr3_init_done,M_AXI_GP0_ARVALID,M_AXI_GP0_AWVALID,M_AXI_GP0_BREADY,M_AXI_GP0_RREADY,M_AXI_GP0_WLAST,M_AXI_GP0_WVALID,M_AXI_GP0_ARID[11:0],M_AXI_GP0_AWID[11:0],M_AXI_GP0_WID[11:0],M_AXI_GP0_ARBURST[1:0],M_AXI_GP0_ARLOCK[1:0],M_AXI_GP0_ARSIZE[2:0],M_AXI_GP0_AWBURST[1:0],M_AXI_GP0_AWLOCK[1:0],M_AXI_GP0_AWSIZE[2:0],M_AXI_GP0_ARPROT[2:0],M_AXI_GP0_AWPROT[2:0],M_AXI_GP0_ARADDR[31:0],M_AXI_GP0_AWADDR[31:0],M_AXI_GP0_WDATA[31:0],M_AXI_GP0_ARCACHE[3:0],M_AXI_GP0_ARLEN[3:0],M_AXI_GP0_ARQOS[3:0],M_AXI_GP0_AWCACHE[3:0],M_AXI_GP0_AWLEN[3:0],M_AXI_GP0_AWQOS[3:0],M_AXI_GP0_WSTRB[3:0],M_AXI_GP0_ARREADY,M_AXI_GP0_AWREADY,M_AXI_GP0_BVALID,M_AXI_GP0_RLAST,M_AXI_GP0_RVALID,M_AXI_GP0_WREADY,M_AXI_GP0_BID[11:0],M_AXI_GP0_RID[11:0],M_AXI_GP0_BRESP[1:0],M_AXI_GP0_RRESP[1:0],M_AXI_GP0_RDATA[31:0],M_AXI_GP1_ARVALID,M_AXI_GP1_AWVALID,M_AXI_GP1_BREADY,M_AXI_GP1_RREADY,M_AXI_GP1_WLAST,M_AXI_GP1_WVALID,M_AXI_GP1_ARID[11:0],M_AXI_GP1_AWID[11:0],M_AXI_GP1_WID[11:0],M_AXI_GP1_ARBURST[1:0],M_AXI_GP1_ARLOCK[1:0],M_AXI_GP1_ARSIZE[2:0],M_AXI_GP1_AWBURST[1:0],M_AXI_GP1_AWLOCK[1:0],M_AXI_GP1_AWSIZE[2:0],M_AXI_GP1_ARPROT[2:0],M_AXI_GP1_AWPROT[2:0],M_AXI_GP1_ARADDR[31:0],M_AXI_GP1_AWADDR[31:0],M_AXI_GP1_WDATA[31:0],M_AXI_GP1_ARCACHE[3:0],M_AXI_GP1_ARLEN[3:0],M_AXI_GP1_ARQOS[3:0],M_AXI_GP1_AWCACHE[3:0],M_AXI_GP1_AWLEN[3:0],M_AXI_GP1_AWQOS[3:0],M_AXI_GP1_WSTRB[3:0],M_AXI_GP1_ARREADY,M_AXI_GP1_AWREADY,M_AXI_GP1_BVALID,M_AXI_GP1_RLAST,M_AXI_GP1_RVALID,M_AXI_GP1_WREADY,M_AXI_GP1_BID[11:0],M_AXI_GP1_RID[11:0],M_AXI_GP1_BRESP[1:0],M_AXI_GP1_RRESP[1:0],M_AXI_GP1_RDATA[31:0],S0_AXI_HP_HC_ARREADY,S0_AXI_HP_HC_AWREADY,S0_AXI_HP_HC_BVALID,S0_AXI_HP_HC_RLAST,S0_AXI_HP_HC_RVALID,S0_AXI_HP_HC_WREADY,S0_AXI_HP_HC_BRESP[1:0],S0_AXI_HP_HC_RRESP[1:0],S0_AXI_HP_HC_BID[4:0],S0_AXI_HP_HC_RID[4:0],S0_AXI_HP_HC_RDATA[63:0],S0_AXI_HP_HC_ARVALID,S0_AXI_HP_HC_AWVALID,S0_AXI_HP_HC_BREADY,S0_AXI_HP_HC_RREADY,S0_AXI_HP_HC_WLAST,S0_AXI_HP_HC_WVALID,S0_AXI_HP_HC_ARBURST[1:0],S0_AXI_HP_HC_ARLOCK[1:0],S0_AXI_HP_HC_ARSIZE[2:0],S0_AXI_HP_HC_AWBURST[1:0],S0_AXI_HP_HC_AWLOCK[1:0],S0_AXI_HP_HC_AWSIZE[2:0],S0_AXI_HP_HC_ARPROT[2:0],S0_AXI_HP_HC_AWPROT[2:0],S0_AXI_HP_HC_ARADDR[31:0],S0_AXI_HP_HC_AWADDR[31:0],S0_AXI_HP_HC_ARCACHE[3:0],S0_AXI_HP_HC_ARLEN[3:0],S0_AXI_HP_HC_ARQOS[3:0],S0_AXI_HP_HC_AWCACHE[3:0],S0_AXI_HP_HC_AWLEN[3:0],S0_AXI_HP_HC_AWQOS[3:0],S0_AXI_HP_HC_ARID[4:0],S0_AXI_HP_HC_AWID[4:0],S0_AXI_HP_HC_WID[4:0],S0_AXI_HP_HC_WDATA[63:0],S0_AXI_HP_HC_WSTRB[7:0],S1_AXI_HP_HC_ARREADY,S1_AXI_HP_HC_AWREADY,S1_AXI_HP_HC_BVALID,S1_AXI_HP_HC_RLAST,S1_AXI_HP_HC_RVALID,S1_AXI_HP_HC_WREADY,S1_AXI_HP_HC_BRESP[1:0],S1_AXI_HP_HC_RRESP[1:0],S1_AXI_HP_HC_BID[4:0],S1_AXI_HP_HC_RID[4:0],S1_AXI_HP_HC_RDATA[63:0],S1_AXI_HP_HC_ARVALID,S1_AXI_HP_HC_AWVALID,S1_AXI_HP_HC_BREADY,S1_AXI_HP_HC_RREADY,S1_AXI_HP_HC_WLAST,S1_AXI_HP_HC_WVALID,S1_AXI_HP_HC_ARBURST[1:0],S1_AXI_HP_HC_ARLOCK[1:0],S1_AXI_HP_HC_ARSIZE[2:0],S1_AXI_HP_HC_AWBURST[1:0],S1_AXI_HP_HC_AWLOCK[1:0],S1_AXI_HP_HC_AWSIZE[2:0],S1_AXI_HP_HC_ARPROT[2:0],S1_AXI_HP_HC_AWPROT[2:0],S1_AXI_HP_HC_ARADDR[31:0],S1_AXI_HP_HC_AWADDR[31:0],S1_AXI_HP_HC_ARCACHE[3:0],S1_AXI_HP_HC_ARLEN[3:0],S1_AXI_HP_HC_ARQOS[3:0],S1_AXI_HP_HC_AWCACHE[3:0],S1_AXI_HP_HC_AWLEN[3:0],S1_AXI_HP_HC_AWQOS[3:0],S1_AXI_HP_HC_ARID[4:0],S1_AXI_HP_HC_AWID[4:0],S1_AXI_HP_HC_WID[4:0],S1_AXI_HP_HC_WDATA[63:0],S1_AXI_HP_HC_WSTRB[7:0],S2_AXI_HP_HC_ARREADY,S2_AXI_HP_HC_AWREADY,S2_AXI_HP_HC_BVALID,S2_AXI_HP_HC_RLAST,S2_AXI_HP_HC_RVALID,S2_AXI_HP_HC_WREADY,S2_AXI_HP_HC_BRESP[1:0],S2_AXI_HP_HC_RRESP[1:0],S2_AXI_HP_HC_BID[4:0],S2_AXI_HP_HC_RID[4:0],S2_AXI_HP_HC_RDATA[63:0],S2_AXI_HP_HC_ARVALID,S2_AXI_HP_HC_AWVALID,S2_AXI_HP_HC_BREADY,S2_AXI_HP_HC_RREADY,S2_AXI_HP_HC_WLAST,S2_AXI_HP_HC_WVALID,S2_AXI_HP_HC_ARBURST[1:0],S2_AXI_HP_HC_ARLOCK[1:0],S2_AXI_HP_HC_ARSIZE[2:0],S2_AXI_HP_HC_AWBURST[1:0],S2_AXI_HP_HC_AWLOCK[1:0],S2_AXI_HP_HC_AWSIZE[2:0],S2_AXI_HP_HC_ARPROT[2:0],S2_AXI_HP_HC_AWPROT[2:0],S2_AXI_HP_HC_ARADDR[31:0],S2_AXI_HP_HC_AWADDR[31:0],S2_AXI_HP_HC_ARCACHE[3:0],S2_AXI_HP_HC_ARLEN[3:0],S2_AXI_HP_HC_ARQOS[3:0],S2_AXI_HP_HC_AWCACHE[3:0],S2_AXI_HP_HC_AWLEN[3:0],S2_AXI_HP_HC_AWQOS[3:0],S2_AXI_HP_HC_ARID[4:0],S2_AXI_HP_HC_AWID[4:0],S2_AXI_HP_HC_WID[4:0],S2_AXI_HP_HC_WDATA[63:0],S2_AXI_HP_HC_WSTRB[7:0],S3_AXI_HP_HC_ARREADY,S3_AXI_HP_HC_AWREADY,S3_AXI_HP_HC_BVALID,S3_AXI_HP_HC_RLAST,S3_AXI_HP_HC_RVALID,S3_AXI_HP_HC_WREADY,S3_AXI_HP_HC_BRESP[1:0],S3_AXI_HP_HC_RRESP[1:0],S3_AXI_HP_HC_BID[4:0],S3_AXI_HP_HC_RID[4:0],S3_AXI_HP_HC_RDATA[63:0],S3_AXI_HP_HC_ARVALID,S3_AXI_HP_HC_AWVALID,S3_AXI_HP_HC_BREADY,S3_AXI_HP_HC_RREADY,S3_AXI_HP_HC_WLAST,S3_AXI_HP_HC_WVALID,S3_AXI_HP_HC_ARBURST[1:0],S3_AXI_HP_HC_ARLOCK[1:0],S3_AXI_HP_HC_ARSIZE[2:0],S3_AXI_HP_HC_AWBURST[1:0],S3_AXI_HP_HC_AWLOCK[1:0],S3_AXI_HP_HC_AWSIZE[2:0],S3_AXI_HP_HC_ARPROT[2:0],S3_AXI_HP_HC_AWPROT[2:0],S3_AXI_HP_HC_ARADDR[31:0],S3_AXI_HP_HC_AWADDR[31:0],S3_AXI_HP_HC_ARCACHE[3:0],S3_AXI_HP_HC_ARLEN[3:0],S3_AXI_HP_HC_ARQOS[3:0],S3_AXI_HP_HC_AWCACHE[3:0],S3_AXI_HP_HC_AWLEN[3:0],S3_AXI_HP_HC_AWQOS[3:0],S3_AXI_HP_HC_ARID[4:0],S3_AXI_HP_HC_AWID[4:0],S3_AXI_HP_HC_WID[4:0],S3_AXI_HP_HC_WDATA[63:0],S3_AXI_HP_HC_WSTRB[7:0],pl_awaddr[26:0],pl_awdata[511:0],pl_awen[63:0],pl_awinfo[5:0],pl_awlast,pl_awvalid,pl_awready,pl_araddr[26:0],pl_arinfo[5:0],pl_arlast,pl_arvalid,pl_arready,pl_rdata[511:0],pl_rvalid,pl_rlast,pl_rready,pl_bvalid,pl_bready,pl_ra_awaddr[15:0],pl_ra_awdata[31:0],pl_ra_awvalid,pl_ra_awready,pl_ra_araddr[15:0],pl_ra_arvalid,pl_ra_arready,pl_ra_rdata[31:0],pl_ra_rvalid,pl_ra_rready,pl_exhs[7:0],pl_exhs_vld,pl_exhs_ack,pl_int_info[17:0],pl_int_valid,pl_int_ready,pl_ra_clk,pl_itf_clk,pl_rst_n,pl_clk_en_b,pl_row_en_b[3:0],pl_col_en_b[3:0],pl_bist_clk,pl_bist_rstn,pl_bist_en,pl_bist_err,pl_bist_err_inv,pl_bist_done,pl_repair_done,pl_repair_fail,pl_buyi_error,pl_clk_div_out,pl_scan_mode_b,pl_scan_en,pl_scan_clk,pl_scan_rst_n,pl_scan_pipe_clk,pl_scan_i[83:0],pl_scan_o[63:0],UserCustomOp_0_awwaddr[31:0],UserCustomOp_0_awwdata[511:0],UserCustomOp_0_awwinfo[71:0],UserCustomOp_0_awwvalid,UserCustomOp_0_awwready,UserCustomOp_0_araddr[31:0],UserCustomOp_0_arvalid,UserCustomOp_0_arinfo[31:0],UserCustomOp_0_arready,UserCustomOp_0_rdata[511:0],UserCustomOp_0_rvalid,UserCustomOp_0_rinfo[31:0],UserCustomOp_0_rready,customop_irq,ai_irq" */;
  input hp_clk;
  input ui_clk;
  input reg_clk;
  input sys_rst_n;
  output img_ready_0;
  input [63:0]img_data_0;
  input img_valid_0;
  input img_start_0;
  output [28:0]app_addr;
  output [2:0]app_cmd;
  output app_en;
  output [511:0]app_wdf_data;
  output app_wdf_end;
  output [63:0]app_wdf_mask;
  output app_wdf_wren;
  input [511:0]app_rd_data;
  input app_rd_data_end;
  input app_rd_data_valid;
  input app_rdy;
  input app_wdf_rdy;
  input ddr3_init_done;
  input M_AXI_GP0_ARVALID;
  input M_AXI_GP0_AWVALID;
  input M_AXI_GP0_BREADY;
  input M_AXI_GP0_RREADY;
  input M_AXI_GP0_WLAST;
  input M_AXI_GP0_WVALID;
  input [11:0]M_AXI_GP0_ARID;
  input [11:0]M_AXI_GP0_AWID;
  input [11:0]M_AXI_GP0_WID;
  input [1:0]M_AXI_GP0_ARBURST;
  input [1:0]M_AXI_GP0_ARLOCK;
  input [2:0]M_AXI_GP0_ARSIZE;
  input [1:0]M_AXI_GP0_AWBURST;
  input [1:0]M_AXI_GP0_AWLOCK;
  input [2:0]M_AXI_GP0_AWSIZE;
  input [2:0]M_AXI_GP0_ARPROT;
  input [2:0]M_AXI_GP0_AWPROT;
  input [31:0]M_AXI_GP0_ARADDR;
  input [31:0]M_AXI_GP0_AWADDR;
  input [31:0]M_AXI_GP0_WDATA;
  input [3:0]M_AXI_GP0_ARCACHE;
  input [3:0]M_AXI_GP0_ARLEN;
  input [3:0]M_AXI_GP0_ARQOS;
  input [3:0]M_AXI_GP0_AWCACHE;
  input [3:0]M_AXI_GP0_AWLEN;
  input [3:0]M_AXI_GP0_AWQOS;
  input [3:0]M_AXI_GP0_WSTRB;
  output M_AXI_GP0_ARREADY;
  output M_AXI_GP0_AWREADY;
  output M_AXI_GP0_BVALID;
  output M_AXI_GP0_RLAST;
  output M_AXI_GP0_RVALID;
  output M_AXI_GP0_WREADY;
  output [11:0]M_AXI_GP0_BID;
  output [11:0]M_AXI_GP0_RID;
  output [1:0]M_AXI_GP0_BRESP;
  output [1:0]M_AXI_GP0_RRESP;
  output [31:0]M_AXI_GP0_RDATA;
  input M_AXI_GP1_ARVALID;
  input M_AXI_GP1_AWVALID;
  input M_AXI_GP1_BREADY;
  input M_AXI_GP1_RREADY;
  input M_AXI_GP1_WLAST;
  input M_AXI_GP1_WVALID;
  input [11:0]M_AXI_GP1_ARID;
  input [11:0]M_AXI_GP1_AWID;
  input [11:0]M_AXI_GP1_WID;
  input [1:0]M_AXI_GP1_ARBURST;
  input [1:0]M_AXI_GP1_ARLOCK;
  input [2:0]M_AXI_GP1_ARSIZE;
  input [1:0]M_AXI_GP1_AWBURST;
  input [1:0]M_AXI_GP1_AWLOCK;
  input [2:0]M_AXI_GP1_AWSIZE;
  input [2:0]M_AXI_GP1_ARPROT;
  input [2:0]M_AXI_GP1_AWPROT;
  input [31:0]M_AXI_GP1_ARADDR;
  input [31:0]M_AXI_GP1_AWADDR;
  input [31:0]M_AXI_GP1_WDATA;
  input [3:0]M_AXI_GP1_ARCACHE;
  input [3:0]M_AXI_GP1_ARLEN;
  input [3:0]M_AXI_GP1_ARQOS;
  input [3:0]M_AXI_GP1_AWCACHE;
  input [3:0]M_AXI_GP1_AWLEN;
  input [3:0]M_AXI_GP1_AWQOS;
  input [3:0]M_AXI_GP1_WSTRB;
  output M_AXI_GP1_ARREADY;
  output M_AXI_GP1_AWREADY;
  output M_AXI_GP1_BVALID;
  output M_AXI_GP1_RLAST;
  output M_AXI_GP1_RVALID;
  output M_AXI_GP1_WREADY;
  output [11:0]M_AXI_GP1_BID;
  output [11:0]M_AXI_GP1_RID;
  output [1:0]M_AXI_GP1_BRESP;
  output [1:0]M_AXI_GP1_RRESP;
  output [31:0]M_AXI_GP1_RDATA;
  input S0_AXI_HP_HC_ARREADY;
  input S0_AXI_HP_HC_AWREADY;
  input S0_AXI_HP_HC_BVALID;
  input S0_AXI_HP_HC_RLAST;
  input S0_AXI_HP_HC_RVALID;
  input S0_AXI_HP_HC_WREADY;
  input [1:0]S0_AXI_HP_HC_BRESP;
  input [1:0]S0_AXI_HP_HC_RRESP;
  input [4:0]S0_AXI_HP_HC_BID;
  input [4:0]S0_AXI_HP_HC_RID;
  input [63:0]S0_AXI_HP_HC_RDATA;
  output S0_AXI_HP_HC_ARVALID;
  output S0_AXI_HP_HC_AWVALID;
  output S0_AXI_HP_HC_BREADY;
  output S0_AXI_HP_HC_RREADY;
  output S0_AXI_HP_HC_WLAST;
  output S0_AXI_HP_HC_WVALID;
  output [1:0]S0_AXI_HP_HC_ARBURST;
  output [1:0]S0_AXI_HP_HC_ARLOCK;
  output [2:0]S0_AXI_HP_HC_ARSIZE;
  output [1:0]S0_AXI_HP_HC_AWBURST;
  output [1:0]S0_AXI_HP_HC_AWLOCK;
  output [2:0]S0_AXI_HP_HC_AWSIZE;
  output [2:0]S0_AXI_HP_HC_ARPROT;
  output [2:0]S0_AXI_HP_HC_AWPROT;
  output [31:0]S0_AXI_HP_HC_ARADDR;
  output [31:0]S0_AXI_HP_HC_AWADDR;
  output [3:0]S0_AXI_HP_HC_ARCACHE;
  output [3:0]S0_AXI_HP_HC_ARLEN;
  output [3:0]S0_AXI_HP_HC_ARQOS;
  output [3:0]S0_AXI_HP_HC_AWCACHE;
  output [3:0]S0_AXI_HP_HC_AWLEN;
  output [3:0]S0_AXI_HP_HC_AWQOS;
  output [4:0]S0_AXI_HP_HC_ARID;
  output [4:0]S0_AXI_HP_HC_AWID;
  output [4:0]S0_AXI_HP_HC_WID;
  output [63:0]S0_AXI_HP_HC_WDATA;
  output [7:0]S0_AXI_HP_HC_WSTRB;
  input S1_AXI_HP_HC_ARREADY;
  input S1_AXI_HP_HC_AWREADY;
  input S1_AXI_HP_HC_BVALID;
  input S1_AXI_HP_HC_RLAST;
  input S1_AXI_HP_HC_RVALID;
  input S1_AXI_HP_HC_WREADY;
  input [1:0]S1_AXI_HP_HC_BRESP;
  input [1:0]S1_AXI_HP_HC_RRESP;
  input [4:0]S1_AXI_HP_HC_BID;
  input [4:0]S1_AXI_HP_HC_RID;
  input [63:0]S1_AXI_HP_HC_RDATA;
  output S1_AXI_HP_HC_ARVALID;
  output S1_AXI_HP_HC_AWVALID;
  output S1_AXI_HP_HC_BREADY;
  output S1_AXI_HP_HC_RREADY;
  output S1_AXI_HP_HC_WLAST;
  output S1_AXI_HP_HC_WVALID;
  output [1:0]S1_AXI_HP_HC_ARBURST;
  output [1:0]S1_AXI_HP_HC_ARLOCK;
  output [2:0]S1_AXI_HP_HC_ARSIZE;
  output [1:0]S1_AXI_HP_HC_AWBURST;
  output [1:0]S1_AXI_HP_HC_AWLOCK;
  output [2:0]S1_AXI_HP_HC_AWSIZE;
  output [2:0]S1_AXI_HP_HC_ARPROT;
  output [2:0]S1_AXI_HP_HC_AWPROT;
  output [31:0]S1_AXI_HP_HC_ARADDR;
  output [31:0]S1_AXI_HP_HC_AWADDR;
  output [3:0]S1_AXI_HP_HC_ARCACHE;
  output [3:0]S1_AXI_HP_HC_ARLEN;
  output [3:0]S1_AXI_HP_HC_ARQOS;
  output [3:0]S1_AXI_HP_HC_AWCACHE;
  output [3:0]S1_AXI_HP_HC_AWLEN;
  output [3:0]S1_AXI_HP_HC_AWQOS;
  output [4:0]S1_AXI_HP_HC_ARID;
  output [4:0]S1_AXI_HP_HC_AWID;
  output [4:0]S1_AXI_HP_HC_WID;
  output [63:0]S1_AXI_HP_HC_WDATA;
  output [7:0]S1_AXI_HP_HC_WSTRB;
  input S2_AXI_HP_HC_ARREADY;
  input S2_AXI_HP_HC_AWREADY;
  input S2_AXI_HP_HC_BVALID;
  input S2_AXI_HP_HC_RLAST;
  input S2_AXI_HP_HC_RVALID;
  input S2_AXI_HP_HC_WREADY;
  input [1:0]S2_AXI_HP_HC_BRESP;
  input [1:0]S2_AXI_HP_HC_RRESP;
  input [4:0]S2_AXI_HP_HC_BID;
  input [4:0]S2_AXI_HP_HC_RID;
  input [63:0]S2_AXI_HP_HC_RDATA;
  output S2_AXI_HP_HC_ARVALID;
  output S2_AXI_HP_HC_AWVALID;
  output S2_AXI_HP_HC_BREADY;
  output S2_AXI_HP_HC_RREADY;
  output S2_AXI_HP_HC_WLAST;
  output S2_AXI_HP_HC_WVALID;
  output [1:0]S2_AXI_HP_HC_ARBURST;
  output [1:0]S2_AXI_HP_HC_ARLOCK;
  output [2:0]S2_AXI_HP_HC_ARSIZE;
  output [1:0]S2_AXI_HP_HC_AWBURST;
  output [1:0]S2_AXI_HP_HC_AWLOCK;
  output [2:0]S2_AXI_HP_HC_AWSIZE;
  output [2:0]S2_AXI_HP_HC_ARPROT;
  output [2:0]S2_AXI_HP_HC_AWPROT;
  output [31:0]S2_AXI_HP_HC_ARADDR;
  output [31:0]S2_AXI_HP_HC_AWADDR;
  output [3:0]S2_AXI_HP_HC_ARCACHE;
  output [3:0]S2_AXI_HP_HC_ARLEN;
  output [3:0]S2_AXI_HP_HC_ARQOS;
  output [3:0]S2_AXI_HP_HC_AWCACHE;
  output [3:0]S2_AXI_HP_HC_AWLEN;
  output [3:0]S2_AXI_HP_HC_AWQOS;
  output [4:0]S2_AXI_HP_HC_ARID;
  output [4:0]S2_AXI_HP_HC_AWID;
  output [4:0]S2_AXI_HP_HC_WID;
  output [63:0]S2_AXI_HP_HC_WDATA;
  output [7:0]S2_AXI_HP_HC_WSTRB;
  input S3_AXI_HP_HC_ARREADY;
  input S3_AXI_HP_HC_AWREADY;
  input S3_AXI_HP_HC_BVALID;
  input S3_AXI_HP_HC_RLAST;
  input S3_AXI_HP_HC_RVALID;
  input S3_AXI_HP_HC_WREADY;
  input [1:0]S3_AXI_HP_HC_BRESP;
  input [1:0]S3_AXI_HP_HC_RRESP;
  input [4:0]S3_AXI_HP_HC_BID;
  input [4:0]S3_AXI_HP_HC_RID;
  input [63:0]S3_AXI_HP_HC_RDATA;
  output S3_AXI_HP_HC_ARVALID;
  output S3_AXI_HP_HC_AWVALID;
  output S3_AXI_HP_HC_BREADY;
  output S3_AXI_HP_HC_RREADY;
  output S3_AXI_HP_HC_WLAST;
  output S3_AXI_HP_HC_WVALID;
  output [1:0]S3_AXI_HP_HC_ARBURST;
  output [1:0]S3_AXI_HP_HC_ARLOCK;
  output [2:0]S3_AXI_HP_HC_ARSIZE;
  output [1:0]S3_AXI_HP_HC_AWBURST;
  output [1:0]S3_AXI_HP_HC_AWLOCK;
  output [2:0]S3_AXI_HP_HC_AWSIZE;
  output [2:0]S3_AXI_HP_HC_ARPROT;
  output [2:0]S3_AXI_HP_HC_AWPROT;
  output [31:0]S3_AXI_HP_HC_ARADDR;
  output [31:0]S3_AXI_HP_HC_AWADDR;
  output [3:0]S3_AXI_HP_HC_ARCACHE;
  output [3:0]S3_AXI_HP_HC_ARLEN;
  output [3:0]S3_AXI_HP_HC_ARQOS;
  output [3:0]S3_AXI_HP_HC_AWCACHE;
  output [3:0]S3_AXI_HP_HC_AWLEN;
  output [3:0]S3_AXI_HP_HC_AWQOS;
  output [4:0]S3_AXI_HP_HC_ARID;
  output [4:0]S3_AXI_HP_HC_AWID;
  output [4:0]S3_AXI_HP_HC_WID;
  output [63:0]S3_AXI_HP_HC_WDATA;
  output [7:0]S3_AXI_HP_HC_WSTRB;
  input [26:0]pl_awaddr;
  input [511:0]pl_awdata;
  input [63:0]pl_awen;
  input [5:0]pl_awinfo;
  input pl_awlast;
  input pl_awvalid;
  output pl_awready;
  input [26:0]pl_araddr;
  input [5:0]pl_arinfo;
  input pl_arlast;
  input pl_arvalid;
  output pl_arready;
  output [511:0]pl_rdata;
  output pl_rvalid;
  output pl_rlast;
  input pl_rready;
  output pl_bvalid;
  input pl_bready;
  output [15:0]pl_ra_awaddr;
  output [31:0]pl_ra_awdata;
  output pl_ra_awvalid;
  input pl_ra_awready;
  output [15:0]pl_ra_araddr;
  output pl_ra_arvalid;
  input pl_ra_arready;
  input [31:0]pl_ra_rdata;
  input pl_ra_rvalid;
  output pl_ra_rready;
  input [7:0]pl_exhs;
  input pl_exhs_vld;
  output pl_exhs_ack;
  input [17:0]pl_int_info;
  input pl_int_valid;
  output pl_int_ready;
  output pl_ra_clk;
  output pl_itf_clk;
  output pl_rst_n;
  output pl_clk_en_b;
  output [3:0]pl_row_en_b;
  output [3:0]pl_col_en_b;
  output pl_bist_clk;
  output pl_bist_rstn;
  output pl_bist_en;
  input pl_bist_err;
  input pl_bist_err_inv;
  input pl_bist_done;
  input pl_repair_done;
  input pl_repair_fail;
  input pl_buyi_error;
  input pl_clk_div_out;
  output pl_scan_mode_b;
  output pl_scan_en;
  output pl_scan_clk;
  output pl_scan_rst_n;
  output pl_scan_pipe_clk;
  output [83:0]pl_scan_i;
  input [63:0]pl_scan_o;
  input [31:0]UserCustomOp_0_awwaddr;
  input [511:0]UserCustomOp_0_awwdata;
  input [71:0]UserCustomOp_0_awwinfo;
  input UserCustomOp_0_awwvalid;
  output UserCustomOp_0_awwready;
  input [31:0]UserCustomOp_0_araddr;
  input UserCustomOp_0_arvalid;
  input [31:0]UserCustomOp_0_arinfo;
  output UserCustomOp_0_arready;
  output [511:0]UserCustomOp_0_rdata;
  output UserCustomOp_0_rvalid;
  output [31:0]UserCustomOp_0_rinfo;
  input UserCustomOp_0_rready;
  output customop_irq;
  output ai_irq;
endmodule
