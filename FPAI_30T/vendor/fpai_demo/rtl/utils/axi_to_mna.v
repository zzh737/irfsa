//==============================================================================
// Orgnization   : Shanghai Fudan Microelectronics Co., Ltd. Confidential
// File Name     : axi_to_mna.v
// Author        : Li Xiayu
// Project       : NB1917
// Create Date   : 2020.01.07
// Description   : Master AXI to Mini-AXI interface
//
//------------------------------------------------------------------------------
// Modification History :
// Rev     Date         Who          Description
//==============================================================================

module axi_to_mna #(parameter IDW=12, DW=32, AW=32)(
    output       [  AW-1 : 0]    m_mna_araddr      ,
    output                       m_mna_arvalid     ,
    input                        m_mna_arready     ,
    
    input        [  DW-1 : 0]    m_mna_rdata       ,
    input                        m_mna_rvalid      ,
    output                       m_mna_rready      ,

    output       [  AW-1 : 0]    m_mna_awaddr      ,
    output                       m_mna_awvalid     ,
    input                        m_mna_awready     ,

    output       [  DW-1 : 0]    m_mna_wdata       ,
    output                       m_mna_wvalid      ,
    input                        m_mna_wready      ,

    input        [  AW-1 : 0]    s_axi_araddr      ,
    input        [     1 : 0]    s_axi_arburst     ,
    input        [     3 : 0]    s_axi_arcache     ,
    input        [ IDW-1 : 0]    s_axi_arid        ,
    input        [     3 : 0]    s_axi_arlen       ,
    input        [     1 : 0]    s_axi_arlock      ,
    input        [     2 : 0]    s_axi_arprot      ,
    input        [     3 : 0]    s_axi_arqos       ,
    output                       s_axi_arready     ,
    input        [     2 : 0]    s_axi_arsize      ,
    input                        s_axi_arvalid     ,
    input        [  AW-1 : 0]    s_axi_awaddr      ,
    input        [     1 : 0]    s_axi_awburst     ,
    input        [     3 : 0]    s_axi_awcache     ,
    input        [ IDW-1 : 0]    s_axi_awid        ,
    input        [     3 : 0]    s_axi_awlen       ,
    input        [     1 : 0]    s_axi_awlock      ,
    input        [     2 : 0]    s_axi_awprot      ,
    input        [     3 : 0]    s_axi_awqos       ,
    output                       s_axi_awready     ,
    input        [     2 : 0]    s_axi_awsize      ,
    input                        s_axi_awvalid     ,
    output       [ IDW-1 : 0]    s_axi_bid         ,
    input                        s_axi_bready      ,
    output       [     1 : 0]    s_axi_bresp       ,
    output                       s_axi_bvalid      ,
    output       [  DW-1 : 0]    s_axi_rdata       ,
    output       [ IDW-1 : 0]    s_axi_rid         ,
    output                       s_axi_rlast       ,
    input                        s_axi_rready      ,
    output       [     1 : 0]    s_axi_rresp       ,
    output                       s_axi_rvalid      ,
    input        [  DW-1 : 0]    s_axi_wdata       ,
    input        [ IDW-1 : 0]    s_axi_wid         ,
    input                        s_axi_wlast       ,
    output                       s_axi_wready      ,
    input        [DW/8-1 : 0]    s_axi_wstrb       ,
    input                        s_axi_wvalid      ,
    
    input                        s_axi_clk_rst     ,
    input                        s_axi_clk
);
    reg [4:0] bvalid_cnt;
    
    wire        rid_fifo_wen   ;
    wire        rid_fifo_rden  ;
    wire [11:0] rid_fifo_din   ;
    wire [11:0] rid_fifo_dout  ;
    wire        rid_fifo_full  ;
    wire        rid_fifo_empty ;
    wire        rid_fifo_pfull ;
    
    wire        bid_fifo_wen   ;
    wire        bid_fifo_rden  ;
    wire [11:0] bid_fifo_din   ;
    wire [11:0] bid_fifo_dout  ;
    wire        bid_fifo_full  ;
    wire        bid_fifo_empty ;
    wire        bid_fifo_pfull ;

    assign m_mna_araddr   = s_axi_araddr   ;
//    assign m_mna_arvalid  = s_axi_arvalid  ;
 


//    assign s_axi_arready  = m_mna_arready  ;
    assign s_axi_rdata    = m_mna_rdata    ;
    assign s_axi_rlast    = 1'b1           ;

    assign m_mna_awaddr   = s_axi_awaddr   ; 
    assign m_mna_awvalid  = s_axi_awvalid  ; 
    assign s_axi_awready  = m_mna_awready  ; 

    assign m_mna_wdata    = s_axi_wdata    ; 
//    assign m_mna_wvalid   = s_axi_wvalid && (~bvalid_cnt[4])  ; 
//    assign s_axi_wready   = m_mna_wready && (~bvalid_cnt[4])  ;  

    assign s_axi_bresp    = 2'b00          ;    // okay response
    assign s_axi_rresp    = 2'b00          ;    // okay response

//    always@(posedge s_axi_clk)begin
//        if(s_axi_clk_rst)
//            s_axi_bid <= 0;
//        else if(s_axi_wvalid)
//            s_axi_bid <= s_axi_wid;
//    end

//    always@(posedge s_axi_clk)begin
//        if(s_axi_clk_rst)
//            bvalid_cnt <= 0;
//        else if  (s_axi_wvalid && s_axi_wready && s_axi_bvalid && s_axi_bready)  
//            bvalid_cnt <= bvalid_cnt;
//        else if(s_axi_wvalid && s_axi_wready)
//            bvalid_cnt <= bvalid_cnt + 1'b1;
//        else if(s_axi_bvalid && s_axi_bready)
//            bvalid_cnt <= bvalid_cnt - 1'b1;
//    end

//    assign s_axi_bvalid = (bvalid_cnt!=0);

    assign s_axi_wready = m_mna_wready & ~bid_fifo_full;
    assign m_mna_wvalid = s_axi_wvalid & ~bid_fifo_full; 
    assign bid_fifo_wen = s_axi_wvalid & s_axi_wready ;
    assign bid_fifo_din = s_axi_wid;
    
    assign s_axi_bid      = bid_fifo_dout;
    assign s_axi_bvalid   =  ~bid_fifo_empty ;
    assign bid_fifo_rden  = s_axi_bvalid & s_axi_bready      ;
    
    mna_idfifo_w12 bid_fifo (
                             .clk       (s_axi_clk     ),    // input wire clk
                             .srst      (s_axi_clk_rst ),    // input wire srst
                             .din       (bid_fifo_din  ),    // input wire [11 : 0] din
                             .wr_en     (bid_fifo_wen  ),    // input wire wr_en
                             .rd_en     (bid_fifo_rden ),    // input wire rd_en
                             .dout      (bid_fifo_dout ),    // output wire [11 : 0] dout
                             .full      (bid_fifo_full ),    // output wire full
                             .empty     (bid_fifo_empty),    // output wire empty
                             .prog_full (bid_fifo_pfull)     // output wire prog_full
    ); 

    //always@(posedge s_axi_clk)begin
    //    if(s_axi_clk_rst)
    //        s_axi_bvalid <= 1'b0;
    //    else if(s_axi_wvalid && s_axi_wready)
    //        s_axi_bvalid <= 1'b1;
    //    else if(s_axi_bready)
    //        s_axi_bvalid <= 1'b0;
    //end

//    always@(posedge s_axi_clk)begin
//        if(s_axi_clk_rst)
//            s_axi_rid <= 0;
//        else if(s_axi_arvalid)
//            s_axi_rid <= s_axi_arid;
//    end
    
    assign s_axi_arready = m_mna_arready & ~rid_fifo_full;
    assign m_mna_arvalid = s_axi_arvalid & ~rid_fifo_full;
    assign rid_fifo_wen = s_axi_arvalid & s_axi_arready ;
    assign rid_fifo_din = s_axi_arid;
    
    assign s_axi_rid      = rid_fifo_dout;
    assign m_mna_rready   = s_axi_rready  &  ~rid_fifo_empty ;
    assign s_axi_rvalid   = m_mna_rvalid  &  ~rid_fifo_empty ;
    assign rid_fifo_rden  = s_axi_rvalid & s_axi_rready      ;
    mna_idfifo_w12 rid_fifo (
                             .clk       (s_axi_clk     ),    // input wire clk
                             .srst      (s_axi_clk_rst ),    // input wire srst
                             .din       (rid_fifo_din  ),    // input wire [11 : 0] din
                             .wr_en     (rid_fifo_wen  ),    // input wire wr_en
                             .rd_en     (rid_fifo_rden ),    // input wire rd_en
                             .dout      (rid_fifo_dout ),    // output wire [11 : 0] dout
                             .full      (rid_fifo_full ),    // output wire full
                             .empty     (rid_fifo_empty),    // output wire empty
                             .prog_full (rid_fifo_pfull)     // output wire prog_full
    ); 

endmodule
