//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Thu Oct 22 22:21:25 2026
//Host        : LAPTOP-AKNRE0JF running 64-bit major release  (build 9200)
//Command     : generate_target ps_ai_wrapper.bd
//Design      : ps_ai_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ps_ai_wrapper
   (AI_BIST_0_pl_bist_done,
    AI_BIST_0_pl_bist_en,
    AI_BIST_0_pl_bist_err,
    AI_BIST_0_pl_bist_err_inv,
    AI_BIST_0_pl_repair_done,
    AI_BIST_0_pl_repair_fail,
    AI_IRQ_0_pl_int_info,
    AI_IRQ_0_pl_int_ready,
    AI_IRQ_0_pl_int_valid,
    AI_SCAN_0_pl_scan_compression_mode,
    AI_SCAN_0_pl_scan_cs,
    AI_SCAN_0_pl_scan_en,
    AI_SCAN_0_pl_scan_in,
    AI_SCAN_0_pl_scan_mode_b,
    AI_SCAN_0_pl_scan_occ_bypass,
    AI_SCAN_0_pl_scan_occ_mode,
    AI_SCAN_0_pl_scan_occ_reset,
    AI_SCAN_0_pl_scan_out,
    AI_SCAN_0_pl_scan_wrp_mode,
    AI_SCAN_0_pl_scan_wrp_shift,
    BYolo_GP0_araddr,
    BYolo_GP0_arburst,
    BYolo_GP0_arcache,
    BYolo_GP0_arid,
    BYolo_GP0_arlen,
    BYolo_GP0_arlock,
    BYolo_GP0_arprot,
    BYolo_GP0_arqos,
    BYolo_GP0_arready,
    BYolo_GP0_arsize,
    BYolo_GP0_arvalid,
    BYolo_GP0_awaddr,
    BYolo_GP0_awburst,
    BYolo_GP0_awcache,
    BYolo_GP0_awid,
    BYolo_GP0_awlen,
    BYolo_GP0_awlock,
    BYolo_GP0_awprot,
    BYolo_GP0_awqos,
    BYolo_GP0_awready,
    BYolo_GP0_awsize,
    BYolo_GP0_awvalid,
    BYolo_GP0_bid,
    BYolo_GP0_bready,
    BYolo_GP0_bresp,
    BYolo_GP0_bvalid,
    BYolo_GP0_rdata,
    BYolo_GP0_rid,
    BYolo_GP0_rlast,
    BYolo_GP0_rready,
    BYolo_GP0_rresp,
    BYolo_GP0_rvalid,
    BYolo_GP0_wdata,
    BYolo_GP0_wid,
    BYolo_GP0_wlast,
    BYolo_GP0_wready,
    BYolo_GP0_wstrb,
    BYolo_GP0_wvalid,
    BYolo_GP1_araddr,
    BYolo_GP1_arburst,
    BYolo_GP1_arcache,
    BYolo_GP1_arid,
    BYolo_GP1_arlen,
    BYolo_GP1_arlock,
    BYolo_GP1_arprot,
    BYolo_GP1_arqos,
    BYolo_GP1_arready,
    BYolo_GP1_arsize,
    BYolo_GP1_arvalid,
    BYolo_GP1_awaddr,
    BYolo_GP1_awburst,
    BYolo_GP1_awcache,
    BYolo_GP1_awid,
    BYolo_GP1_awlen,
    BYolo_GP1_awlock,
    BYolo_GP1_awprot,
    BYolo_GP1_awqos,
    BYolo_GP1_awready,
    BYolo_GP1_awsize,
    BYolo_GP1_awvalid,
    BYolo_GP1_bid,
    BYolo_GP1_bready,
    BYolo_GP1_bresp,
    BYolo_GP1_bvalid,
    BYolo_GP1_rdata,
    BYolo_GP1_rid,
    BYolo_GP1_rlast,
    BYolo_GP1_rready,
    BYolo_GP1_rresp,
    BYolo_GP1_rvalid,
    BYolo_GP1_wdata,
    BYolo_GP1_wid,
    BYolo_GP1_wlast,
    BYolo_GP1_wready,
    BYolo_GP1_wstrb,
    BYolo_GP1_wvalid,
    DDR_0_addr,
    DDR_0_ba,
    DDR_0_cas_n,
    DDR_0_ck_n,
    DDR_0_ck_p,
    DDR_0_cke,
    DDR_0_cs_n,
    DDR_0_dm,
    DDR_0_dq,
    DDR_0_dqs_n,
    DDR_0_dqs_p,
    DDR_0_odt,
    DDR_0_ras_n,
    DDR_0_reset_n,
    DDR_0_we_n,
    FCLK_CLK0_0,
    FCLK_RESET0_N_0,
    FIXED_IO_0_ddr_vrn,
    FIXED_IO_0_ddr_vrp,
    FIXED_IO_0_mio,
    FIXED_IO_0_ps_clk,
    FIXED_IO_0_ps_porb,
    FIXED_IO_0_ps_srstb,
    M_AI_HP_0_pl_araddr,
    M_AI_HP_0_pl_arinfo,
    M_AI_HP_0_pl_arlast,
    M_AI_HP_0_pl_arready,
    M_AI_HP_0_pl_arvalid,
    M_AI_HP_0_pl_awaddr,
    M_AI_HP_0_pl_awdata,
    M_AI_HP_0_pl_awen,
    M_AI_HP_0_pl_awinfo,
    M_AI_HP_0_pl_awlast,
    M_AI_HP_0_pl_awready,
    M_AI_HP_0_pl_awvalid,
    M_AI_HP_0_pl_bready,
    M_AI_HP_0_pl_bvalid,
    M_AI_HP_0_pl_rdata,
    M_AI_HP_0_pl_rlast,
    M_AI_HP_0_pl_rready,
    M_AI_HP_0_pl_rvalid,
    PJTAG_0_tck,
    PJTAG_0_tdi,
    PJTAG_0_tdo,
    PJTAG_0_tms,
    S_AI_GP_0_pl_ra_araddr,
    S_AI_GP_0_pl_ra_arready,
    S_AI_GP_0_pl_ra_arvalid,
    S_AI_GP_0_pl_ra_awaddr,
    S_AI_GP_0_pl_ra_awdata,
    S_AI_GP_0_pl_ra_awready,
    S_AI_GP_0_pl_ra_awvalid,
    S_AI_GP_0_pl_ra_rdata,
    S_AI_GP_0_pl_ra_rready,
    S_AI_GP_0_pl_ra_rvalid,
    S_AXI_HP0_0_araddr,
    S_AXI_HP0_0_arburst,
    S_AXI_HP0_0_arcache,
    S_AXI_HP0_0_arid,
    S_AXI_HP0_0_arlen,
    S_AXI_HP0_0_arlock,
    S_AXI_HP0_0_arprot,
    S_AXI_HP0_0_arqos,
    S_AXI_HP0_0_arready,
    S_AXI_HP0_0_arsize,
    S_AXI_HP0_0_arvalid,
    S_AXI_HP0_0_awaddr,
    S_AXI_HP0_0_awburst,
    S_AXI_HP0_0_awcache,
    S_AXI_HP0_0_awid,
    S_AXI_HP0_0_awlen,
    S_AXI_HP0_0_awlock,
    S_AXI_HP0_0_awprot,
    S_AXI_HP0_0_awqos,
    S_AXI_HP0_0_awready,
    S_AXI_HP0_0_awsize,
    S_AXI_HP0_0_awvalid,
    S_AXI_HP0_0_bid,
    S_AXI_HP0_0_bready,
    S_AXI_HP0_0_bresp,
    S_AXI_HP0_0_bvalid,
    S_AXI_HP0_0_rdata,
    S_AXI_HP0_0_rid,
    S_AXI_HP0_0_rlast,
    S_AXI_HP0_0_rready,
    S_AXI_HP0_0_rresp,
    S_AXI_HP0_0_rvalid,
    S_AXI_HP0_0_wdata,
    S_AXI_HP0_0_wid,
    S_AXI_HP0_0_wlast,
    S_AXI_HP0_0_wready,
    S_AXI_HP0_0_wstrb,
    S_AXI_HP0_0_wvalid,
    S_AXI_HP0_FIFO_CTRL_0_racount,
    S_AXI_HP0_FIFO_CTRL_0_rcount,
    S_AXI_HP0_FIFO_CTRL_0_rdissuecapen,
    S_AXI_HP0_FIFO_CTRL_0_wacount,
    S_AXI_HP0_FIFO_CTRL_0_wcount,
    S_AXI_HP0_FIFO_CTRL_0_wrissuecapen,
    S_AXI_HP1_0_araddr,
    S_AXI_HP1_0_arburst,
    S_AXI_HP1_0_arcache,
    S_AXI_HP1_0_arid,
    S_AXI_HP1_0_arlen,
    S_AXI_HP1_0_arlock,
    S_AXI_HP1_0_arprot,
    S_AXI_HP1_0_arqos,
    S_AXI_HP1_0_arready,
    S_AXI_HP1_0_arsize,
    S_AXI_HP1_0_arvalid,
    S_AXI_HP1_0_awaddr,
    S_AXI_HP1_0_awburst,
    S_AXI_HP1_0_awcache,
    S_AXI_HP1_0_awid,
    S_AXI_HP1_0_awlen,
    S_AXI_HP1_0_awlock,
    S_AXI_HP1_0_awprot,
    S_AXI_HP1_0_awqos,
    S_AXI_HP1_0_awready,
    S_AXI_HP1_0_awsize,
    S_AXI_HP1_0_awvalid,
    S_AXI_HP1_0_bid,
    S_AXI_HP1_0_bready,
    S_AXI_HP1_0_bresp,
    S_AXI_HP1_0_bvalid,
    S_AXI_HP1_0_rdata,
    S_AXI_HP1_0_rid,
    S_AXI_HP1_0_rlast,
    S_AXI_HP1_0_rready,
    S_AXI_HP1_0_rresp,
    S_AXI_HP1_0_rvalid,
    S_AXI_HP1_0_wdata,
    S_AXI_HP1_0_wid,
    S_AXI_HP1_0_wlast,
    S_AXI_HP1_0_wready,
    S_AXI_HP1_0_wstrb,
    S_AXI_HP1_0_wvalid,
    S_AXI_HP1_FIFO_CTRL_0_racount,
    S_AXI_HP1_FIFO_CTRL_0_rcount,
    S_AXI_HP1_FIFO_CTRL_0_rdissuecapen,
    S_AXI_HP1_FIFO_CTRL_0_wacount,
    S_AXI_HP1_FIFO_CTRL_0_wcount,
    S_AXI_HP1_FIFO_CTRL_0_wrissuecapen,
    S_AXI_HP2_0_araddr,
    S_AXI_HP2_0_arburst,
    S_AXI_HP2_0_arcache,
    S_AXI_HP2_0_arid,
    S_AXI_HP2_0_arlen,
    S_AXI_HP2_0_arlock,
    S_AXI_HP2_0_arprot,
    S_AXI_HP2_0_arqos,
    S_AXI_HP2_0_arready,
    S_AXI_HP2_0_arsize,
    S_AXI_HP2_0_arvalid,
    S_AXI_HP2_0_awaddr,
    S_AXI_HP2_0_awburst,
    S_AXI_HP2_0_awcache,
    S_AXI_HP2_0_awid,
    S_AXI_HP2_0_awlen,
    S_AXI_HP2_0_awlock,
    S_AXI_HP2_0_awprot,
    S_AXI_HP2_0_awqos,
    S_AXI_HP2_0_awready,
    S_AXI_HP2_0_awsize,
    S_AXI_HP2_0_awvalid,
    S_AXI_HP2_0_bid,
    S_AXI_HP2_0_bready,
    S_AXI_HP2_0_bresp,
    S_AXI_HP2_0_bvalid,
    S_AXI_HP2_0_rdata,
    S_AXI_HP2_0_rid,
    S_AXI_HP2_0_rlast,
    S_AXI_HP2_0_rready,
    S_AXI_HP2_0_rresp,
    S_AXI_HP2_0_rvalid,
    S_AXI_HP2_0_wdata,
    S_AXI_HP2_0_wid,
    S_AXI_HP2_0_wlast,
    S_AXI_HP2_0_wready,
    S_AXI_HP2_0_wstrb,
    S_AXI_HP2_0_wvalid,
    S_AXI_HP2_1_araddr,
    S_AXI_HP2_1_arburst,
    S_AXI_HP2_1_arcache,
    S_AXI_HP2_1_arid,
    S_AXI_HP2_1_arlen,
    S_AXI_HP2_1_arlock,
    S_AXI_HP2_1_arprot,
    S_AXI_HP2_1_arqos,
    S_AXI_HP2_1_arready,
    S_AXI_HP2_1_arsize,
    S_AXI_HP2_1_arvalid,
    S_AXI_HP2_1_awaddr,
    S_AXI_HP2_1_awburst,
    S_AXI_HP2_1_awcache,
    S_AXI_HP2_1_awid,
    S_AXI_HP2_1_awlen,
    S_AXI_HP2_1_awlock,
    S_AXI_HP2_1_awprot,
    S_AXI_HP2_1_awqos,
    S_AXI_HP2_1_awready,
    S_AXI_HP2_1_awsize,
    S_AXI_HP2_1_awvalid,
    S_AXI_HP2_1_bid,
    S_AXI_HP2_1_bready,
    S_AXI_HP2_1_bresp,
    S_AXI_HP2_1_bvalid,
    S_AXI_HP2_1_rdata,
    S_AXI_HP2_1_rid,
    S_AXI_HP2_1_rlast,
    S_AXI_HP2_1_rready,
    S_AXI_HP2_1_rresp,
    S_AXI_HP2_1_rvalid,
    S_AXI_HP2_1_wdata,
    S_AXI_HP2_1_wid,
    S_AXI_HP2_1_wlast,
    S_AXI_HP2_1_wready,
    S_AXI_HP2_1_wstrb,
    S_AXI_HP2_1_wvalid,
    S_AXI_HP2_FIFO_CTRL_0_racount,
    S_AXI_HP2_FIFO_CTRL_0_rcount,
    S_AXI_HP2_FIFO_CTRL_0_rdissuecapen,
    S_AXI_HP2_FIFO_CTRL_0_wacount,
    S_AXI_HP2_FIFO_CTRL_0_wcount,
    S_AXI_HP2_FIFO_CTRL_0_wrissuecapen,
    S_AXI_HP3_0_araddr,
    S_AXI_HP3_0_arburst,
    S_AXI_HP3_0_arcache,
    S_AXI_HP3_0_arid,
    S_AXI_HP3_0_arlen,
    S_AXI_HP3_0_arlock,
    S_AXI_HP3_0_arprot,
    S_AXI_HP3_0_arqos,
    S_AXI_HP3_0_arready,
    S_AXI_HP3_0_arsize,
    S_AXI_HP3_0_arvalid,
    S_AXI_HP3_0_awaddr,
    S_AXI_HP3_0_awburst,
    S_AXI_HP3_0_awcache,
    S_AXI_HP3_0_awid,
    S_AXI_HP3_0_awlen,
    S_AXI_HP3_0_awlock,
    S_AXI_HP3_0_awprot,
    S_AXI_HP3_0_awqos,
    S_AXI_HP3_0_awready,
    S_AXI_HP3_0_awsize,
    S_AXI_HP3_0_awvalid,
    S_AXI_HP3_0_bid,
    S_AXI_HP3_0_bready,
    S_AXI_HP3_0_bresp,
    S_AXI_HP3_0_bvalid,
    S_AXI_HP3_0_rdata,
    S_AXI_HP3_0_rid,
    S_AXI_HP3_0_rlast,
    S_AXI_HP3_0_rready,
    S_AXI_HP3_0_rresp,
    S_AXI_HP3_0_rvalid,
    S_AXI_HP3_0_wdata,
    S_AXI_HP3_0_wid,
    S_AXI_HP3_0_wlast,
    S_AXI_HP3_0_wready,
    S_AXI_HP3_0_wstrb,
    S_AXI_HP3_0_wvalid,
    S_AXI_HP3_FIFO_CTRL_0_racount,
    S_AXI_HP3_FIFO_CTRL_0_rcount,
    S_AXI_HP3_FIFO_CTRL_0_rdissuecapen,
    S_AXI_HP3_FIFO_CTRL_0_wacount,
    S_AXI_HP3_FIFO_CTRL_0_wcount,
    S_AXI_HP3_FIFO_CTRL_0_wrissuecapen,
    USBIND_0_0_port_indctl,
    USBIND_0_0_vbus_pwrfault,
    USBIND_0_0_vbus_pwrselect,
    User_GP0_araddr,
    User_GP0_arburst,
    User_GP0_arcache,
    User_GP0_arid,
    User_GP0_arlen,
    User_GP0_arlock,
    User_GP0_arprot,
    User_GP0_arqos,
    User_GP0_arready,
    User_GP0_arsize,
    User_GP0_arvalid,
    User_GP0_awaddr,
    User_GP0_awburst,
    User_GP0_awcache,
    User_GP0_awid,
    User_GP0_awlen,
    User_GP0_awlock,
    User_GP0_awprot,
    User_GP0_awqos,
    User_GP0_awready,
    User_GP0_awsize,
    User_GP0_awvalid,
    User_GP0_bid,
    User_GP0_bready,
    User_GP0_bresp,
    User_GP0_bvalid,
    User_GP0_rdata,
    User_GP0_rid,
    User_GP0_rlast,
    User_GP0_rready,
    User_GP0_rresp,
    User_GP0_rvalid,
    User_GP0_wdata,
    User_GP0_wid,
    User_GP0_wlast,
    User_GP0_wready,
    User_GP0_wstrb,
    User_GP0_wvalid,
    User_GP1_araddr,
    User_GP1_arburst,
    User_GP1_arcache,
    User_GP1_arid,
    User_GP1_arlen,
    User_GP1_arlock,
    User_GP1_arprot,
    User_GP1_arqos,
    User_GP1_arready,
    User_GP1_arsize,
    User_GP1_arvalid,
    User_GP1_awaddr,
    User_GP1_awburst,
    User_GP1_awcache,
    User_GP1_awid,
    User_GP1_awlen,
    User_GP1_awlock,
    User_GP1_awprot,
    User_GP1_awqos,
    User_GP1_awready,
    User_GP1_awsize,
    User_GP1_awvalid,
    User_GP1_bid,
    User_GP1_bready,
    User_GP1_bresp,
    User_GP1_bvalid,
    User_GP1_rdata,
    User_GP1_rid,
    User_GP1_rlast,
    User_GP1_rready,
    User_GP1_rresp,
    User_GP1_rvalid,
    User_GP1_wdata,
    User_GP1_wid,
    User_GP1_wlast,
    User_GP1_wready,
    User_GP1_wstrb,
    User_GP1_wvalid,
    ai_irq,
    customop_irq,
    gp_axi_aclk,
    hp_axi_aclk,
    pl_bist_clk_0,
    pl_bist_rstn_0,
    pl_clk_div_out_0,
    pl_clk_en_b_0,
    pl_itf_clk_0,
    pl_ra_clk_0,
    pl_rst_n_0,
    pl_scan_clk_0,
    pl_scan_rst_n_0,
    reset_n,
    soft_rst_n,
    test_irq);
  output AI_BIST_0_pl_bist_done;
  input AI_BIST_0_pl_bist_en;
  output AI_BIST_0_pl_bist_err;
  output AI_BIST_0_pl_bist_err_inv;
  output AI_BIST_0_pl_repair_done;
  output AI_BIST_0_pl_repair_fail;
  output [17:0]AI_IRQ_0_pl_int_info;
  input AI_IRQ_0_pl_int_ready;
  output AI_IRQ_0_pl_int_valid;
  input AI_SCAN_0_pl_scan_compression_mode;
  input [7:0]AI_SCAN_0_pl_scan_cs;
  input AI_SCAN_0_pl_scan_en;
  input [63:0]AI_SCAN_0_pl_scan_in;
  input AI_SCAN_0_pl_scan_mode_b;
  input AI_SCAN_0_pl_scan_occ_bypass;
  input AI_SCAN_0_pl_scan_occ_mode;
  input AI_SCAN_0_pl_scan_occ_reset;
  output [63:0]AI_SCAN_0_pl_scan_out;
  input AI_SCAN_0_pl_scan_wrp_mode;
  input AI_SCAN_0_pl_scan_wrp_shift;
  output [31:0]BYolo_GP0_araddr;
  output [1:0]BYolo_GP0_arburst;
  output [3:0]BYolo_GP0_arcache;
  output [11:0]BYolo_GP0_arid;
  output [3:0]BYolo_GP0_arlen;
  output [1:0]BYolo_GP0_arlock;
  output [2:0]BYolo_GP0_arprot;
  output [3:0]BYolo_GP0_arqos;
  input [0:0]BYolo_GP0_arready;
  output [2:0]BYolo_GP0_arsize;
  output [0:0]BYolo_GP0_arvalid;
  output [31:0]BYolo_GP0_awaddr;
  output [1:0]BYolo_GP0_awburst;
  output [3:0]BYolo_GP0_awcache;
  output [11:0]BYolo_GP0_awid;
  output [3:0]BYolo_GP0_awlen;
  output [1:0]BYolo_GP0_awlock;
  output [2:0]BYolo_GP0_awprot;
  output [3:0]BYolo_GP0_awqos;
  input [0:0]BYolo_GP0_awready;
  output [2:0]BYolo_GP0_awsize;
  output [0:0]BYolo_GP0_awvalid;
  input [11:0]BYolo_GP0_bid;
  output [0:0]BYolo_GP0_bready;
  input [1:0]BYolo_GP0_bresp;
  input [0:0]BYolo_GP0_bvalid;
  input [31:0]BYolo_GP0_rdata;
  input [11:0]BYolo_GP0_rid;
  input [0:0]BYolo_GP0_rlast;
  output [0:0]BYolo_GP0_rready;
  input [1:0]BYolo_GP0_rresp;
  input [0:0]BYolo_GP0_rvalid;
  output [31:0]BYolo_GP0_wdata;
  output [11:0]BYolo_GP0_wid;
  output [0:0]BYolo_GP0_wlast;
  input [0:0]BYolo_GP0_wready;
  output [3:0]BYolo_GP0_wstrb;
  output [0:0]BYolo_GP0_wvalid;
  output [31:0]BYolo_GP1_araddr;
  output [1:0]BYolo_GP1_arburst;
  output [3:0]BYolo_GP1_arcache;
  output [11:0]BYolo_GP1_arid;
  output [3:0]BYolo_GP1_arlen;
  output [1:0]BYolo_GP1_arlock;
  output [2:0]BYolo_GP1_arprot;
  output [3:0]BYolo_GP1_arqos;
  input [0:0]BYolo_GP1_arready;
  output [2:0]BYolo_GP1_arsize;
  output [0:0]BYolo_GP1_arvalid;
  output [31:0]BYolo_GP1_awaddr;
  output [1:0]BYolo_GP1_awburst;
  output [3:0]BYolo_GP1_awcache;
  output [11:0]BYolo_GP1_awid;
  output [3:0]BYolo_GP1_awlen;
  output [1:0]BYolo_GP1_awlock;
  output [2:0]BYolo_GP1_awprot;
  output [3:0]BYolo_GP1_awqos;
  input [0:0]BYolo_GP1_awready;
  output [2:0]BYolo_GP1_awsize;
  output [0:0]BYolo_GP1_awvalid;
  input [11:0]BYolo_GP1_bid;
  output [0:0]BYolo_GP1_bready;
  input [1:0]BYolo_GP1_bresp;
  input [0:0]BYolo_GP1_bvalid;
  input [31:0]BYolo_GP1_rdata;
  input [11:0]BYolo_GP1_rid;
  input [0:0]BYolo_GP1_rlast;
  output [0:0]BYolo_GP1_rready;
  input [1:0]BYolo_GP1_rresp;
  input [0:0]BYolo_GP1_rvalid;
  output [31:0]BYolo_GP1_wdata;
  output [11:0]BYolo_GP1_wid;
  output [0:0]BYolo_GP1_wlast;
  input [0:0]BYolo_GP1_wready;
  output [3:0]BYolo_GP1_wstrb;
  output [0:0]BYolo_GP1_wvalid;
  inout [14:0]DDR_0_addr;
  inout [2:0]DDR_0_ba;
  inout DDR_0_cas_n;
  inout DDR_0_ck_n;
  inout DDR_0_ck_p;
  inout DDR_0_cke;
  inout DDR_0_cs_n;
  inout [3:0]DDR_0_dm;
  inout [31:0]DDR_0_dq;
  inout [3:0]DDR_0_dqs_n;
  inout [3:0]DDR_0_dqs_p;
  inout DDR_0_odt;
  inout DDR_0_ras_n;
  inout DDR_0_reset_n;
  inout DDR_0_we_n;
  output FCLK_CLK0_0;
  output FCLK_RESET0_N_0;
  inout FIXED_IO_0_ddr_vrn;
  inout FIXED_IO_0_ddr_vrp;
  inout [53:0]FIXED_IO_0_mio;
  inout FIXED_IO_0_ps_clk;
  inout FIXED_IO_0_ps_porb;
  inout FIXED_IO_0_ps_srstb;
  output [26:0]M_AI_HP_0_pl_araddr;
  output [5:0]M_AI_HP_0_pl_arinfo;
  output M_AI_HP_0_pl_arlast;
  input M_AI_HP_0_pl_arready;
  output M_AI_HP_0_pl_arvalid;
  output [26:0]M_AI_HP_0_pl_awaddr;
  output [511:0]M_AI_HP_0_pl_awdata;
  output [63:0]M_AI_HP_0_pl_awen;
  output [5:0]M_AI_HP_0_pl_awinfo;
  output M_AI_HP_0_pl_awlast;
  input M_AI_HP_0_pl_awready;
  output M_AI_HP_0_pl_awvalid;
  output M_AI_HP_0_pl_bready;
  input M_AI_HP_0_pl_bvalid;
  input [511:0]M_AI_HP_0_pl_rdata;
  input M_AI_HP_0_pl_rlast;
  output M_AI_HP_0_pl_rready;
  input M_AI_HP_0_pl_rvalid;
  input PJTAG_0_tck;
  input PJTAG_0_tdi;
  output PJTAG_0_tdo;
  input PJTAG_0_tms;
  input [15:0]S_AI_GP_0_pl_ra_araddr;
  output S_AI_GP_0_pl_ra_arready;
  input S_AI_GP_0_pl_ra_arvalid;
  input [15:0]S_AI_GP_0_pl_ra_awaddr;
  input [31:0]S_AI_GP_0_pl_ra_awdata;
  output S_AI_GP_0_pl_ra_awready;
  input S_AI_GP_0_pl_ra_awvalid;
  output [31:0]S_AI_GP_0_pl_ra_rdata;
  input S_AI_GP_0_pl_ra_rready;
  output S_AI_GP_0_pl_ra_rvalid;
  input [31:0]S_AXI_HP0_0_araddr;
  input [1:0]S_AXI_HP0_0_arburst;
  input [3:0]S_AXI_HP0_0_arcache;
  input [5:0]S_AXI_HP0_0_arid;
  input [3:0]S_AXI_HP0_0_arlen;
  input [1:0]S_AXI_HP0_0_arlock;
  input [2:0]S_AXI_HP0_0_arprot;
  input [3:0]S_AXI_HP0_0_arqos;
  output S_AXI_HP0_0_arready;
  input [2:0]S_AXI_HP0_0_arsize;
  input S_AXI_HP0_0_arvalid;
  input [31:0]S_AXI_HP0_0_awaddr;
  input [1:0]S_AXI_HP0_0_awburst;
  input [3:0]S_AXI_HP0_0_awcache;
  input [5:0]S_AXI_HP0_0_awid;
  input [3:0]S_AXI_HP0_0_awlen;
  input [1:0]S_AXI_HP0_0_awlock;
  input [2:0]S_AXI_HP0_0_awprot;
  input [3:0]S_AXI_HP0_0_awqos;
  output S_AXI_HP0_0_awready;
  input [2:0]S_AXI_HP0_0_awsize;
  input S_AXI_HP0_0_awvalid;
  output [5:0]S_AXI_HP0_0_bid;
  input S_AXI_HP0_0_bready;
  output [1:0]S_AXI_HP0_0_bresp;
  output S_AXI_HP0_0_bvalid;
  output [63:0]S_AXI_HP0_0_rdata;
  output [5:0]S_AXI_HP0_0_rid;
  output S_AXI_HP0_0_rlast;
  input S_AXI_HP0_0_rready;
  output [1:0]S_AXI_HP0_0_rresp;
  output S_AXI_HP0_0_rvalid;
  input [63:0]S_AXI_HP0_0_wdata;
  input [5:0]S_AXI_HP0_0_wid;
  input S_AXI_HP0_0_wlast;
  output S_AXI_HP0_0_wready;
  input [7:0]S_AXI_HP0_0_wstrb;
  input S_AXI_HP0_0_wvalid;
  output [2:0]S_AXI_HP0_FIFO_CTRL_0_racount;
  output [7:0]S_AXI_HP0_FIFO_CTRL_0_rcount;
  input S_AXI_HP0_FIFO_CTRL_0_rdissuecapen;
  output [5:0]S_AXI_HP0_FIFO_CTRL_0_wacount;
  output [7:0]S_AXI_HP0_FIFO_CTRL_0_wcount;
  input S_AXI_HP0_FIFO_CTRL_0_wrissuecapen;
  input [31:0]S_AXI_HP1_0_araddr;
  input [1:0]S_AXI_HP1_0_arburst;
  input [3:0]S_AXI_HP1_0_arcache;
  input [5:0]S_AXI_HP1_0_arid;
  input [3:0]S_AXI_HP1_0_arlen;
  input [1:0]S_AXI_HP1_0_arlock;
  input [2:0]S_AXI_HP1_0_arprot;
  input [3:0]S_AXI_HP1_0_arqos;
  output S_AXI_HP1_0_arready;
  input [2:0]S_AXI_HP1_0_arsize;
  input S_AXI_HP1_0_arvalid;
  input [31:0]S_AXI_HP1_0_awaddr;
  input [1:0]S_AXI_HP1_0_awburst;
  input [3:0]S_AXI_HP1_0_awcache;
  input [5:0]S_AXI_HP1_0_awid;
  input [3:0]S_AXI_HP1_0_awlen;
  input [1:0]S_AXI_HP1_0_awlock;
  input [2:0]S_AXI_HP1_0_awprot;
  input [3:0]S_AXI_HP1_0_awqos;
  output S_AXI_HP1_0_awready;
  input [2:0]S_AXI_HP1_0_awsize;
  input S_AXI_HP1_0_awvalid;
  output [5:0]S_AXI_HP1_0_bid;
  input S_AXI_HP1_0_bready;
  output [1:0]S_AXI_HP1_0_bresp;
  output S_AXI_HP1_0_bvalid;
  output [63:0]S_AXI_HP1_0_rdata;
  output [5:0]S_AXI_HP1_0_rid;
  output S_AXI_HP1_0_rlast;
  input S_AXI_HP1_0_rready;
  output [1:0]S_AXI_HP1_0_rresp;
  output S_AXI_HP1_0_rvalid;
  input [63:0]S_AXI_HP1_0_wdata;
  input [5:0]S_AXI_HP1_0_wid;
  input S_AXI_HP1_0_wlast;
  output S_AXI_HP1_0_wready;
  input [7:0]S_AXI_HP1_0_wstrb;
  input S_AXI_HP1_0_wvalid;
  output [2:0]S_AXI_HP1_FIFO_CTRL_0_racount;
  output [7:0]S_AXI_HP1_FIFO_CTRL_0_rcount;
  input S_AXI_HP1_FIFO_CTRL_0_rdissuecapen;
  output [5:0]S_AXI_HP1_FIFO_CTRL_0_wacount;
  output [7:0]S_AXI_HP1_FIFO_CTRL_0_wcount;
  input S_AXI_HP1_FIFO_CTRL_0_wrissuecapen;
  input [31:0]S_AXI_HP2_0_araddr;
  input [1:0]S_AXI_HP2_0_arburst;
  input [3:0]S_AXI_HP2_0_arcache;
  input [4:0]S_AXI_HP2_0_arid;
  input [3:0]S_AXI_HP2_0_arlen;
  input [1:0]S_AXI_HP2_0_arlock;
  input [2:0]S_AXI_HP2_0_arprot;
  input [3:0]S_AXI_HP2_0_arqos;
  output S_AXI_HP2_0_arready;
  input [2:0]S_AXI_HP2_0_arsize;
  input S_AXI_HP2_0_arvalid;
  input [31:0]S_AXI_HP2_0_awaddr;
  input [1:0]S_AXI_HP2_0_awburst;
  input [3:0]S_AXI_HP2_0_awcache;
  input [4:0]S_AXI_HP2_0_awid;
  input [3:0]S_AXI_HP2_0_awlen;
  input [1:0]S_AXI_HP2_0_awlock;
  input [2:0]S_AXI_HP2_0_awprot;
  input [3:0]S_AXI_HP2_0_awqos;
  output S_AXI_HP2_0_awready;
  input [2:0]S_AXI_HP2_0_awsize;
  input S_AXI_HP2_0_awvalid;
  output [4:0]S_AXI_HP2_0_bid;
  input S_AXI_HP2_0_bready;
  output [1:0]S_AXI_HP2_0_bresp;
  output S_AXI_HP2_0_bvalid;
  output [63:0]S_AXI_HP2_0_rdata;
  output [4:0]S_AXI_HP2_0_rid;
  output S_AXI_HP2_0_rlast;
  input S_AXI_HP2_0_rready;
  output [1:0]S_AXI_HP2_0_rresp;
  output S_AXI_HP2_0_rvalid;
  input [63:0]S_AXI_HP2_0_wdata;
  input [4:0]S_AXI_HP2_0_wid;
  input S_AXI_HP2_0_wlast;
  output S_AXI_HP2_0_wready;
  input [7:0]S_AXI_HP2_0_wstrb;
  input S_AXI_HP2_0_wvalid;
  input [31:0]S_AXI_HP2_1_araddr;
  input [1:0]S_AXI_HP2_1_arburst;
  input [3:0]S_AXI_HP2_1_arcache;
  input [4:0]S_AXI_HP2_1_arid;
  input [3:0]S_AXI_HP2_1_arlen;
  input [1:0]S_AXI_HP2_1_arlock;
  input [2:0]S_AXI_HP2_1_arprot;
  input [3:0]S_AXI_HP2_1_arqos;
  output S_AXI_HP2_1_arready;
  input [2:0]S_AXI_HP2_1_arsize;
  input S_AXI_HP2_1_arvalid;
  input [31:0]S_AXI_HP2_1_awaddr;
  input [1:0]S_AXI_HP2_1_awburst;
  input [3:0]S_AXI_HP2_1_awcache;
  input [4:0]S_AXI_HP2_1_awid;
  input [3:0]S_AXI_HP2_1_awlen;
  input [1:0]S_AXI_HP2_1_awlock;
  input [2:0]S_AXI_HP2_1_awprot;
  input [3:0]S_AXI_HP2_1_awqos;
  output S_AXI_HP2_1_awready;
  input [2:0]S_AXI_HP2_1_awsize;
  input S_AXI_HP2_1_awvalid;
  output [4:0]S_AXI_HP2_1_bid;
  input S_AXI_HP2_1_bready;
  output [1:0]S_AXI_HP2_1_bresp;
  output S_AXI_HP2_1_bvalid;
  output [63:0]S_AXI_HP2_1_rdata;
  output [4:0]S_AXI_HP2_1_rid;
  output S_AXI_HP2_1_rlast;
  input S_AXI_HP2_1_rready;
  output [1:0]S_AXI_HP2_1_rresp;
  output S_AXI_HP2_1_rvalid;
  input [63:0]S_AXI_HP2_1_wdata;
  input [4:0]S_AXI_HP2_1_wid;
  input S_AXI_HP2_1_wlast;
  output S_AXI_HP2_1_wready;
  input [7:0]S_AXI_HP2_1_wstrb;
  input S_AXI_HP2_1_wvalid;
  output [2:0]S_AXI_HP2_FIFO_CTRL_0_racount;
  output [7:0]S_AXI_HP2_FIFO_CTRL_0_rcount;
  input S_AXI_HP2_FIFO_CTRL_0_rdissuecapen;
  output [5:0]S_AXI_HP2_FIFO_CTRL_0_wacount;
  output [7:0]S_AXI_HP2_FIFO_CTRL_0_wcount;
  input S_AXI_HP2_FIFO_CTRL_0_wrissuecapen;
  input [31:0]S_AXI_HP3_0_araddr;
  input [1:0]S_AXI_HP3_0_arburst;
  input [3:0]S_AXI_HP3_0_arcache;
  input [5:0]S_AXI_HP3_0_arid;
  input [3:0]S_AXI_HP3_0_arlen;
  input [1:0]S_AXI_HP3_0_arlock;
  input [2:0]S_AXI_HP3_0_arprot;
  input [3:0]S_AXI_HP3_0_arqos;
  output S_AXI_HP3_0_arready;
  input [2:0]S_AXI_HP3_0_arsize;
  input S_AXI_HP3_0_arvalid;
  input [31:0]S_AXI_HP3_0_awaddr;
  input [1:0]S_AXI_HP3_0_awburst;
  input [3:0]S_AXI_HP3_0_awcache;
  input [5:0]S_AXI_HP3_0_awid;
  input [3:0]S_AXI_HP3_0_awlen;
  input [1:0]S_AXI_HP3_0_awlock;
  input [2:0]S_AXI_HP3_0_awprot;
  input [3:0]S_AXI_HP3_0_awqos;
  output S_AXI_HP3_0_awready;
  input [2:0]S_AXI_HP3_0_awsize;
  input S_AXI_HP3_0_awvalid;
  output [5:0]S_AXI_HP3_0_bid;
  input S_AXI_HP3_0_bready;
  output [1:0]S_AXI_HP3_0_bresp;
  output S_AXI_HP3_0_bvalid;
  output [63:0]S_AXI_HP3_0_rdata;
  output [5:0]S_AXI_HP3_0_rid;
  output S_AXI_HP3_0_rlast;
  input S_AXI_HP3_0_rready;
  output [1:0]S_AXI_HP3_0_rresp;
  output S_AXI_HP3_0_rvalid;
  input [63:0]S_AXI_HP3_0_wdata;
  input [5:0]S_AXI_HP3_0_wid;
  input S_AXI_HP3_0_wlast;
  output S_AXI_HP3_0_wready;
  input [7:0]S_AXI_HP3_0_wstrb;
  input S_AXI_HP3_0_wvalid;
  output [2:0]S_AXI_HP3_FIFO_CTRL_0_racount;
  output [7:0]S_AXI_HP3_FIFO_CTRL_0_rcount;
  input S_AXI_HP3_FIFO_CTRL_0_rdissuecapen;
  output [5:0]S_AXI_HP3_FIFO_CTRL_0_wacount;
  output [7:0]S_AXI_HP3_FIFO_CTRL_0_wcount;
  input S_AXI_HP3_FIFO_CTRL_0_wrissuecapen;
  output [1:0]USBIND_0_0_port_indctl;
  input USBIND_0_0_vbus_pwrfault;
  output USBIND_0_0_vbus_pwrselect;
  output [31:0]User_GP0_araddr;
  output [1:0]User_GP0_arburst;
  output [3:0]User_GP0_arcache;
  output [11:0]User_GP0_arid;
  output [3:0]User_GP0_arlen;
  output [1:0]User_GP0_arlock;
  output [2:0]User_GP0_arprot;
  output [3:0]User_GP0_arqos;
  input [0:0]User_GP0_arready;
  output [2:0]User_GP0_arsize;
  output [0:0]User_GP0_arvalid;
  output [31:0]User_GP0_awaddr;
  output [1:0]User_GP0_awburst;
  output [3:0]User_GP0_awcache;
  output [11:0]User_GP0_awid;
  output [3:0]User_GP0_awlen;
  output [1:0]User_GP0_awlock;
  output [2:0]User_GP0_awprot;
  output [3:0]User_GP0_awqos;
  input [0:0]User_GP0_awready;
  output [2:0]User_GP0_awsize;
  output [0:0]User_GP0_awvalid;
  input [11:0]User_GP0_bid;
  output [0:0]User_GP0_bready;
  input [1:0]User_GP0_bresp;
  input [0:0]User_GP0_bvalid;
  input [31:0]User_GP0_rdata;
  input [11:0]User_GP0_rid;
  input [0:0]User_GP0_rlast;
  output [0:0]User_GP0_rready;
  input [1:0]User_GP0_rresp;
  input [0:0]User_GP0_rvalid;
  output [31:0]User_GP0_wdata;
  output [11:0]User_GP0_wid;
  output [0:0]User_GP0_wlast;
  input [0:0]User_GP0_wready;
  output [3:0]User_GP0_wstrb;
  output [0:0]User_GP0_wvalid;
  output [31:0]User_GP1_araddr;
  output [1:0]User_GP1_arburst;
  output [3:0]User_GP1_arcache;
  output [11:0]User_GP1_arid;
  output [3:0]User_GP1_arlen;
  output [1:0]User_GP1_arlock;
  output [2:0]User_GP1_arprot;
  output [3:0]User_GP1_arqos;
  input [0:0]User_GP1_arready;
  output [2:0]User_GP1_arsize;
  output [0:0]User_GP1_arvalid;
  output [31:0]User_GP1_awaddr;
  output [1:0]User_GP1_awburst;
  output [3:0]User_GP1_awcache;
  output [11:0]User_GP1_awid;
  output [3:0]User_GP1_awlen;
  output [1:0]User_GP1_awlock;
  output [2:0]User_GP1_awprot;
  output [3:0]User_GP1_awqos;
  input [0:0]User_GP1_awready;
  output [2:0]User_GP1_awsize;
  output [0:0]User_GP1_awvalid;
  input [11:0]User_GP1_bid;
  output [0:0]User_GP1_bready;
  input [1:0]User_GP1_bresp;
  input [0:0]User_GP1_bvalid;
  input [31:0]User_GP1_rdata;
  input [11:0]User_GP1_rid;
  input [0:0]User_GP1_rlast;
  output [0:0]User_GP1_rready;
  input [1:0]User_GP1_rresp;
  input [0:0]User_GP1_rvalid;
  output [31:0]User_GP1_wdata;
  output [11:0]User_GP1_wid;
  output [0:0]User_GP1_wlast;
  input [0:0]User_GP1_wready;
  output [3:0]User_GP1_wstrb;
  output [0:0]User_GP1_wvalid;
  input ai_irq;
  input customop_irq;
  input gp_axi_aclk;
  input hp_axi_aclk;
  input pl_bist_clk_0;
  input pl_bist_rstn_0;
  output pl_clk_div_out_0;
  input pl_clk_en_b_0;
  input pl_itf_clk_0;
  input pl_ra_clk_0;
  input pl_rst_n_0;
  input pl_scan_clk_0;
  input pl_scan_rst_n_0;
  input reset_n;
  input soft_rst_n;
  input test_irq;

  wire AI_BIST_0_pl_bist_done;
  wire AI_BIST_0_pl_bist_en;
  wire AI_BIST_0_pl_bist_err;
  wire AI_BIST_0_pl_bist_err_inv;
  wire AI_BIST_0_pl_repair_done;
  wire AI_BIST_0_pl_repair_fail;
  wire [17:0]AI_IRQ_0_pl_int_info;
  wire AI_IRQ_0_pl_int_ready;
  wire AI_IRQ_0_pl_int_valid;
  wire AI_SCAN_0_pl_scan_compression_mode;
  wire [7:0]AI_SCAN_0_pl_scan_cs;
  wire AI_SCAN_0_pl_scan_en;
  wire [63:0]AI_SCAN_0_pl_scan_in;
  wire AI_SCAN_0_pl_scan_mode_b;
  wire AI_SCAN_0_pl_scan_occ_bypass;
  wire AI_SCAN_0_pl_scan_occ_mode;
  wire AI_SCAN_0_pl_scan_occ_reset;
  wire [63:0]AI_SCAN_0_pl_scan_out;
  wire AI_SCAN_0_pl_scan_wrp_mode;
  wire AI_SCAN_0_pl_scan_wrp_shift;
  wire [31:0]BYolo_GP0_araddr;
  wire [1:0]BYolo_GP0_arburst;
  wire [3:0]BYolo_GP0_arcache;
  wire [11:0]BYolo_GP0_arid;
  wire [3:0]BYolo_GP0_arlen;
  wire [1:0]BYolo_GP0_arlock;
  wire [2:0]BYolo_GP0_arprot;
  wire [3:0]BYolo_GP0_arqos;
  wire [0:0]BYolo_GP0_arready;
  wire [2:0]BYolo_GP0_arsize;
  wire [0:0]BYolo_GP0_arvalid;
  wire [31:0]BYolo_GP0_awaddr;
  wire [1:0]BYolo_GP0_awburst;
  wire [3:0]BYolo_GP0_awcache;
  wire [11:0]BYolo_GP0_awid;
  wire [3:0]BYolo_GP0_awlen;
  wire [1:0]BYolo_GP0_awlock;
  wire [2:0]BYolo_GP0_awprot;
  wire [3:0]BYolo_GP0_awqos;
  wire [0:0]BYolo_GP0_awready;
  wire [2:0]BYolo_GP0_awsize;
  wire [0:0]BYolo_GP0_awvalid;
  wire [11:0]BYolo_GP0_bid;
  wire [0:0]BYolo_GP0_bready;
  wire [1:0]BYolo_GP0_bresp;
  wire [0:0]BYolo_GP0_bvalid;
  wire [31:0]BYolo_GP0_rdata;
  wire [11:0]BYolo_GP0_rid;
  wire [0:0]BYolo_GP0_rlast;
  wire [0:0]BYolo_GP0_rready;
  wire [1:0]BYolo_GP0_rresp;
  wire [0:0]BYolo_GP0_rvalid;
  wire [31:0]BYolo_GP0_wdata;
  wire [11:0]BYolo_GP0_wid;
  wire [0:0]BYolo_GP0_wlast;
  wire [0:0]BYolo_GP0_wready;
  wire [3:0]BYolo_GP0_wstrb;
  wire [0:0]BYolo_GP0_wvalid;
  wire [31:0]BYolo_GP1_araddr;
  wire [1:0]BYolo_GP1_arburst;
  wire [3:0]BYolo_GP1_arcache;
  wire [11:0]BYolo_GP1_arid;
  wire [3:0]BYolo_GP1_arlen;
  wire [1:0]BYolo_GP1_arlock;
  wire [2:0]BYolo_GP1_arprot;
  wire [3:0]BYolo_GP1_arqos;
  wire [0:0]BYolo_GP1_arready;
  wire [2:0]BYolo_GP1_arsize;
  wire [0:0]BYolo_GP1_arvalid;
  wire [31:0]BYolo_GP1_awaddr;
  wire [1:0]BYolo_GP1_awburst;
  wire [3:0]BYolo_GP1_awcache;
  wire [11:0]BYolo_GP1_awid;
  wire [3:0]BYolo_GP1_awlen;
  wire [1:0]BYolo_GP1_awlock;
  wire [2:0]BYolo_GP1_awprot;
  wire [3:0]BYolo_GP1_awqos;
  wire [0:0]BYolo_GP1_awready;
  wire [2:0]BYolo_GP1_awsize;
  wire [0:0]BYolo_GP1_awvalid;
  wire [11:0]BYolo_GP1_bid;
  wire [0:0]BYolo_GP1_bready;
  wire [1:0]BYolo_GP1_bresp;
  wire [0:0]BYolo_GP1_bvalid;
  wire [31:0]BYolo_GP1_rdata;
  wire [11:0]BYolo_GP1_rid;
  wire [0:0]BYolo_GP1_rlast;
  wire [0:0]BYolo_GP1_rready;
  wire [1:0]BYolo_GP1_rresp;
  wire [0:0]BYolo_GP1_rvalid;
  wire [31:0]BYolo_GP1_wdata;
  wire [11:0]BYolo_GP1_wid;
  wire [0:0]BYolo_GP1_wlast;
  wire [0:0]BYolo_GP1_wready;
  wire [3:0]BYolo_GP1_wstrb;
  wire [0:0]BYolo_GP1_wvalid;
  wire [14:0]DDR_0_addr;
  wire [2:0]DDR_0_ba;
  wire DDR_0_cas_n;
  wire DDR_0_ck_n;
  wire DDR_0_ck_p;
  wire DDR_0_cke;
  wire DDR_0_cs_n;
  wire [3:0]DDR_0_dm;
  wire [31:0]DDR_0_dq;
  wire [3:0]DDR_0_dqs_n;
  wire [3:0]DDR_0_dqs_p;
  wire DDR_0_odt;
  wire DDR_0_ras_n;
  wire DDR_0_reset_n;
  wire DDR_0_we_n;
  wire FCLK_CLK0_0;
  wire FCLK_RESET0_N_0;
  wire FIXED_IO_0_ddr_vrn;
  wire FIXED_IO_0_ddr_vrp;
  wire [53:0]FIXED_IO_0_mio;
  wire FIXED_IO_0_ps_clk;
  wire FIXED_IO_0_ps_porb;
  wire FIXED_IO_0_ps_srstb;
  wire [26:0]M_AI_HP_0_pl_araddr;
  wire [5:0]M_AI_HP_0_pl_arinfo;
  wire M_AI_HP_0_pl_arlast;
  wire M_AI_HP_0_pl_arready;
  wire M_AI_HP_0_pl_arvalid;
  wire [26:0]M_AI_HP_0_pl_awaddr;
  wire [511:0]M_AI_HP_0_pl_awdata;
  wire [63:0]M_AI_HP_0_pl_awen;
  wire [5:0]M_AI_HP_0_pl_awinfo;
  wire M_AI_HP_0_pl_awlast;
  wire M_AI_HP_0_pl_awready;
  wire M_AI_HP_0_pl_awvalid;
  wire M_AI_HP_0_pl_bready;
  wire M_AI_HP_0_pl_bvalid;
  wire [511:0]M_AI_HP_0_pl_rdata;
  wire M_AI_HP_0_pl_rlast;
  wire M_AI_HP_0_pl_rready;
  wire M_AI_HP_0_pl_rvalid;
  wire PJTAG_0_tck;
  wire PJTAG_0_tdi;
  wire PJTAG_0_tdo;
  wire PJTAG_0_tms;
  wire [15:0]S_AI_GP_0_pl_ra_araddr;
  wire S_AI_GP_0_pl_ra_arready;
  wire S_AI_GP_0_pl_ra_arvalid;
  wire [15:0]S_AI_GP_0_pl_ra_awaddr;
  wire [31:0]S_AI_GP_0_pl_ra_awdata;
  wire S_AI_GP_0_pl_ra_awready;
  wire S_AI_GP_0_pl_ra_awvalid;
  wire [31:0]S_AI_GP_0_pl_ra_rdata;
  wire S_AI_GP_0_pl_ra_rready;
  wire S_AI_GP_0_pl_ra_rvalid;
  wire [31:0]S_AXI_HP0_0_araddr;
  wire [1:0]S_AXI_HP0_0_arburst;
  wire [3:0]S_AXI_HP0_0_arcache;
  wire [5:0]S_AXI_HP0_0_arid;
  wire [3:0]S_AXI_HP0_0_arlen;
  wire [1:0]S_AXI_HP0_0_arlock;
  wire [2:0]S_AXI_HP0_0_arprot;
  wire [3:0]S_AXI_HP0_0_arqos;
  wire S_AXI_HP0_0_arready;
  wire [2:0]S_AXI_HP0_0_arsize;
  wire S_AXI_HP0_0_arvalid;
  wire [31:0]S_AXI_HP0_0_awaddr;
  wire [1:0]S_AXI_HP0_0_awburst;
  wire [3:0]S_AXI_HP0_0_awcache;
  wire [5:0]S_AXI_HP0_0_awid;
  wire [3:0]S_AXI_HP0_0_awlen;
  wire [1:0]S_AXI_HP0_0_awlock;
  wire [2:0]S_AXI_HP0_0_awprot;
  wire [3:0]S_AXI_HP0_0_awqos;
  wire S_AXI_HP0_0_awready;
  wire [2:0]S_AXI_HP0_0_awsize;
  wire S_AXI_HP0_0_awvalid;
  wire [5:0]S_AXI_HP0_0_bid;
  wire S_AXI_HP0_0_bready;
  wire [1:0]S_AXI_HP0_0_bresp;
  wire S_AXI_HP0_0_bvalid;
  wire [63:0]S_AXI_HP0_0_rdata;
  wire [5:0]S_AXI_HP0_0_rid;
  wire S_AXI_HP0_0_rlast;
  wire S_AXI_HP0_0_rready;
  wire [1:0]S_AXI_HP0_0_rresp;
  wire S_AXI_HP0_0_rvalid;
  wire [63:0]S_AXI_HP0_0_wdata;
  wire [5:0]S_AXI_HP0_0_wid;
  wire S_AXI_HP0_0_wlast;
  wire S_AXI_HP0_0_wready;
  wire [7:0]S_AXI_HP0_0_wstrb;
  wire S_AXI_HP0_0_wvalid;
  wire [2:0]S_AXI_HP0_FIFO_CTRL_0_racount;
  wire [7:0]S_AXI_HP0_FIFO_CTRL_0_rcount;
  wire S_AXI_HP0_FIFO_CTRL_0_rdissuecapen;
  wire [5:0]S_AXI_HP0_FIFO_CTRL_0_wacount;
  wire [7:0]S_AXI_HP0_FIFO_CTRL_0_wcount;
  wire S_AXI_HP0_FIFO_CTRL_0_wrissuecapen;
  wire [31:0]S_AXI_HP1_0_araddr;
  wire [1:0]S_AXI_HP1_0_arburst;
  wire [3:0]S_AXI_HP1_0_arcache;
  wire [5:0]S_AXI_HP1_0_arid;
  wire [3:0]S_AXI_HP1_0_arlen;
  wire [1:0]S_AXI_HP1_0_arlock;
  wire [2:0]S_AXI_HP1_0_arprot;
  wire [3:0]S_AXI_HP1_0_arqos;
  wire S_AXI_HP1_0_arready;
  wire [2:0]S_AXI_HP1_0_arsize;
  wire S_AXI_HP1_0_arvalid;
  wire [31:0]S_AXI_HP1_0_awaddr;
  wire [1:0]S_AXI_HP1_0_awburst;
  wire [3:0]S_AXI_HP1_0_awcache;
  wire [5:0]S_AXI_HP1_0_awid;
  wire [3:0]S_AXI_HP1_0_awlen;
  wire [1:0]S_AXI_HP1_0_awlock;
  wire [2:0]S_AXI_HP1_0_awprot;
  wire [3:0]S_AXI_HP1_0_awqos;
  wire S_AXI_HP1_0_awready;
  wire [2:0]S_AXI_HP1_0_awsize;
  wire S_AXI_HP1_0_awvalid;
  wire [5:0]S_AXI_HP1_0_bid;
  wire S_AXI_HP1_0_bready;
  wire [1:0]S_AXI_HP1_0_bresp;
  wire S_AXI_HP1_0_bvalid;
  wire [63:0]S_AXI_HP1_0_rdata;
  wire [5:0]S_AXI_HP1_0_rid;
  wire S_AXI_HP1_0_rlast;
  wire S_AXI_HP1_0_rready;
  wire [1:0]S_AXI_HP1_0_rresp;
  wire S_AXI_HP1_0_rvalid;
  wire [63:0]S_AXI_HP1_0_wdata;
  wire [5:0]S_AXI_HP1_0_wid;
  wire S_AXI_HP1_0_wlast;
  wire S_AXI_HP1_0_wready;
  wire [7:0]S_AXI_HP1_0_wstrb;
  wire S_AXI_HP1_0_wvalid;
  wire [2:0]S_AXI_HP1_FIFO_CTRL_0_racount;
  wire [7:0]S_AXI_HP1_FIFO_CTRL_0_rcount;
  wire S_AXI_HP1_FIFO_CTRL_0_rdissuecapen;
  wire [5:0]S_AXI_HP1_FIFO_CTRL_0_wacount;
  wire [7:0]S_AXI_HP1_FIFO_CTRL_0_wcount;
  wire S_AXI_HP1_FIFO_CTRL_0_wrissuecapen;
  wire [31:0]S_AXI_HP2_0_araddr;
  wire [1:0]S_AXI_HP2_0_arburst;
  wire [3:0]S_AXI_HP2_0_arcache;
  wire [4:0]S_AXI_HP2_0_arid;
  wire [3:0]S_AXI_HP2_0_arlen;
  wire [1:0]S_AXI_HP2_0_arlock;
  wire [2:0]S_AXI_HP2_0_arprot;
  wire [3:0]S_AXI_HP2_0_arqos;
  wire S_AXI_HP2_0_arready;
  wire [2:0]S_AXI_HP2_0_arsize;
  wire S_AXI_HP2_0_arvalid;
  wire [31:0]S_AXI_HP2_0_awaddr;
  wire [1:0]S_AXI_HP2_0_awburst;
  wire [3:0]S_AXI_HP2_0_awcache;
  wire [4:0]S_AXI_HP2_0_awid;
  wire [3:0]S_AXI_HP2_0_awlen;
  wire [1:0]S_AXI_HP2_0_awlock;
  wire [2:0]S_AXI_HP2_0_awprot;
  wire [3:0]S_AXI_HP2_0_awqos;
  wire S_AXI_HP2_0_awready;
  wire [2:0]S_AXI_HP2_0_awsize;
  wire S_AXI_HP2_0_awvalid;
  wire [4:0]S_AXI_HP2_0_bid;
  wire S_AXI_HP2_0_bready;
  wire [1:0]S_AXI_HP2_0_bresp;
  wire S_AXI_HP2_0_bvalid;
  wire [63:0]S_AXI_HP2_0_rdata;
  wire [4:0]S_AXI_HP2_0_rid;
  wire S_AXI_HP2_0_rlast;
  wire S_AXI_HP2_0_rready;
  wire [1:0]S_AXI_HP2_0_rresp;
  wire S_AXI_HP2_0_rvalid;
  wire [63:0]S_AXI_HP2_0_wdata;
  wire [4:0]S_AXI_HP2_0_wid;
  wire S_AXI_HP2_0_wlast;
  wire S_AXI_HP2_0_wready;
  wire [7:0]S_AXI_HP2_0_wstrb;
  wire S_AXI_HP2_0_wvalid;
  wire [31:0]S_AXI_HP2_1_araddr;
  wire [1:0]S_AXI_HP2_1_arburst;
  wire [3:0]S_AXI_HP2_1_arcache;
  wire [4:0]S_AXI_HP2_1_arid;
  wire [3:0]S_AXI_HP2_1_arlen;
  wire [1:0]S_AXI_HP2_1_arlock;
  wire [2:0]S_AXI_HP2_1_arprot;
  wire [3:0]S_AXI_HP2_1_arqos;
  wire S_AXI_HP2_1_arready;
  wire [2:0]S_AXI_HP2_1_arsize;
  wire S_AXI_HP2_1_arvalid;
  wire [31:0]S_AXI_HP2_1_awaddr;
  wire [1:0]S_AXI_HP2_1_awburst;
  wire [3:0]S_AXI_HP2_1_awcache;
  wire [4:0]S_AXI_HP2_1_awid;
  wire [3:0]S_AXI_HP2_1_awlen;
  wire [1:0]S_AXI_HP2_1_awlock;
  wire [2:0]S_AXI_HP2_1_awprot;
  wire [3:0]S_AXI_HP2_1_awqos;
  wire S_AXI_HP2_1_awready;
  wire [2:0]S_AXI_HP2_1_awsize;
  wire S_AXI_HP2_1_awvalid;
  wire [4:0]S_AXI_HP2_1_bid;
  wire S_AXI_HP2_1_bready;
  wire [1:0]S_AXI_HP2_1_bresp;
  wire S_AXI_HP2_1_bvalid;
  wire [63:0]S_AXI_HP2_1_rdata;
  wire [4:0]S_AXI_HP2_1_rid;
  wire S_AXI_HP2_1_rlast;
  wire S_AXI_HP2_1_rready;
  wire [1:0]S_AXI_HP2_1_rresp;
  wire S_AXI_HP2_1_rvalid;
  wire [63:0]S_AXI_HP2_1_wdata;
  wire [4:0]S_AXI_HP2_1_wid;
  wire S_AXI_HP2_1_wlast;
  wire S_AXI_HP2_1_wready;
  wire [7:0]S_AXI_HP2_1_wstrb;
  wire S_AXI_HP2_1_wvalid;
  wire [2:0]S_AXI_HP2_FIFO_CTRL_0_racount;
  wire [7:0]S_AXI_HP2_FIFO_CTRL_0_rcount;
  wire S_AXI_HP2_FIFO_CTRL_0_rdissuecapen;
  wire [5:0]S_AXI_HP2_FIFO_CTRL_0_wacount;
  wire [7:0]S_AXI_HP2_FIFO_CTRL_0_wcount;
  wire S_AXI_HP2_FIFO_CTRL_0_wrissuecapen;
  wire [31:0]S_AXI_HP3_0_araddr;
  wire [1:0]S_AXI_HP3_0_arburst;
  wire [3:0]S_AXI_HP3_0_arcache;
  wire [5:0]S_AXI_HP3_0_arid;
  wire [3:0]S_AXI_HP3_0_arlen;
  wire [1:0]S_AXI_HP3_0_arlock;
  wire [2:0]S_AXI_HP3_0_arprot;
  wire [3:0]S_AXI_HP3_0_arqos;
  wire S_AXI_HP3_0_arready;
  wire [2:0]S_AXI_HP3_0_arsize;
  wire S_AXI_HP3_0_arvalid;
  wire [31:0]S_AXI_HP3_0_awaddr;
  wire [1:0]S_AXI_HP3_0_awburst;
  wire [3:0]S_AXI_HP3_0_awcache;
  wire [5:0]S_AXI_HP3_0_awid;
  wire [3:0]S_AXI_HP3_0_awlen;
  wire [1:0]S_AXI_HP3_0_awlock;
  wire [2:0]S_AXI_HP3_0_awprot;
  wire [3:0]S_AXI_HP3_0_awqos;
  wire S_AXI_HP3_0_awready;
  wire [2:0]S_AXI_HP3_0_awsize;
  wire S_AXI_HP3_0_awvalid;
  wire [5:0]S_AXI_HP3_0_bid;
  wire S_AXI_HP3_0_bready;
  wire [1:0]S_AXI_HP3_0_bresp;
  wire S_AXI_HP3_0_bvalid;
  wire [63:0]S_AXI_HP3_0_rdata;
  wire [5:0]S_AXI_HP3_0_rid;
  wire S_AXI_HP3_0_rlast;
  wire S_AXI_HP3_0_rready;
  wire [1:0]S_AXI_HP3_0_rresp;
  wire S_AXI_HP3_0_rvalid;
  wire [63:0]S_AXI_HP3_0_wdata;
  wire [5:0]S_AXI_HP3_0_wid;
  wire S_AXI_HP3_0_wlast;
  wire S_AXI_HP3_0_wready;
  wire [7:0]S_AXI_HP3_0_wstrb;
  wire S_AXI_HP3_0_wvalid;
  wire [2:0]S_AXI_HP3_FIFO_CTRL_0_racount;
  wire [7:0]S_AXI_HP3_FIFO_CTRL_0_rcount;
  wire S_AXI_HP3_FIFO_CTRL_0_rdissuecapen;
  wire [5:0]S_AXI_HP3_FIFO_CTRL_0_wacount;
  wire [7:0]S_AXI_HP3_FIFO_CTRL_0_wcount;
  wire S_AXI_HP3_FIFO_CTRL_0_wrissuecapen;
  wire [1:0]USBIND_0_0_port_indctl;
  wire USBIND_0_0_vbus_pwrfault;
  wire USBIND_0_0_vbus_pwrselect;
  wire [31:0]User_GP0_araddr;
  wire [1:0]User_GP0_arburst;
  wire [3:0]User_GP0_arcache;
  wire [11:0]User_GP0_arid;
  wire [3:0]User_GP0_arlen;
  wire [1:0]User_GP0_arlock;
  wire [2:0]User_GP0_arprot;
  wire [3:0]User_GP0_arqos;
  wire [0:0]User_GP0_arready;
  wire [2:0]User_GP0_arsize;
  wire [0:0]User_GP0_arvalid;
  wire [31:0]User_GP0_awaddr;
  wire [1:0]User_GP0_awburst;
  wire [3:0]User_GP0_awcache;
  wire [11:0]User_GP0_awid;
  wire [3:0]User_GP0_awlen;
  wire [1:0]User_GP0_awlock;
  wire [2:0]User_GP0_awprot;
  wire [3:0]User_GP0_awqos;
  wire [0:0]User_GP0_awready;
  wire [2:0]User_GP0_awsize;
  wire [0:0]User_GP0_awvalid;
  wire [11:0]User_GP0_bid;
  wire [0:0]User_GP0_bready;
  wire [1:0]User_GP0_bresp;
  wire [0:0]User_GP0_bvalid;
  wire [31:0]User_GP0_rdata;
  wire [11:0]User_GP0_rid;
  wire [0:0]User_GP0_rlast;
  wire [0:0]User_GP0_rready;
  wire [1:0]User_GP0_rresp;
  wire [0:0]User_GP0_rvalid;
  wire [31:0]User_GP0_wdata;
  wire [11:0]User_GP0_wid;
  wire [0:0]User_GP0_wlast;
  wire [0:0]User_GP0_wready;
  wire [3:0]User_GP0_wstrb;
  wire [0:0]User_GP0_wvalid;
  wire [31:0]User_GP1_araddr;
  wire [1:0]User_GP1_arburst;
  wire [3:0]User_GP1_arcache;
  wire [11:0]User_GP1_arid;
  wire [3:0]User_GP1_arlen;
  wire [1:0]User_GP1_arlock;
  wire [2:0]User_GP1_arprot;
  wire [3:0]User_GP1_arqos;
  wire [0:0]User_GP1_arready;
  wire [2:0]User_GP1_arsize;
  wire [0:0]User_GP1_arvalid;
  wire [31:0]User_GP1_awaddr;
  wire [1:0]User_GP1_awburst;
  wire [3:0]User_GP1_awcache;
  wire [11:0]User_GP1_awid;
  wire [3:0]User_GP1_awlen;
  wire [1:0]User_GP1_awlock;
  wire [2:0]User_GP1_awprot;
  wire [3:0]User_GP1_awqos;
  wire [0:0]User_GP1_awready;
  wire [2:0]User_GP1_awsize;
  wire [0:0]User_GP1_awvalid;
  wire [11:0]User_GP1_bid;
  wire [0:0]User_GP1_bready;
  wire [1:0]User_GP1_bresp;
  wire [0:0]User_GP1_bvalid;
  wire [31:0]User_GP1_rdata;
  wire [11:0]User_GP1_rid;
  wire [0:0]User_GP1_rlast;
  wire [0:0]User_GP1_rready;
  wire [1:0]User_GP1_rresp;
  wire [0:0]User_GP1_rvalid;
  wire [31:0]User_GP1_wdata;
  wire [11:0]User_GP1_wid;
  wire [0:0]User_GP1_wlast;
  wire [0:0]User_GP1_wready;
  wire [3:0]User_GP1_wstrb;
  wire [0:0]User_GP1_wvalid;
  wire ai_irq;
  wire customop_irq;
  wire gp_axi_aclk;
  wire hp_axi_aclk;
  wire pl_bist_clk_0;
  wire pl_bist_rstn_0;
  wire pl_clk_div_out_0;
  wire pl_clk_en_b_0;
  wire pl_itf_clk_0;
  wire pl_ra_clk_0;
  wire pl_rst_n_0;
  wire pl_scan_clk_0;
  wire pl_scan_rst_n_0;
  wire reset_n;
  wire soft_rst_n;
  wire test_irq;

  ps_ai ps_ai_i
       (.AI_BIST_0_pl_bist_done(AI_BIST_0_pl_bist_done),
        .AI_BIST_0_pl_bist_en(AI_BIST_0_pl_bist_en),
        .AI_BIST_0_pl_bist_err(AI_BIST_0_pl_bist_err),
        .AI_BIST_0_pl_bist_err_inv(AI_BIST_0_pl_bist_err_inv),
        .AI_BIST_0_pl_repair_done(AI_BIST_0_pl_repair_done),
        .AI_BIST_0_pl_repair_fail(AI_BIST_0_pl_repair_fail),
        .AI_IRQ_0_pl_int_info(AI_IRQ_0_pl_int_info),
        .AI_IRQ_0_pl_int_ready(AI_IRQ_0_pl_int_ready),
        .AI_IRQ_0_pl_int_valid(AI_IRQ_0_pl_int_valid),
        .AI_SCAN_0_pl_scan_compression_mode(AI_SCAN_0_pl_scan_compression_mode),
        .AI_SCAN_0_pl_scan_cs(AI_SCAN_0_pl_scan_cs),
        .AI_SCAN_0_pl_scan_en(AI_SCAN_0_pl_scan_en),
        .AI_SCAN_0_pl_scan_in(AI_SCAN_0_pl_scan_in),
        .AI_SCAN_0_pl_scan_mode_b(AI_SCAN_0_pl_scan_mode_b),
        .AI_SCAN_0_pl_scan_occ_bypass(AI_SCAN_0_pl_scan_occ_bypass),
        .AI_SCAN_0_pl_scan_occ_mode(AI_SCAN_0_pl_scan_occ_mode),
        .AI_SCAN_0_pl_scan_occ_reset(AI_SCAN_0_pl_scan_occ_reset),
        .AI_SCAN_0_pl_scan_out(AI_SCAN_0_pl_scan_out),
        .AI_SCAN_0_pl_scan_wrp_mode(AI_SCAN_0_pl_scan_wrp_mode),
        .AI_SCAN_0_pl_scan_wrp_shift(AI_SCAN_0_pl_scan_wrp_shift),
        .BYolo_GP0_araddr(BYolo_GP0_araddr),
        .BYolo_GP0_arburst(BYolo_GP0_arburst),
        .BYolo_GP0_arcache(BYolo_GP0_arcache),
        .BYolo_GP0_arid(BYolo_GP0_arid),
        .BYolo_GP0_arlen(BYolo_GP0_arlen),
        .BYolo_GP0_arlock(BYolo_GP0_arlock),
        .BYolo_GP0_arprot(BYolo_GP0_arprot),
        .BYolo_GP0_arqos(BYolo_GP0_arqos),
        .BYolo_GP0_arready(BYolo_GP0_arready),
        .BYolo_GP0_arsize(BYolo_GP0_arsize),
        .BYolo_GP0_arvalid(BYolo_GP0_arvalid),
        .BYolo_GP0_awaddr(BYolo_GP0_awaddr),
        .BYolo_GP0_awburst(BYolo_GP0_awburst),
        .BYolo_GP0_awcache(BYolo_GP0_awcache),
        .BYolo_GP0_awid(BYolo_GP0_awid),
        .BYolo_GP0_awlen(BYolo_GP0_awlen),
        .BYolo_GP0_awlock(BYolo_GP0_awlock),
        .BYolo_GP0_awprot(BYolo_GP0_awprot),
        .BYolo_GP0_awqos(BYolo_GP0_awqos),
        .BYolo_GP0_awready(BYolo_GP0_awready),
        .BYolo_GP0_awsize(BYolo_GP0_awsize),
        .BYolo_GP0_awvalid(BYolo_GP0_awvalid),
        .BYolo_GP0_bid(BYolo_GP0_bid),
        .BYolo_GP0_bready(BYolo_GP0_bready),
        .BYolo_GP0_bresp(BYolo_GP0_bresp),
        .BYolo_GP0_bvalid(BYolo_GP0_bvalid),
        .BYolo_GP0_rdata(BYolo_GP0_rdata),
        .BYolo_GP0_rid(BYolo_GP0_rid),
        .BYolo_GP0_rlast(BYolo_GP0_rlast),
        .BYolo_GP0_rready(BYolo_GP0_rready),
        .BYolo_GP0_rresp(BYolo_GP0_rresp),
        .BYolo_GP0_rvalid(BYolo_GP0_rvalid),
        .BYolo_GP0_wdata(BYolo_GP0_wdata),
        .BYolo_GP0_wid(BYolo_GP0_wid),
        .BYolo_GP0_wlast(BYolo_GP0_wlast),
        .BYolo_GP0_wready(BYolo_GP0_wready),
        .BYolo_GP0_wstrb(BYolo_GP0_wstrb),
        .BYolo_GP0_wvalid(BYolo_GP0_wvalid),
        .BYolo_GP1_araddr(BYolo_GP1_araddr),
        .BYolo_GP1_arburst(BYolo_GP1_arburst),
        .BYolo_GP1_arcache(BYolo_GP1_arcache),
        .BYolo_GP1_arid(BYolo_GP1_arid),
        .BYolo_GP1_arlen(BYolo_GP1_arlen),
        .BYolo_GP1_arlock(BYolo_GP1_arlock),
        .BYolo_GP1_arprot(BYolo_GP1_arprot),
        .BYolo_GP1_arqos(BYolo_GP1_arqos),
        .BYolo_GP1_arready(BYolo_GP1_arready),
        .BYolo_GP1_arsize(BYolo_GP1_arsize),
        .BYolo_GP1_arvalid(BYolo_GP1_arvalid),
        .BYolo_GP1_awaddr(BYolo_GP1_awaddr),
        .BYolo_GP1_awburst(BYolo_GP1_awburst),
        .BYolo_GP1_awcache(BYolo_GP1_awcache),
        .BYolo_GP1_awid(BYolo_GP1_awid),
        .BYolo_GP1_awlen(BYolo_GP1_awlen),
        .BYolo_GP1_awlock(BYolo_GP1_awlock),
        .BYolo_GP1_awprot(BYolo_GP1_awprot),
        .BYolo_GP1_awqos(BYolo_GP1_awqos),
        .BYolo_GP1_awready(BYolo_GP1_awready),
        .BYolo_GP1_awsize(BYolo_GP1_awsize),
        .BYolo_GP1_awvalid(BYolo_GP1_awvalid),
        .BYolo_GP1_bid(BYolo_GP1_bid),
        .BYolo_GP1_bready(BYolo_GP1_bready),
        .BYolo_GP1_bresp(BYolo_GP1_bresp),
        .BYolo_GP1_bvalid(BYolo_GP1_bvalid),
        .BYolo_GP1_rdata(BYolo_GP1_rdata),
        .BYolo_GP1_rid(BYolo_GP1_rid),
        .BYolo_GP1_rlast(BYolo_GP1_rlast),
        .BYolo_GP1_rready(BYolo_GP1_rready),
        .BYolo_GP1_rresp(BYolo_GP1_rresp),
        .BYolo_GP1_rvalid(BYolo_GP1_rvalid),
        .BYolo_GP1_wdata(BYolo_GP1_wdata),
        .BYolo_GP1_wid(BYolo_GP1_wid),
        .BYolo_GP1_wlast(BYolo_GP1_wlast),
        .BYolo_GP1_wready(BYolo_GP1_wready),
        .BYolo_GP1_wstrb(BYolo_GP1_wstrb),
        .BYolo_GP1_wvalid(BYolo_GP1_wvalid),
        .DDR_0_addr(DDR_0_addr),
        .DDR_0_ba(DDR_0_ba),
        .DDR_0_cas_n(DDR_0_cas_n),
        .DDR_0_ck_n(DDR_0_ck_n),
        .DDR_0_ck_p(DDR_0_ck_p),
        .DDR_0_cke(DDR_0_cke),
        .DDR_0_cs_n(DDR_0_cs_n),
        .DDR_0_dm(DDR_0_dm),
        .DDR_0_dq(DDR_0_dq),
        .DDR_0_dqs_n(DDR_0_dqs_n),
        .DDR_0_dqs_p(DDR_0_dqs_p),
        .DDR_0_odt(DDR_0_odt),
        .DDR_0_ras_n(DDR_0_ras_n),
        .DDR_0_reset_n(DDR_0_reset_n),
        .DDR_0_we_n(DDR_0_we_n),
        .FCLK_CLK0_0(FCLK_CLK0_0),
        .FCLK_RESET0_N_0(FCLK_RESET0_N_0),
        .FIXED_IO_0_ddr_vrn(FIXED_IO_0_ddr_vrn),
        .FIXED_IO_0_ddr_vrp(FIXED_IO_0_ddr_vrp),
        .FIXED_IO_0_mio(FIXED_IO_0_mio),
        .FIXED_IO_0_ps_clk(FIXED_IO_0_ps_clk),
        .FIXED_IO_0_ps_porb(FIXED_IO_0_ps_porb),
        .FIXED_IO_0_ps_srstb(FIXED_IO_0_ps_srstb),
        .M_AI_HP_0_pl_araddr(M_AI_HP_0_pl_araddr),
        .M_AI_HP_0_pl_arinfo(M_AI_HP_0_pl_arinfo),
        .M_AI_HP_0_pl_arlast(M_AI_HP_0_pl_arlast),
        .M_AI_HP_0_pl_arready(M_AI_HP_0_pl_arready),
        .M_AI_HP_0_pl_arvalid(M_AI_HP_0_pl_arvalid),
        .M_AI_HP_0_pl_awaddr(M_AI_HP_0_pl_awaddr),
        .M_AI_HP_0_pl_awdata(M_AI_HP_0_pl_awdata),
        .M_AI_HP_0_pl_awen(M_AI_HP_0_pl_awen),
        .M_AI_HP_0_pl_awinfo(M_AI_HP_0_pl_awinfo),
        .M_AI_HP_0_pl_awlast(M_AI_HP_0_pl_awlast),
        .M_AI_HP_0_pl_awready(M_AI_HP_0_pl_awready),
        .M_AI_HP_0_pl_awvalid(M_AI_HP_0_pl_awvalid),
        .M_AI_HP_0_pl_bready(M_AI_HP_0_pl_bready),
        .M_AI_HP_0_pl_bvalid(M_AI_HP_0_pl_bvalid),
        .M_AI_HP_0_pl_rdata(M_AI_HP_0_pl_rdata),
        .M_AI_HP_0_pl_rlast(M_AI_HP_0_pl_rlast),
        .M_AI_HP_0_pl_rready(M_AI_HP_0_pl_rready),
        .M_AI_HP_0_pl_rvalid(M_AI_HP_0_pl_rvalid),
        .PJTAG_0_tck(PJTAG_0_tck),
        .PJTAG_0_tdi(PJTAG_0_tdi),
        .PJTAG_0_tdo(PJTAG_0_tdo),
        .PJTAG_0_tms(PJTAG_0_tms),
        .S_AI_GP_0_pl_ra_araddr(S_AI_GP_0_pl_ra_araddr),
        .S_AI_GP_0_pl_ra_arready(S_AI_GP_0_pl_ra_arready),
        .S_AI_GP_0_pl_ra_arvalid(S_AI_GP_0_pl_ra_arvalid),
        .S_AI_GP_0_pl_ra_awaddr(S_AI_GP_0_pl_ra_awaddr),
        .S_AI_GP_0_pl_ra_awdata(S_AI_GP_0_pl_ra_awdata),
        .S_AI_GP_0_pl_ra_awready(S_AI_GP_0_pl_ra_awready),
        .S_AI_GP_0_pl_ra_awvalid(S_AI_GP_0_pl_ra_awvalid),
        .S_AI_GP_0_pl_ra_rdata(S_AI_GP_0_pl_ra_rdata),
        .S_AI_GP_0_pl_ra_rready(S_AI_GP_0_pl_ra_rready),
        .S_AI_GP_0_pl_ra_rvalid(S_AI_GP_0_pl_ra_rvalid),
        .S_AXI_HP0_0_araddr(S_AXI_HP0_0_araddr),
        .S_AXI_HP0_0_arburst(S_AXI_HP0_0_arburst),
        .S_AXI_HP0_0_arcache(S_AXI_HP0_0_arcache),
        .S_AXI_HP0_0_arid(S_AXI_HP0_0_arid),
        .S_AXI_HP0_0_arlen(S_AXI_HP0_0_arlen),
        .S_AXI_HP0_0_arlock(S_AXI_HP0_0_arlock),
        .S_AXI_HP0_0_arprot(S_AXI_HP0_0_arprot),
        .S_AXI_HP0_0_arqos(S_AXI_HP0_0_arqos),
        .S_AXI_HP0_0_arready(S_AXI_HP0_0_arready),
        .S_AXI_HP0_0_arsize(S_AXI_HP0_0_arsize),
        .S_AXI_HP0_0_arvalid(S_AXI_HP0_0_arvalid),
        .S_AXI_HP0_0_awaddr(S_AXI_HP0_0_awaddr),
        .S_AXI_HP0_0_awburst(S_AXI_HP0_0_awburst),
        .S_AXI_HP0_0_awcache(S_AXI_HP0_0_awcache),
        .S_AXI_HP0_0_awid(S_AXI_HP0_0_awid),
        .S_AXI_HP0_0_awlen(S_AXI_HP0_0_awlen),
        .S_AXI_HP0_0_awlock(S_AXI_HP0_0_awlock),
        .S_AXI_HP0_0_awprot(S_AXI_HP0_0_awprot),
        .S_AXI_HP0_0_awqos(S_AXI_HP0_0_awqos),
        .S_AXI_HP0_0_awready(S_AXI_HP0_0_awready),
        .S_AXI_HP0_0_awsize(S_AXI_HP0_0_awsize),
        .S_AXI_HP0_0_awvalid(S_AXI_HP0_0_awvalid),
        .S_AXI_HP0_0_bid(S_AXI_HP0_0_bid),
        .S_AXI_HP0_0_bready(S_AXI_HP0_0_bready),
        .S_AXI_HP0_0_bresp(S_AXI_HP0_0_bresp),
        .S_AXI_HP0_0_bvalid(S_AXI_HP0_0_bvalid),
        .S_AXI_HP0_0_rdata(S_AXI_HP0_0_rdata),
        .S_AXI_HP0_0_rid(S_AXI_HP0_0_rid),
        .S_AXI_HP0_0_rlast(S_AXI_HP0_0_rlast),
        .S_AXI_HP0_0_rready(S_AXI_HP0_0_rready),
        .S_AXI_HP0_0_rresp(S_AXI_HP0_0_rresp),
        .S_AXI_HP0_0_rvalid(S_AXI_HP0_0_rvalid),
        .S_AXI_HP0_0_wdata(S_AXI_HP0_0_wdata),
        .S_AXI_HP0_0_wid(S_AXI_HP0_0_wid),
        .S_AXI_HP0_0_wlast(S_AXI_HP0_0_wlast),
        .S_AXI_HP0_0_wready(S_AXI_HP0_0_wready),
        .S_AXI_HP0_0_wstrb(S_AXI_HP0_0_wstrb),
        .S_AXI_HP0_0_wvalid(S_AXI_HP0_0_wvalid),
        .S_AXI_HP0_FIFO_CTRL_0_racount(S_AXI_HP0_FIFO_CTRL_0_racount),
        .S_AXI_HP0_FIFO_CTRL_0_rcount(S_AXI_HP0_FIFO_CTRL_0_rcount),
        .S_AXI_HP0_FIFO_CTRL_0_rdissuecapen(S_AXI_HP0_FIFO_CTRL_0_rdissuecapen),
        .S_AXI_HP0_FIFO_CTRL_0_wacount(S_AXI_HP0_FIFO_CTRL_0_wacount),
        .S_AXI_HP0_FIFO_CTRL_0_wcount(S_AXI_HP0_FIFO_CTRL_0_wcount),
        .S_AXI_HP0_FIFO_CTRL_0_wrissuecapen(S_AXI_HP0_FIFO_CTRL_0_wrissuecapen),
        .S_AXI_HP1_0_araddr(S_AXI_HP1_0_araddr),
        .S_AXI_HP1_0_arburst(S_AXI_HP1_0_arburst),
        .S_AXI_HP1_0_arcache(S_AXI_HP1_0_arcache),
        .S_AXI_HP1_0_arid(S_AXI_HP1_0_arid),
        .S_AXI_HP1_0_arlen(S_AXI_HP1_0_arlen),
        .S_AXI_HP1_0_arlock(S_AXI_HP1_0_arlock),
        .S_AXI_HP1_0_arprot(S_AXI_HP1_0_arprot),
        .S_AXI_HP1_0_arqos(S_AXI_HP1_0_arqos),
        .S_AXI_HP1_0_arready(S_AXI_HP1_0_arready),
        .S_AXI_HP1_0_arsize(S_AXI_HP1_0_arsize),
        .S_AXI_HP1_0_arvalid(S_AXI_HP1_0_arvalid),
        .S_AXI_HP1_0_awaddr(S_AXI_HP1_0_awaddr),
        .S_AXI_HP1_0_awburst(S_AXI_HP1_0_awburst),
        .S_AXI_HP1_0_awcache(S_AXI_HP1_0_awcache),
        .S_AXI_HP1_0_awid(S_AXI_HP1_0_awid),
        .S_AXI_HP1_0_awlen(S_AXI_HP1_0_awlen),
        .S_AXI_HP1_0_awlock(S_AXI_HP1_0_awlock),
        .S_AXI_HP1_0_awprot(S_AXI_HP1_0_awprot),
        .S_AXI_HP1_0_awqos(S_AXI_HP1_0_awqos),
        .S_AXI_HP1_0_awready(S_AXI_HP1_0_awready),
        .S_AXI_HP1_0_awsize(S_AXI_HP1_0_awsize),
        .S_AXI_HP1_0_awvalid(S_AXI_HP1_0_awvalid),
        .S_AXI_HP1_0_bid(S_AXI_HP1_0_bid),
        .S_AXI_HP1_0_bready(S_AXI_HP1_0_bready),
        .S_AXI_HP1_0_bresp(S_AXI_HP1_0_bresp),
        .S_AXI_HP1_0_bvalid(S_AXI_HP1_0_bvalid),
        .S_AXI_HP1_0_rdata(S_AXI_HP1_0_rdata),
        .S_AXI_HP1_0_rid(S_AXI_HP1_0_rid),
        .S_AXI_HP1_0_rlast(S_AXI_HP1_0_rlast),
        .S_AXI_HP1_0_rready(S_AXI_HP1_0_rready),
        .S_AXI_HP1_0_rresp(S_AXI_HP1_0_rresp),
        .S_AXI_HP1_0_rvalid(S_AXI_HP1_0_rvalid),
        .S_AXI_HP1_0_wdata(S_AXI_HP1_0_wdata),
        .S_AXI_HP1_0_wid(S_AXI_HP1_0_wid),
        .S_AXI_HP1_0_wlast(S_AXI_HP1_0_wlast),
        .S_AXI_HP1_0_wready(S_AXI_HP1_0_wready),
        .S_AXI_HP1_0_wstrb(S_AXI_HP1_0_wstrb),
        .S_AXI_HP1_0_wvalid(S_AXI_HP1_0_wvalid),
        .S_AXI_HP1_FIFO_CTRL_0_racount(S_AXI_HP1_FIFO_CTRL_0_racount),
        .S_AXI_HP1_FIFO_CTRL_0_rcount(S_AXI_HP1_FIFO_CTRL_0_rcount),
        .S_AXI_HP1_FIFO_CTRL_0_rdissuecapen(S_AXI_HP1_FIFO_CTRL_0_rdissuecapen),
        .S_AXI_HP1_FIFO_CTRL_0_wacount(S_AXI_HP1_FIFO_CTRL_0_wacount),
        .S_AXI_HP1_FIFO_CTRL_0_wcount(S_AXI_HP1_FIFO_CTRL_0_wcount),
        .S_AXI_HP1_FIFO_CTRL_0_wrissuecapen(S_AXI_HP1_FIFO_CTRL_0_wrissuecapen),
        .S_AXI_HP2_0_araddr(S_AXI_HP2_0_araddr),
        .S_AXI_HP2_0_arburst(S_AXI_HP2_0_arburst),
        .S_AXI_HP2_0_arcache(S_AXI_HP2_0_arcache),
        .S_AXI_HP2_0_arid(S_AXI_HP2_0_arid),
        .S_AXI_HP2_0_arlen(S_AXI_HP2_0_arlen),
        .S_AXI_HP2_0_arlock(S_AXI_HP2_0_arlock),
        .S_AXI_HP2_0_arprot(S_AXI_HP2_0_arprot),
        .S_AXI_HP2_0_arqos(S_AXI_HP2_0_arqos),
        .S_AXI_HP2_0_arready(S_AXI_HP2_0_arready),
        .S_AXI_HP2_0_arsize(S_AXI_HP2_0_arsize),
        .S_AXI_HP2_0_arvalid(S_AXI_HP2_0_arvalid),
        .S_AXI_HP2_0_awaddr(S_AXI_HP2_0_awaddr),
        .S_AXI_HP2_0_awburst(S_AXI_HP2_0_awburst),
        .S_AXI_HP2_0_awcache(S_AXI_HP2_0_awcache),
        .S_AXI_HP2_0_awid(S_AXI_HP2_0_awid),
        .S_AXI_HP2_0_awlen(S_AXI_HP2_0_awlen),
        .S_AXI_HP2_0_awlock(S_AXI_HP2_0_awlock),
        .S_AXI_HP2_0_awprot(S_AXI_HP2_0_awprot),
        .S_AXI_HP2_0_awqos(S_AXI_HP2_0_awqos),
        .S_AXI_HP2_0_awready(S_AXI_HP2_0_awready),
        .S_AXI_HP2_0_awsize(S_AXI_HP2_0_awsize),
        .S_AXI_HP2_0_awvalid(S_AXI_HP2_0_awvalid),
        .S_AXI_HP2_0_bid(S_AXI_HP2_0_bid),
        .S_AXI_HP2_0_bready(S_AXI_HP2_0_bready),
        .S_AXI_HP2_0_bresp(S_AXI_HP2_0_bresp),
        .S_AXI_HP2_0_bvalid(S_AXI_HP2_0_bvalid),
        .S_AXI_HP2_0_rdata(S_AXI_HP2_0_rdata),
        .S_AXI_HP2_0_rid(S_AXI_HP2_0_rid),
        .S_AXI_HP2_0_rlast(S_AXI_HP2_0_rlast),
        .S_AXI_HP2_0_rready(S_AXI_HP2_0_rready),
        .S_AXI_HP2_0_rresp(S_AXI_HP2_0_rresp),
        .S_AXI_HP2_0_rvalid(S_AXI_HP2_0_rvalid),
        .S_AXI_HP2_0_wdata(S_AXI_HP2_0_wdata),
        .S_AXI_HP2_0_wid(S_AXI_HP2_0_wid),
        .S_AXI_HP2_0_wlast(S_AXI_HP2_0_wlast),
        .S_AXI_HP2_0_wready(S_AXI_HP2_0_wready),
        .S_AXI_HP2_0_wstrb(S_AXI_HP2_0_wstrb),
        .S_AXI_HP2_0_wvalid(S_AXI_HP2_0_wvalid),
        .S_AXI_HP2_1_araddr(S_AXI_HP2_1_araddr),
        .S_AXI_HP2_1_arburst(S_AXI_HP2_1_arburst),
        .S_AXI_HP2_1_arcache(S_AXI_HP2_1_arcache),
        .S_AXI_HP2_1_arid(S_AXI_HP2_1_arid),
        .S_AXI_HP2_1_arlen(S_AXI_HP2_1_arlen),
        .S_AXI_HP2_1_arlock(S_AXI_HP2_1_arlock),
        .S_AXI_HP2_1_arprot(S_AXI_HP2_1_arprot),
        .S_AXI_HP2_1_arqos(S_AXI_HP2_1_arqos),
        .S_AXI_HP2_1_arready(S_AXI_HP2_1_arready),
        .S_AXI_HP2_1_arsize(S_AXI_HP2_1_arsize),
        .S_AXI_HP2_1_arvalid(S_AXI_HP2_1_arvalid),
        .S_AXI_HP2_1_awaddr(S_AXI_HP2_1_awaddr),
        .S_AXI_HP2_1_awburst(S_AXI_HP2_1_awburst),
        .S_AXI_HP2_1_awcache(S_AXI_HP2_1_awcache),
        .S_AXI_HP2_1_awid(S_AXI_HP2_1_awid),
        .S_AXI_HP2_1_awlen(S_AXI_HP2_1_awlen),
        .S_AXI_HP2_1_awlock(S_AXI_HP2_1_awlock),
        .S_AXI_HP2_1_awprot(S_AXI_HP2_1_awprot),
        .S_AXI_HP2_1_awqos(S_AXI_HP2_1_awqos),
        .S_AXI_HP2_1_awready(S_AXI_HP2_1_awready),
        .S_AXI_HP2_1_awsize(S_AXI_HP2_1_awsize),
        .S_AXI_HP2_1_awvalid(S_AXI_HP2_1_awvalid),
        .S_AXI_HP2_1_bid(S_AXI_HP2_1_bid),
        .S_AXI_HP2_1_bready(S_AXI_HP2_1_bready),
        .S_AXI_HP2_1_bresp(S_AXI_HP2_1_bresp),
        .S_AXI_HP2_1_bvalid(S_AXI_HP2_1_bvalid),
        .S_AXI_HP2_1_rdata(S_AXI_HP2_1_rdata),
        .S_AXI_HP2_1_rid(S_AXI_HP2_1_rid),
        .S_AXI_HP2_1_rlast(S_AXI_HP2_1_rlast),
        .S_AXI_HP2_1_rready(S_AXI_HP2_1_rready),
        .S_AXI_HP2_1_rresp(S_AXI_HP2_1_rresp),
        .S_AXI_HP2_1_rvalid(S_AXI_HP2_1_rvalid),
        .S_AXI_HP2_1_wdata(S_AXI_HP2_1_wdata),
        .S_AXI_HP2_1_wid(S_AXI_HP2_1_wid),
        .S_AXI_HP2_1_wlast(S_AXI_HP2_1_wlast),
        .S_AXI_HP2_1_wready(S_AXI_HP2_1_wready),
        .S_AXI_HP2_1_wstrb(S_AXI_HP2_1_wstrb),
        .S_AXI_HP2_1_wvalid(S_AXI_HP2_1_wvalid),
        .S_AXI_HP2_FIFO_CTRL_0_racount(S_AXI_HP2_FIFO_CTRL_0_racount),
        .S_AXI_HP2_FIFO_CTRL_0_rcount(S_AXI_HP2_FIFO_CTRL_0_rcount),
        .S_AXI_HP2_FIFO_CTRL_0_rdissuecapen(S_AXI_HP2_FIFO_CTRL_0_rdissuecapen),
        .S_AXI_HP2_FIFO_CTRL_0_wacount(S_AXI_HP2_FIFO_CTRL_0_wacount),
        .S_AXI_HP2_FIFO_CTRL_0_wcount(S_AXI_HP2_FIFO_CTRL_0_wcount),
        .S_AXI_HP2_FIFO_CTRL_0_wrissuecapen(S_AXI_HP2_FIFO_CTRL_0_wrissuecapen),
        .S_AXI_HP3_0_araddr(S_AXI_HP3_0_araddr),
        .S_AXI_HP3_0_arburst(S_AXI_HP3_0_arburst),
        .S_AXI_HP3_0_arcache(S_AXI_HP3_0_arcache),
        .S_AXI_HP3_0_arid(S_AXI_HP3_0_arid),
        .S_AXI_HP3_0_arlen(S_AXI_HP3_0_arlen),
        .S_AXI_HP3_0_arlock(S_AXI_HP3_0_arlock),
        .S_AXI_HP3_0_arprot(S_AXI_HP3_0_arprot),
        .S_AXI_HP3_0_arqos(S_AXI_HP3_0_arqos),
        .S_AXI_HP3_0_arready(S_AXI_HP3_0_arready),
        .S_AXI_HP3_0_arsize(S_AXI_HP3_0_arsize),
        .S_AXI_HP3_0_arvalid(S_AXI_HP3_0_arvalid),
        .S_AXI_HP3_0_awaddr(S_AXI_HP3_0_awaddr),
        .S_AXI_HP3_0_awburst(S_AXI_HP3_0_awburst),
        .S_AXI_HP3_0_awcache(S_AXI_HP3_0_awcache),
        .S_AXI_HP3_0_awid(S_AXI_HP3_0_awid),
        .S_AXI_HP3_0_awlen(S_AXI_HP3_0_awlen),
        .S_AXI_HP3_0_awlock(S_AXI_HP3_0_awlock),
        .S_AXI_HP3_0_awprot(S_AXI_HP3_0_awprot),
        .S_AXI_HP3_0_awqos(S_AXI_HP3_0_awqos),
        .S_AXI_HP3_0_awready(S_AXI_HP3_0_awready),
        .S_AXI_HP3_0_awsize(S_AXI_HP3_0_awsize),
        .S_AXI_HP3_0_awvalid(S_AXI_HP3_0_awvalid),
        .S_AXI_HP3_0_bid(S_AXI_HP3_0_bid),
        .S_AXI_HP3_0_bready(S_AXI_HP3_0_bready),
        .S_AXI_HP3_0_bresp(S_AXI_HP3_0_bresp),
        .S_AXI_HP3_0_bvalid(S_AXI_HP3_0_bvalid),
        .S_AXI_HP3_0_rdata(S_AXI_HP3_0_rdata),
        .S_AXI_HP3_0_rid(S_AXI_HP3_0_rid),
        .S_AXI_HP3_0_rlast(S_AXI_HP3_0_rlast),
        .S_AXI_HP3_0_rready(S_AXI_HP3_0_rready),
        .S_AXI_HP3_0_rresp(S_AXI_HP3_0_rresp),
        .S_AXI_HP3_0_rvalid(S_AXI_HP3_0_rvalid),
        .S_AXI_HP3_0_wdata(S_AXI_HP3_0_wdata),
        .S_AXI_HP3_0_wid(S_AXI_HP3_0_wid),
        .S_AXI_HP3_0_wlast(S_AXI_HP3_0_wlast),
        .S_AXI_HP3_0_wready(S_AXI_HP3_0_wready),
        .S_AXI_HP3_0_wstrb(S_AXI_HP3_0_wstrb),
        .S_AXI_HP3_0_wvalid(S_AXI_HP3_0_wvalid),
        .S_AXI_HP3_FIFO_CTRL_0_racount(S_AXI_HP3_FIFO_CTRL_0_racount),
        .S_AXI_HP3_FIFO_CTRL_0_rcount(S_AXI_HP3_FIFO_CTRL_0_rcount),
        .S_AXI_HP3_FIFO_CTRL_0_rdissuecapen(S_AXI_HP3_FIFO_CTRL_0_rdissuecapen),
        .S_AXI_HP3_FIFO_CTRL_0_wacount(S_AXI_HP3_FIFO_CTRL_0_wacount),
        .S_AXI_HP3_FIFO_CTRL_0_wcount(S_AXI_HP3_FIFO_CTRL_0_wcount),
        .S_AXI_HP3_FIFO_CTRL_0_wrissuecapen(S_AXI_HP3_FIFO_CTRL_0_wrissuecapen),
        .USBIND_0_0_port_indctl(USBIND_0_0_port_indctl),
        .USBIND_0_0_vbus_pwrfault(USBIND_0_0_vbus_pwrfault),
        .USBIND_0_0_vbus_pwrselect(USBIND_0_0_vbus_pwrselect),
        .User_GP0_araddr(User_GP0_araddr),
        .User_GP0_arburst(User_GP0_arburst),
        .User_GP0_arcache(User_GP0_arcache),
        .User_GP0_arid(User_GP0_arid),
        .User_GP0_arlen(User_GP0_arlen),
        .User_GP0_arlock(User_GP0_arlock),
        .User_GP0_arprot(User_GP0_arprot),
        .User_GP0_arqos(User_GP0_arqos),
        .User_GP0_arready(User_GP0_arready),
        .User_GP0_arsize(User_GP0_arsize),
        .User_GP0_arvalid(User_GP0_arvalid),
        .User_GP0_awaddr(User_GP0_awaddr),
        .User_GP0_awburst(User_GP0_awburst),
        .User_GP0_awcache(User_GP0_awcache),
        .User_GP0_awid(User_GP0_awid),
        .User_GP0_awlen(User_GP0_awlen),
        .User_GP0_awlock(User_GP0_awlock),
        .User_GP0_awprot(User_GP0_awprot),
        .User_GP0_awqos(User_GP0_awqos),
        .User_GP0_awready(User_GP0_awready),
        .User_GP0_awsize(User_GP0_awsize),
        .User_GP0_awvalid(User_GP0_awvalid),
        .User_GP0_bid(User_GP0_bid),
        .User_GP0_bready(User_GP0_bready),
        .User_GP0_bresp(User_GP0_bresp),
        .User_GP0_bvalid(User_GP0_bvalid),
        .User_GP0_rdata(User_GP0_rdata),
        .User_GP0_rid(User_GP0_rid),
        .User_GP0_rlast(User_GP0_rlast),
        .User_GP0_rready(User_GP0_rready),
        .User_GP0_rresp(User_GP0_rresp),
        .User_GP0_rvalid(User_GP0_rvalid),
        .User_GP0_wdata(User_GP0_wdata),
        .User_GP0_wid(User_GP0_wid),
        .User_GP0_wlast(User_GP0_wlast),
        .User_GP0_wready(User_GP0_wready),
        .User_GP0_wstrb(User_GP0_wstrb),
        .User_GP0_wvalid(User_GP0_wvalid),
        .User_GP1_araddr(User_GP1_araddr),
        .User_GP1_arburst(User_GP1_arburst),
        .User_GP1_arcache(User_GP1_arcache),
        .User_GP1_arid(User_GP1_arid),
        .User_GP1_arlen(User_GP1_arlen),
        .User_GP1_arlock(User_GP1_arlock),
        .User_GP1_arprot(User_GP1_arprot),
        .User_GP1_arqos(User_GP1_arqos),
        .User_GP1_arready(User_GP1_arready),
        .User_GP1_arsize(User_GP1_arsize),
        .User_GP1_arvalid(User_GP1_arvalid),
        .User_GP1_awaddr(User_GP1_awaddr),
        .User_GP1_awburst(User_GP1_awburst),
        .User_GP1_awcache(User_GP1_awcache),
        .User_GP1_awid(User_GP1_awid),
        .User_GP1_awlen(User_GP1_awlen),
        .User_GP1_awlock(User_GP1_awlock),
        .User_GP1_awprot(User_GP1_awprot),
        .User_GP1_awqos(User_GP1_awqos),
        .User_GP1_awready(User_GP1_awready),
        .User_GP1_awsize(User_GP1_awsize),
        .User_GP1_awvalid(User_GP1_awvalid),
        .User_GP1_bid(User_GP1_bid),
        .User_GP1_bready(User_GP1_bready),
        .User_GP1_bresp(User_GP1_bresp),
        .User_GP1_bvalid(User_GP1_bvalid),
        .User_GP1_rdata(User_GP1_rdata),
        .User_GP1_rid(User_GP1_rid),
        .User_GP1_rlast(User_GP1_rlast),
        .User_GP1_rready(User_GP1_rready),
        .User_GP1_rresp(User_GP1_rresp),
        .User_GP1_rvalid(User_GP1_rvalid),
        .User_GP1_wdata(User_GP1_wdata),
        .User_GP1_wid(User_GP1_wid),
        .User_GP1_wlast(User_GP1_wlast),
        .User_GP1_wready(User_GP1_wready),
        .User_GP1_wstrb(User_GP1_wstrb),
        .User_GP1_wvalid(User_GP1_wvalid),
        .ai_irq(ai_irq),
        .customop_irq(customop_irq),
        .gp_axi_aclk(gp_axi_aclk),
        .hp_axi_aclk(hp_axi_aclk),
        .pl_bist_clk_0(pl_bist_clk_0),
        .pl_bist_rstn_0(pl_bist_rstn_0),
        .pl_clk_div_out_0(pl_clk_div_out_0),
        .pl_clk_en_b_0(pl_clk_en_b_0),
        .pl_itf_clk_0(pl_itf_clk_0),
        .pl_ra_clk_0(pl_ra_clk_0),
        .pl_rst_n_0(pl_rst_n_0),
        .pl_scan_clk_0(pl_scan_clk_0),
        .pl_scan_rst_n_0(pl_scan_rst_n_0),
        .reset_n(reset_n),
        .soft_rst_n(soft_rst_n),
        .test_irq(test_irq));
endmodule
