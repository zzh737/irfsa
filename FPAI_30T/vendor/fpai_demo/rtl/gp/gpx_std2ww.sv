//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : gpx_std2ww.v
// Author        : zhaoxiaodong
// Project       :
// Create Date   : 2020.02.07
// Description   :
//
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
//==============================================================================

module gpx_std2ww (
    mna_gp_std_itf.slave      std_gpx            ,    
    mna_gp_ww_itf.master      ww_gpx             ,

    input                     gpx_rst            ,
    input                     gpx_clk
);

///write
 reg    awaddr_vld,wdata_vld;

 assign std_gpx.awready =  ww_gpx.awwvalid ? ww_gpx.awwready : ~awaddr_vld; 
 assign std_gpx.wready  =  ww_gpx.awwvalid ? ww_gpx.awwready : ~wdata_vld;

 always@(posedge gpx_clk) begin
     if(gpx_rst)
        {awaddr_vld,ww_gpx.awwaddr} <= 0;
     else if(std_gpx.awvalid && std_gpx.awready)
        {awaddr_vld,ww_gpx.awwaddr} <= {1'b1,std_gpx.awaddr};
     else if(ww_gpx.awwready && ww_gpx.awwvalid)
        {awaddr_vld,ww_gpx.awwaddr} <= {1'b0,ww_gpx.awwaddr};
 end

 always@(posedge gpx_clk) begin
     if(gpx_rst)
        {wdata_vld,ww_gpx.awwdata} <= 0;
     else if(std_gpx.wvalid && std_gpx.wready)
        {wdata_vld,ww_gpx.awwdata} <= {1'b1,std_gpx.wdata};
     else if(ww_gpx.awwready && ww_gpx.awwvalid)
        {wdata_vld,ww_gpx.awwdata} <= {1'b0,ww_gpx.awwdata};
 end
 
 assign ww_gpx.awwvalid = awaddr_vld && wdata_vld;



///read 

assign ww_gpx.araddr  = std_gpx.araddr ;
assign ww_gpx.arvalid = std_gpx.arvalid;
assign ww_gpx.rready  = std_gpx.rready ;

assign std_gpx.arready = ww_gpx.arready;
assign std_gpx.rdata   = ww_gpx.rdata;
assign std_gpx.rvalid  = ww_gpx.rvalid;




endmodule
