module mna_gp2axi(
    mna_gp_ww_itf.slave         gpx            ,
    input                       gpx_clk        ,
    input                       gpx_rst        ,     
    
    //AXI-Lite Master
    output                      S_AXI_ACLK     ,
    output                      S_AXI_ARESETN  ,
						       
    output      [ 8 : 0]        S_AXI_AWADDR   ,
    output      [ 2 : 0]        S_AXI_AWPROT   ,
    output                      S_AXI_AWVALID  ,
    input                       S_AXI_AWREADY  ,
						        
    output      [31 : 0]        S_AXI_WDATA    ,
    output      [ 3 : 0]        S_AXI_WSTRB    ,
    output                      S_AXI_WVALID   ,
    input                       S_AXI_WREADY   ,
						        
    input       [ 1 : 0]        S_AXI_BRESP    ,
    input                       S_AXI_BVALID   ,
    output                      S_AXI_BREADY   ,
						        
    output      [ 8 : 0]        S_AXI_ARADDR   ,
    output      [ 2 : 0]        S_AXI_ARPROT   ,
    output                      S_AXI_ARVALID  ,
    input                       S_AXI_ARREADY  ,
						        
    input       [31 : 0]        S_AXI_RDATA    ,
    input       [ 1 : 0]        S_AXI_RRESP    ,
    input                       S_AXI_RVALID   ,
    output                      S_AXI_RREADY   
    );

assign S_AXI_ACLK = gpx_clk;
assign S_AXI_ARESETN = ~gpx_rst;

//write
assign S_AXI_AWADDR   = gpx.awwaddr[8:0];
assign S_AXI_AWPROT   = 3'h0;
assign S_AXI_AWVALID  = gpx.awwvalid & S_AXI_WREADY;

assign gpx.awwready   = S_AXI_AWREADY & S_AXI_WREADY;

assign S_AXI_WDATA    = gpx.awwdata;
assign S_AXI_WSTRB    = 4'b1111;
assign S_AXI_WVALID   = gpx.awwvalid && S_AXI_AWREADY;
 
assign S_AXI_BREADY   = 1'b1;

//read
assign S_AXI_ARADDR   = gpx.araddr[8:0];
assign S_AXI_ARPROT   = 3'h0;
assign S_AXI_ARVALID  = gpx.arvalid;

assign gpx.arready    = S_AXI_ARREADY;

assign gpx.rdata      = S_AXI_RDATA ;
assign gpx.rvalid     = S_AXI_RVALID ;
assign S_AXI_RREADY   = gpx.rready  ;
endmodule    