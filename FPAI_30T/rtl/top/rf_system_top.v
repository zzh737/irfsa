//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : rf_system_top.v (derived from vendor ai7030_edif_top.v)
// Author        : 
// Project       : 
// Create Date   : 
// Description   :
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
//=============================================================================

module rf_system_top (
  // PS
  inout     [53 : 0]     FIXED_IO_0_mio            ,
  inout     [14 : 0]     DDR_0_addr                , 
  inout     [2  : 0]     DDR_0_ba                  , 
  inout                  DDR_0_cas_n               , 
  inout                  DDR_0_ck_n                , 
  inout                  DDR_0_ck_p                , 
  inout                  DDR_0_cke                 , 
  inout                  DDR_0_cs_n                , 
  inout     [3  : 0]     DDR_0_dm                  , 
  inout     [31 : 0]     DDR_0_dq                  , 
  inout     [3  : 0]     DDR_0_dqs_n               , 
  inout     [3  : 0]     DDR_0_dqs_p               , 
  inout                  DDR_0_odt                 , 
  inout                  DDR_0_ras_n               , 
  inout                  DDR_0_reset_n             , 
  inout                  DDR_0_we_n                , 
  inout                  FIXED_IO_0_ddr_vrn        , 
  inout                  FIXED_IO_0_ddr_vrp        , 
  inout                  FIXED_IO_0_ps_clk         ,
  inout                  FIXED_IO_0_ps_porb        ,
  inout                  FIXED_IO_0_ps_srstb       ,
         
  // PL DDR       
  inout     [ 63 : 0]    ddr3_dq                   ,
  inout     [  7 : 0]    ddr3_dqs_n                ,
  inout     [  7 : 0]    ddr3_dqs_p                ,
  output    [  7 : 0]    ddr3_dm                   ,
  output    [ 14 : 0]    ddr3_addr                 ,
  output    [  2 : 0]    ddr3_ba                   ,
  output                 ddr3_ras_n                ,
  output                 ddr3_cas_n                ,
  output                 ddr3_we_n                 ,
  output                 ddr3_reset_n              ,
  output    [  0 : 0]    ddr3_ck_p                 ,
  output    [  0 : 0]    ddr3_ck_n                 ,
  output    [  0 : 0]    ddr3_cke                  ,
  output    [  0 : 0]    ddr3_cs_n                 ,
  output    [  0 : 0]    ddr3_odt                  ,
       
  input                  sys_rst                   ,
  input                  sys_clk_p                 ,
  input                  sys_clk_n                 ,

  output                 HDMI_CLK_P                ,    
  output                 HDMI_CLK_N                , 
  output [2:0]           HDMI_TX_P                 , 
  output [2:0]           HDMI_TX_N                 ,      
 
  output    [  1 : 0]    led                       ,
  output                 PS_PHY_RESET_N            ,

  input                  PJTAG_TCK                 ,
  input                  PJTAG_TMS                 ,
  input                  PJTAG_TDI                 ,
  output                 PJTAG_TDO                 
);

  // User CustomOp REG BUS
  wire   [ 31 : 0]  User_Reg_awwaddr        ;
  wire   [ 31 : 0]  User_Reg_awwdata        ;
  wire              User_Reg_awwvalid       ;
  wire              User_Reg_awwready       ;
  wire   [ 31 : 0]  User_Reg_araddr         ;
  wire              User_Reg_arvalid        ;
  wire              User_Reg_arready        ;
  wire   [ 31 : 0]  User_Reg_rdata          ;
  wire              User_Reg_rvalid         ;
  wire              User_Reg_rready         ;

  //User CustomOp DATA BUS
  wire   [ 31 : 0]  User_Ddr_awwaddr  ;
  wire   [511 : 0]  User_Ddr_awwdata  ;
  wire   [ 71 : 0]  User_Ddr_awwinfo  ; //{1'b0,pl_awen[63:0],pl_awinfo[5:0],pl_awlast[0]}
  wire              User_Ddr_awwvalid ;
  wire              User_Ddr_awwready ;
  wire   [ 31 : 0]  User_Ddr_araddr   ;
  wire              User_Ddr_arvalid  ;
  wire   [ 31 : 0]  User_Ddr_arinfo   ;  //{25'h0,pl_arinfo,pl_arlast}
  wire              User_Ddr_arready  ;
  wire   [511 : 0]  User_Ddr_rdata    ;
  wire              User_Ddr_rvalid   ;
  wire   [ 31 : 0]  User_Ddr_rinfo    ;  //{25'h0,pl_rinfo,pl_rlast}
  wire              User_Ddr_rready   ;
  wire              gp_clk            ;
  wire              hp_clk            ;
  wire              gp_clk_rst        ;
  wire              hp_clk_rst        ;
  ethernet_phy_reset u_ps_phy_reset(
    .clk(gp_clk), .arst(sys_rst | gp_clk_rst), .reset_n(PS_PHY_RESET_N)
  );
rf_platform U0_ps_ai_peripheral(
  .FIXED_IO_0_mio         ( FIXED_IO_0_mio      ),
  .DDR_0_addr             ( DDR_0_addr          ), 
  .DDR_0_ba               ( DDR_0_ba            ), 
  .DDR_0_cas_n            ( DDR_0_cas_n         ), 
  .DDR_0_ck_n             ( DDR_0_ck_n          ), 
  .DDR_0_ck_p             ( DDR_0_ck_p          ), 
  .DDR_0_cke              ( DDR_0_cke           ), 
  .DDR_0_cs_n             ( DDR_0_cs_n          ), 
  .DDR_0_dm               ( DDR_0_dm            ), 
  .DDR_0_dq               ( DDR_0_dq            ), 
  .DDR_0_dqs_n            ( DDR_0_dqs_n         ), 
  .DDR_0_dqs_p            ( DDR_0_dqs_p         ), 
  .DDR_0_odt              ( DDR_0_odt           ), 
  .DDR_0_ras_n            ( DDR_0_ras_n         ), 
  .DDR_0_reset_n          ( DDR_0_reset_n       ), 
  .DDR_0_we_n             ( DDR_0_we_n          ), 
  .FIXED_IO_0_ddr_vrn     ( FIXED_IO_0_ddr_vrn  ), 
  .FIXED_IO_0_ddr_vrp     ( FIXED_IO_0_ddr_vrp  ), 
  .FIXED_IO_0_ps_clk      ( FIXED_IO_0_ps_clk   ),
  .FIXED_IO_0_ps_porb     ( FIXED_IO_0_ps_porb  ),
  .FIXED_IO_0_ps_srstb    ( FIXED_IO_0_ps_srstb ),

  .ddr3_dq                ( ddr3_dq            ),
  .ddr3_dqs_n             ( ddr3_dqs_n         ),
  .ddr3_dqs_p             ( ddr3_dqs_p         ),
  .ddr3_dm                ( ddr3_dm            ),
  .ddr3_addr              ( ddr3_addr          ),
  .ddr3_ba                ( ddr3_ba            ),
  .ddr3_ras_n             ( ddr3_ras_n         ),
  .ddr3_cas_n             ( ddr3_cas_n         ),
  .ddr3_we_n              ( ddr3_we_n          ),
  .ddr3_reset_n           ( ddr3_reset_n       ),
  .ddr3_ck_p              ( ddr3_ck_p          ),
  .ddr3_ck_n              ( ddr3_ck_n          ),
  .ddr3_cke               ( ddr3_cke           ),
  .ddr3_cs_n              ( ddr3_cs_n          ),
  .ddr3_odt               ( ddr3_odt           ),
       
  .sys_rst                ( sys_rst            ),
  .sys_clk_p              ( sys_clk_p          ),
  .sys_clk_n              ( sys_clk_n          ),

  .led                    ( led                ),  // ouput
  .PJTAG_TCK              ( PJTAG_TCK          ),
  .PJTAG_TMS              ( PJTAG_TMS          ),
  .PJTAG_TDI              ( PJTAG_TDI          ),
  .PJTAG_TDO              ( PJTAG_TDO          ),

  .gp_clk                 ( gp_clk             ),
  .hp_clk                 ( hp_clk             ),
  .gp_clk_rst             ( gp_clk_rst         ),
  .hp_clk_rst             ( hp_clk_rst         ),

  .User_Reg_awwaddr       ( User_Reg_awwaddr   ),
  .User_Reg_awwdata       ( User_Reg_awwdata   ),
  .User_Reg_awwvalid      ( User_Reg_awwvalid  ),
  .User_Reg_awwready      ( User_Reg_awwready  ),
  .User_Reg_araddr        ( User_Reg_araddr    ),
  .User_Reg_arvalid       ( User_Reg_arvalid   ),
  .User_Reg_arready       ( User_Reg_arready   ),
  .User_Reg_rdata         ( User_Reg_rdata     ),
  .User_Reg_rvalid        ( User_Reg_rvalid    ),
  .User_Reg_rready        ( User_Reg_rready    ),

  .User_Ddr_awwaddr       ( User_Ddr_awwaddr   ),
  .User_Ddr_awwdata       ( User_Ddr_awwdata   ),
  .User_Ddr_awwinfo       ( User_Ddr_awwinfo   ),  //{1'b0,pl_awen[63:0],pl_awinfo[5:0],pl_awlast[0]}
  .User_Ddr_awwvalid      ( User_Ddr_awwvalid  ),
  .User_Ddr_awwready      ( User_Ddr_awwready  ),
  .User_Ddr_araddr        ( User_Ddr_araddr    ),
  .User_Ddr_arvalid       ( User_Ddr_arvalid   ),
  .User_Ddr_arinfo        ( User_Ddr_arinfo    ),  //{25'h0,pl_arinfo,pl_arlast}
  .User_Ddr_arready       ( User_Ddr_arready   ),
  .User_Ddr_rdata         ( User_Ddr_rdata     ),
  .User_Ddr_rvalid        ( User_Ddr_rvalid    ),
  .User_Ddr_rinfo         ( User_Ddr_rinfo     ),  //{25'h0,pl_rinfo,pl_rlast}
  .User_Ddr_rready        ( User_Ddr_rready    ) 
);





// Product-specific Custom Op replaces the incompatible old adder registers.
wire video_pix,video_serial,video_lock,video_rst,video_de,video_hs,video_vs;
wire render_de,render_hs,render_vs;
wire [11:0] video_x,video_y;
wire [23:0] video_rgb;
rf_product_core U_product(
 .gp_clk(gp_clk),.gp_rst(gp_clk_rst),.hp_clk(hp_clk),.hp_rst(hp_clk_rst),
 .reg_awaddr(User_Reg_awwaddr),.reg_wdata(User_Reg_awwdata),
 .reg_wvalid(User_Reg_awwvalid),.reg_wready(User_Reg_awwready),
 .reg_araddr(User_Reg_araddr),.reg_arvalid(User_Reg_arvalid),.reg_arready(User_Reg_arready),
 .reg_rdata(User_Reg_rdata),.reg_rvalid(User_Reg_rvalid),.reg_rready(User_Reg_rready),
 .ddr_awaddr(User_Ddr_awwaddr),.ddr_wdata(User_Ddr_awwdata),.ddr_winfo(User_Ddr_awwinfo),
 .ddr_wvalid(User_Ddr_awwvalid),.ddr_wready(User_Ddr_awwready),
 .ddr_araddr(User_Ddr_araddr),.ddr_arinfo(User_Ddr_arinfo),
 .ddr_arvalid(User_Ddr_arvalid),.ddr_arready(User_Ddr_arready),
 .ddr_rdata(User_Ddr_rdata),.ddr_rvalid(User_Ddr_rvalid),.ddr_rready(User_Ddr_rready),
 .pix_clk(video_pix),.pix_rst(video_rst),.x(video_x),.y(video_y),
 .de(video_de),.hs(video_hs),.vs(video_vs),
 .video_de(render_de),.video_hs(render_hs),.video_vs(render_vs),.video_rgb(video_rgb));

// Reuse gp_clk (100 MHz) so the board 200 MHz differential input has ONE buffer,
// inside the vendor MIG. Do not instantiate a second IBUFDS on the same pins.
video_clock_core #(.INPUT_PERIOD(10.0),.INPUT_DIV(5)) video_clocks(
 gp_clk,gp_clk_rst,video_pix,video_serial,video_lock);
// Keep the board-validated sampled reset; do not drive asynchronous presets
// from the GP clock domain in the product video domain.
reset_sync #(.SYNCHRONOUS(2)) video_reset(video_pix,gp_clk_rst|!video_lock,video_rst);
video_timing video_scan(video_pix,video_rst,video_x,video_y,video_de,video_hs,video_vs);
hdmi_tx video_output(video_pix,video_serial,video_rst,render_de,render_hs,render_vs,video_rgb,
 HDMI_CLK_P,HDMI_CLK_N,HDMI_TX_P,HDMI_TX_N);
endmodule
