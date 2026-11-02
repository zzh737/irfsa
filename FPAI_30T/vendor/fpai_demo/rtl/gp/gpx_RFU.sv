//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : gpx_RFU.v
// Author        : zhaoxiaodong
// Project       :
// Create Date   : 2021.07.30
// Description   : 防止读到无效地址时卡�?
//
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
//==============================================================================

module gpx_RFU#(parameter ERR=32'hEEEEEEEE)(
    mna_gp_ww_itf.slave       gpx                ,    

    input                     gpx_rst            ,
    input                     gpx_clk
);

reg mxx_rvalid;


assign gpx.arready   =  ~mxx_rvalid  ;
assign gpx.rdata     =  ERR ;
assign gpx.rvalid    =  mxx_rvalid   ;
assign gpx.awwready  =  1'b1 ;


always@(posedge gpx_clk) begin
    if(gpx_rst)
       mxx_rvalid <= 1'b0;
    else if(gpx.arvalid && gpx.arready)
       mxx_rvalid <= 1'b1;
    else if(gpx.rvalid && gpx.rready)
       mxx_rvalid <= 1'b0;
end


endmodule
