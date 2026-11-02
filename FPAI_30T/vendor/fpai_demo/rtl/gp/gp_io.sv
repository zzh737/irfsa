//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : gp_io
// Author        : Xu Yun
// Project       : NB2240
// Create Date   : 2022.11.23
// Description   :
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
//==============================================================================

module gp_io(
    // GP
    input                            M_AXI_GP_ARVALID           ,         
    input                            M_AXI_GP_AWVALID           ,         
    input                            M_AXI_GP_BREADY            ,         
    input                            M_AXI_GP_RREADY            ,         
    input                            M_AXI_GP_WLAST             ,         
    input                            M_AXI_GP_WVALID            ,         
    input    [11 : 0 ]               M_AXI_GP_ARID              ,
    input    [11 : 0 ]               M_AXI_GP_AWID              ,
    input    [11 : 0 ]               M_AXI_GP_WID               ,
    input    [1 : 0  ]               M_AXI_GP_ARBURST           , 
    input    [1 : 0  ]               M_AXI_GP_ARLOCK            , 
    input    [2 : 0  ]               M_AXI_GP_ARSIZE            , 
    input    [1 : 0  ]               M_AXI_GP_AWBURST           , 
    input    [1 : 0  ]               M_AXI_GP_AWLOCK            , 
    input    [2 : 0  ]               M_AXI_GP_AWSIZE            , 
    input    [2 : 0  ]               M_AXI_GP_ARPROT            , 
    input    [2 : 0  ]               M_AXI_GP_AWPROT            , 
    input    [31 : 0 ]               M_AXI_GP_ARADDR            ,
    input    [31 : 0 ]               M_AXI_GP_AWADDR            ,
    input    [31 : 0 ]               M_AXI_GP_WDATA             ,
    input    [3 : 0  ]               M_AXI_GP_ARCACHE           , 
    input    [3 : 0  ]               M_AXI_GP_ARLEN             , 
    input    [3 : 0  ]               M_AXI_GP_ARQOS             , 
    input    [3 : 0  ]               M_AXI_GP_AWCACHE           , 
    input    [3 : 0  ]               M_AXI_GP_AWLEN             , 
    input    [3 : 0  ]               M_AXI_GP_AWQOS             , 
    input    [3 : 0  ]               M_AXI_GP_WSTRB             , 
    output                           M_AXI_GP_ACLK              ,          
    output                           M_AXI_GP_ARREADY           ,          
    output                           M_AXI_GP_AWREADY           ,          
    output                           M_AXI_GP_BVALID            ,          
    output                           M_AXI_GP_RLAST             ,          
    output                           M_AXI_GP_RVALID            ,          
    output                           M_AXI_GP_WREADY            ,          
    output   [11 : 0 ]               M_AXI_GP_BID               , 
    output   [11 : 0 ]               M_AXI_GP_RID               , 
    output   [1 : 0  ]               M_AXI_GP_BRESP             ,  
    output   [1 : 0  ]               M_AXI_GP_RRESP             ,  
    output   [31 : 0 ]               M_AXI_GP_RDATA             ,

    // gp
    mna_gp_ww_itf.master             gp                         ,

    // clk & rst          
    input                            gp_clk_rst                 ,
    input                            gp_clk                     
);          
    //------------ GP IO ------------
    mna_gp_std_itf       gp_std()         ;

   // ************************************************************************************
   //   PS-PL IO : GP  
   // ************************************************************************************
    assign M_AXI_GP_ACLK = gp_clk;

    axi_to_mna #(.IDW(12), .DW(32), .AW(32)) axi_to_mna_u0(
        .m_mna_araddr      (gp_std.araddr    ),
        .m_mna_arvalid     (gp_std.arvalid   ),
        .m_mna_arready     (gp_std.arready   ),
        .m_mna_rdata       (gp_std.rdata     ),
        .m_mna_rvalid      (gp_std.rvalid    ),
        .m_mna_rready      (gp_std.rready    ),
        .m_mna_awaddr      (gp_std.awaddr    ),
        .m_mna_awvalid     (gp_std.awvalid   ),
        .m_mna_awready     (gp_std.awready   ),
        .m_mna_wdata       (gp_std.wdata     ),
        .m_mna_wvalid      (gp_std.wvalid    ),
        .m_mna_wready      (gp_std.wready    ),

        .s_axi_araddr      (M_AXI_GP_ARADDR  ),
        .s_axi_arburst     (M_AXI_GP_ARBURST ),
        .s_axi_arcache     (M_AXI_GP_ARCACHE ),
        .s_axi_arid        (M_AXI_GP_ARID    ),
        .s_axi_arlen       (M_AXI_GP_ARLEN   ),
        .s_axi_arlock      (M_AXI_GP_ARLOCK  ),
        .s_axi_arprot      (M_AXI_GP_ARPROT  ),
        .s_axi_arqos       (M_AXI_GP_ARQOS   ),
        .s_axi_arready     (M_AXI_GP_ARREADY ),
        .s_axi_arsize      (M_AXI_GP_ARSIZE  ),
        .s_axi_arvalid     (M_AXI_GP_ARVALID ),
        .s_axi_awaddr      (M_AXI_GP_AWADDR  ),
        .s_axi_awburst     (M_AXI_GP_AWBURST ),
        .s_axi_awcache     (M_AXI_GP_AWCACHE ),
        .s_axi_awid        (M_AXI_GP_AWID    ),
        .s_axi_awlen       (M_AXI_GP_AWLEN   ),
        .s_axi_awlock      (M_AXI_GP_AWLOCK  ),
        .s_axi_awprot      (M_AXI_GP_AWPROT  ),
        .s_axi_awqos       (M_AXI_GP_AWQOS   ),
        .s_axi_awready     (M_AXI_GP_AWREADY ),
        .s_axi_awsize      (M_AXI_GP_AWSIZE  ),
        .s_axi_awvalid     (M_AXI_GP_AWVALID ),
        .s_axi_bid         (M_AXI_GP_BID     ),
        .s_axi_bready      (M_AXI_GP_BREADY  ),
        .s_axi_bresp       (M_AXI_GP_BRESP   ),
        .s_axi_bvalid      (M_AXI_GP_BVALID  ),
        .s_axi_rdata       (M_AXI_GP_RDATA   ),
        .s_axi_rid         (M_AXI_GP_RID     ),
        .s_axi_rlast       (M_AXI_GP_RLAST   ),
        .s_axi_rready      (M_AXI_GP_RREADY  ),
        .s_axi_rresp       (M_AXI_GP_RRESP   ),
        .s_axi_rvalid      (M_AXI_GP_RVALID  ),
        .s_axi_wdata       (M_AXI_GP_WDATA   ),
        .s_axi_wid         (M_AXI_GP_WID     ),
        .s_axi_wlast       (M_AXI_GP_WLAST   ),
        .s_axi_wready      (M_AXI_GP_WREADY  ),
        .s_axi_wstrb       (M_AXI_GP_WSTRB   ),
        .s_axi_wvalid      (M_AXI_GP_WVALID  ),

        .s_axi_clk_rst     (gp_clk_rst       ),
        .s_axi_clk         (gp_clk           )
    );

    gpx_std2ww gpx_std2ww_u0(
            .std_gpx  (gp_std.slave ) ,    
            .ww_gpx   (gp           ) ,
            .gpx_rst  (gp_clk_rst   ) ,
            .gpx_clk  (gp_clk       )
    );

endmodule    