//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : gpx_ww_split.v
// Author        : zhaoxiaodong
// Project       :
// Create Date   : 2020.02.07
// Description   : ASP:addr split bit
//
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
// 1.01    2022.7.3     xuyun        add parameter ERR
//==============================================================================

module gpx_ww_split #(parameter BASE=32'h43C00000,ERR=32'hEEEEEEEE,ASP=8)(
    mna_gp_ww_itf.slave       gpx                ,    
    mna_gp_ww_itf.master      m00_gpx            ,
    mna_gp_ww_itf.master      m01_gpx            ,

    input                     gpx_rst            ,
    input                     gpx_clk
);


wire rbase_match,wbase_match;
reg wait_rdata;
reg mxx_rvalid;


assign rbase_match = gpx.araddr[31:ASP+1]  == BASE[31:ASP+1];
assign wbase_match = gpx.awwaddr[31:ASP+1] == BASE[31:ASP+1];


assign m00_gpx.araddr   = gpx.araddr;
assign m00_gpx.arvalid  = rbase_match && (~wait_rdata) && (~gpx.araddr[ASP]) & gpx.arvalid  ;
assign m00_gpx.rready   = gpx.rready;
assign m00_gpx.awwaddr  = gpx.awwaddr;
assign m00_gpx.awwdata  = gpx.awwdata;
assign m00_gpx.awwvalid = wbase_match && (~gpx.awwaddr[ASP]) & gpx.awwvalid ;

assign m01_gpx.araddr   = gpx.araddr;
assign m01_gpx.arvalid  = rbase_match && (~wait_rdata) && (gpx.araddr[ASP]) & gpx.arvalid  ;
assign m01_gpx.rready   = gpx.rready;
assign m01_gpx.awwaddr  = gpx.awwaddr;
assign m01_gpx.awwdata  = gpx.awwdata;
assign m01_gpx.awwvalid = wbase_match && (gpx.awwaddr[ASP]) & gpx.awwvalid ;

assign gpx.arready   =  rbase_match ? ((gpx.araddr[ASP]) ? (~wait_rdata) && m01_gpx.arready : (~wait_rdata) && m00_gpx.arready) : ~mxx_rvalid ;
assign gpx.rdata     =  mxx_rvalid ? ERR : (m01_gpx.rvalid  ? m01_gpx.rdata : m00_gpx.rdata)   ;
assign gpx.rvalid    =  mxx_rvalid | m01_gpx.rvalid  | m00_gpx.rvalid  ;
assign gpx.awwready  =  wbase_match ? ((gpx.awwaddr[ASP]) ? m01_gpx.awwready : m00_gpx.awwready) : 1'b1 ;

always@(posedge gpx_clk) begin
    if(gpx_rst)
       wait_rdata <= 1'b0;
    else if(gpx.arvalid && gpx.arready)
       wait_rdata <= 1'b1;
    else if(gpx.rvalid && gpx.rready)
       wait_rdata <= 1'b0;
end

always@(posedge gpx_clk) begin
    if(gpx_rst)
       mxx_rvalid <= 1'b0;
    else if( (~rbase_match) && gpx.arvalid && gpx.arready)
       mxx_rvalid <= 1'b1;
    else if(gpx.rvalid && gpx.rready)
       mxx_rvalid <= 1'b0;
end


endmodule
