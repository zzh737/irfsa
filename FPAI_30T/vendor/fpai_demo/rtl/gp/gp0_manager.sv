//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : gp0_manager.v
// Author        : zhaoxiaodong
// Project       :
// Create Date   : 2020.02.07
// Description   : 
//
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
// 1.01    2022.7.3     xuyun        modify ASP, Add ERR
// 1.02    2022.7.25    luowei       parameter base
//==============================================================================

module gp0_manager #(parameter GP0_BASE=32'h40000000)(
    mna_gp_ww_itf.slave       gpx                ,    
    mna_gp_ww_itf.master      host_ctrl          ,
    mna_gp_ww_itf.master      ai_ra              ,
    mna_gp_ww_itf.master      m2_gpx             ,
    mna_gp_ww_itf.master      m3_gpx             ,

    input                     gpx_rst            ,
    input                     gpx_clk
);
localparam GP0_SPLIT_BASE = GP0_BASE | 32'h00080000;

mna_gp_ww_itf m00_gpx();
mna_gp_ww_itf m04_gpx();
//mna_gp_ww_itf m6_gpx();

/*

                                          GP0_BASE(default:0x4000_0000)
                                              gpx
                              _________________|_________________     
                             /                                   \                         
*512*                  0x4000_0000                          0x4008_0000
                        m00_gpx                               m04_gpx
                  __________|__________                 __________|__________                              
                 /                     \               /                     \                       
*256*       0x4000_0000            0x4004_0000    0x4008_0000           0x400c_0000  
                 |                      |              |                      |
             host_ctrl               ai_ra         m2_gpx                 m6_gpx   
              
*/

gpx_ww_split #(.BASE(GP0_BASE),.ASP(19), .ERR(32'hB0AAAAAA)) gpx_ww_split_u0(
        .gpx     (gpx             )  ,    
        .m00_gpx (m00_gpx.master  )  ,
        .m01_gpx (m04_gpx.master  )  ,
        .gpx_rst (gpx_rst         )  ,
        .gpx_clk (gpx_clk         )
);


gpx_ww_split #(.BASE(GP0_BASE),.ASP(18),.ERR(32'hB0BBBBBB)) gpx_ww_split_u1(
        .gpx     (m00_gpx.slave   )  ,    
        .m00_gpx (host_ctrl       )  ,
        .m01_gpx (ai_ra           )  ,
        .gpx_rst (gpx_rst         )  ,
        .gpx_clk (gpx_clk         )
);

gpx_ww_split #(.BASE(GP0_SPLIT_BASE),.ASP(18),.ERR(32'hB0CCCCCC)) gpx_ww_split_u2(
        .gpx     (m04_gpx.slave   )  ,    
        .m00_gpx (m2_gpx          )  ,
        .m01_gpx (m3_gpx          )  ,
        .gpx_rst (gpx_rst         )  ,
        .gpx_clk (gpx_clk         )
);

//gpx_RFU  #(.ERR(32'hB0DDDDDD)) gpx_RFU_u2(
//        .gpx     (m2_gpx.slave    )  ,    
//        .gpx_rst (gpx_rst         )  ,
//        .gpx_clk (gpx_clk         )
//);
//
//gpx_RFU  #(.ERR(32'hB0EEEEEE)) gpx_RFU_u6(
//        .gpx     (m6_gpx.slave    )  ,    
//        .gpx_rst (gpx_rst         )  ,
//        .gpx_clk (gpx_clk         )
//);

endmodule
