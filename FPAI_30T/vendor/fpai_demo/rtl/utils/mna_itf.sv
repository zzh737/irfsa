
/* interface mna_gp_ww_itf;

 logic [ 31 : 0]    araddr       ;
 logic              arvalid      ;
 logic              arready      ;
 logic [ 31 : 0]    rdata        ;
 logic              rvalid       ;
 logic              rready       ;
 logic [ 31 : 0]    awwaddr      ;
 logic [ 31 : 0]    awwdata      ;
 logic              awwvalid     ;
 logic              awwready     ;

 modport slave(
  input   araddr       ,
  input   arvalid      ,
  output  arready      ,
  output  rdata        ,
  output  rvalid       ,
  input   rready       ,
  input   awwaddr      ,
  input   awwdata      ,
  input   awwvalid     ,
  output  awwready     );
 
 modport master(
  output  araddr       ,
  output  arvalid      ,
  input   arready      ,
  input   rdata        ,
  input   rvalid       ,
  output  rready       ,
  output  awwaddr      ,
  output  awwdata      ,
  output  awwvalid     ,
  input   awwready     );

endinterface //mini axi wwaddr&wwdata gp interface
 */
interface mna_gp_ww_itf;

 logic [ 31 : 0]    araddr       ;
 logic              arvalid      ;
 logic              arready      ;
 logic [ 31 : 0]    rdata        ;
 logic              rvalid       ;
 logic              rready       ;
 logic [ 31 : 0]    awwaddr      ;
 logic [ 31 : 0]    awwdata      ;
 logic              awwvalid     ;
 logic              awwready     ;

 modport slave(
  input   araddr       ,
  input   arvalid      ,
  output  arready      ,
  output  rdata        ,
  output  rvalid       ,
  input   rready       ,
  input   awwaddr      ,
  input   awwdata      ,
  input   awwvalid     ,
  output  awwready     );
 
 modport master(
  output  araddr       ,
  output  arvalid      ,
  input   arready      ,
  input   rdata        ,
  input   rvalid       ,
  output  rready       ,
  output  awwaddr      ,
  output  awwdata      ,
  output  awwvalid     ,
  input   awwready     );

endinterface //mini axi reg access interface

/////////////////////////////////////////////////////////

interface mna_gp_ww_brsep_itf;

 logic   [1:0]            bresp  ;
 logic                    bvalid ;
 logic                    bready ;
 logic [  8 : 0]          araddr       ;
 logic                    arvalid      ;
 logic                    arready      ;
 logic [ 31 : 0]          rdata        ;
 logic                    rvalid       ;
 logic                    rready       ;
 logic [  8 : 0]          awwaddr      ;
 logic [ 31 : 0]          awwdata      ;
 logic                    awwvalid     ;
 logic                    awwready     ;

 modport slave(
  input   araddr       ,
  input   arvalid      ,
  output  arready      ,
  output  rdata        ,
  output  rvalid       ,
  input   rready       ,
  input   awwaddr      ,
  input   awwdata      ,
  input   awwvalid     ,
  output  awwready     ,
  output  bresp        ,
  output  bvalid       ,
  input   bready       );

 modport master(
  output  araddr       ,
  output  arvalid      ,
  input   arready      ,
  input   rdata        ,
  input   rvalid       ,
  output  rready       ,
  output  awwaddr      ,
  output  awwdata      ,
  output  awwvalid     ,
  input   awwready     ,
  input   bresp        ,
  input   bvalid       ,
  output  bready       ); 

endinterface //mna_gp_ww with brsep

//////////////////////////////////////////////////////////

interface mna_gp_std_itf;

 logic   [ 31 : 0]    araddr        ;
 logic                arvalid       ;
 logic                arready       ;
 logic   [ 31 : 0]    rdata         ;
 logic                rvalid        ;
 logic                rready        ;
 logic   [ 31 : 0]    awaddr        ;
 logic                awvalid       ;
 logic                awready       ;
 logic   [ 31 : 0]    wdata         ;
 logic                wvalid        ;
 logic                wready        ;

 modport master(
   output araddr        ,
   output arvalid       ,
   input  arready       ,
   input  rdata         ,
   input  rvalid        ,
   output rready        ,
   output awaddr        ,
   output awvalid       ,
   input  awready       ,
   output wdata         ,
   output wvalid        ,
   input  wready        );
 
 modport slave (
   input   araddr        ,
   input   arvalid       ,
   output  arready       ,
   output  rdata         ,
   output  rvalid        ,
   input   rready        ,
   input   awaddr        ,
   input   awvalid       ,
   output  awready       ,
   input   wdata         ,
   input   wvalid        ,
   output  wready        );

endinterface  //mini axi standard gp interface

//////////////////////////////////////////////////////////
interface mna_gp_std_brsep_itf;

 logic   [ 31 : 0]    araddr        ;
 logic                arvalid       ;
 logic                arready       ;
 logic   [ 31 : 0]    rdata         ;
 logic                rvalid        ;
 logic                rready        ;
 logic   [ 31 : 0]    awaddr        ;
 logic                awvalid       ;
 logic                awready       ;
 logic   [ 31 : 0]    wdata         ;
 logic                wvalid        ;
 logic                wready        ;
 logic   [1:0]        bresp         ;
 logic                bvalid        ;
 logic                bready        ;

 modport master(
   output araddr        ,
   output arvalid       ,
   input  arready       ,
   input  rdata         ,
   input  rvalid        ,
   output rready        ,
   output awaddr        ,
   output awvalid       ,
   input  awready       ,
   output wdata         ,
   output wvalid        ,
   input  wready        ,
   input   bresp        ,
   input   bvalid       ,
   output  bready       );   

 modport slave (
   input   araddr        ,
   input   arvalid       ,
   output  arready       ,
   output  rdata         ,
   output  rvalid        ,
   input   rready        ,
   input   awaddr        ,
   input   awvalid       ,
   output  awready       ,
   input   wdata         ,
   input   wvalid        ,
   output  wready        ,
   output  bresp        ,
   output  bvalid       ,
   input   bready       ); 

endinterface  //mini axi standard gp interface with brsep

///////////////////////////////////////////////////////

interface mna_hp_std_itf;

 logic   [ 31 : 0]    araddr        ;
 logic   [ 31 : 0]    arinfo        ; 
 logic                arvalid       ;
 logic                arready       ;
 logic   [ 63 : 0]    rdata         ;
 logic                rvalid        ;
 logic                rready        ;
 logic   [ 31 : 0]    awaddr        ;
 logic                awvalid       ;
 logic                awready       ;
 logic   [ 63 : 0]    wdata         ;
 logic                wvalid        ;
 logic                wready        ;

 modport master(
   output araddr        ,
   output arvalid       ,
   input  arready       ,
   input  rdata         ,
   input  rvalid        ,
   output rready        ,
   output awaddr        ,
   output awvalid       ,
   input  awready       ,
   output wdata         ,
   output wvalid        ,
   input  wready        );
 
 modport slave (
   input   araddr        ,
   input   arvalid       ,
   output  arready       ,
   output  rdata         ,
   output  rvalid        ,
   input   rready        ,
   input   awaddr        ,
   input   awvalid       ,
   output  awready       ,
   input   wdata         ,
   input   wvalid        ,
   output  wready        );

endinterface  //mini axi hp standard interface

//////////////////////////////////////////////////////

/* interface mna_ddr_ww_itf;

 logic [ 31 : 0]    awwaddr      ;
 logic [511 : 0]    awwdata      ;
 logic [ 31 : 0]    awwinfo      ; //{24'h0,4'b{info},use_lut,flush_lut,awwfirst,awwlast}
 logic              awwvalid     ;
 logic              awwready     ;

 modport slave(
  input   awwaddr      ,
  input   awwdata      ,
  input   awwinfo      ,
  input   awwvalid     ,
  output  awwready     );
 
 modport master(
  output  awwaddr      ,
  output  awwdata      ,
  output  awwinfo      ,
  output  awwvalid     ,
  input   awwready     );

endinterface //mini axi wwaddr&wwdata ddr interface

/////////////////////////////////////////////////////////////////////////

interface mna_ddr_rd_itf;

 logic [ 31 : 0]    araddr       ;
 logic              arvalid      ;
 logic [ 31:  0]    arinfo       ;   //{28'h0,disable_decrypt,kexpd,arfirst,arlast}
 logic              arready      ;
 logic [511 : 0]    rdata        ;
 logic              rvalid       ;
 logic [ 31:  0]    rinfo        ;  //{28'h0,disable_decrypt,kexpd,rfirst,rlast}
 logic              rready       ;

 modport slave(
  input   araddr       ,
  input   arvalid      ,
  input   arinfo       ,
  output  arready      ,
  output  rdata        ,
  output  rvalid       ,
  output  rinfo        ,
  input   rready       );

 modport master(
  output  araddr       ,
  output  arvalid      ,
  output  arinfo       ,
  input   arready      ,
  input   rdata        ,
  input   rvalid       ,
  input   rinfo        ,
  output  rready       );

endinterface //mini axi read ddr interface */
interface mna_ddr_ww_itf;

 logic [ 31 : 0]    awwaddr      ;
 logic [511 : 0]    awwdata      ;
 logic [ 71 : 0]    awwinfo      ; //{1'b0,pl_awen[63:0],pl_awinfo[5:0],pl_awlast[0]}
 logic              awwvalid     ;
 logic              awwready     ;

 modport slave(
  input   awwaddr      ,
  input   awwdata      ,
  input   awwinfo      ,
  input   awwvalid     ,
  output  awwready     );  
 
 modport master(
  output  awwaddr      ,
  output  awwdata      ,
  output  awwinfo      ,
  output  awwvalid     ,
  input   awwready     );

endinterface //mini axi wwaddr&wwdata ddr interface

interface mna_ddr33_ww_itf;

 logic [ 32 : 0]    awwaddr      ;
 logic [511 : 0]    awwdata      ;
 logic [ 71 : 0]    awwinfo      ; //{1'b0,pl_awen[63:0],pl_awinfo[5:0],pl_awlast[0]}
 logic              awwvalid     ;
 logic              awwready     ;
 logic              bvalid       ; 
 logic              bready       ; 

 modport slave(
  input   awwaddr      ,
  input   awwdata      ,
  input   awwinfo      ,
  input   awwvalid     ,
  output  awwready     ,
  output  bvalid       ,
  input   bready       );
 
 modport master(
  output  awwaddr      ,
  output  awwdata      ,
  output  awwinfo      ,
  output  awwvalid     ,
  input   awwready     ,
  input   bvalid       ,
  output  bready       );

endinterface //mini axi wwaddr&wwdata ddr interface

/////////////////////////////////////////////////////////////////////////

interface mna_ddr_rd_itf;

 logic [ 31 : 0]    araddr       ;
 logic              arvalid      ;
 logic [ 31:  0]    arinfo       ;  //{25'h0,pl_arinfo,pl_arlast}
 logic              arready      ;
 logic [511 : 0]    rdata        ;
 logic              rvalid       ;
 logic [ 31:  0]    rinfo        ;  //{25'h0,pl_rinfo,pl_rlast}
 logic              rready       ;

 modport slave(
  input   araddr       ,
  input   arvalid      ,
  input   arinfo       ,
  output  arready      ,
  output  rdata        ,
  output  rvalid       ,
  output  rinfo        ,
  input   rready       );

 modport master(
  output  araddr       ,
  output  arvalid      ,
  output  arinfo       ,
  input   arready      ,
  input   rdata        ,
  input   rvalid       ,
  input   rinfo        ,
  output  rready       );

endinterface //mini axi read ddr interface

interface mna_ddr33_rd_itf;

 logic [ 32 : 0]    araddr       ;
 logic              arvalid      ;
 logic [ 31:  0]    arinfo       ;  //{25'h0,pl_arinfo,pl_arlast}
 logic              arready      ;
 logic [511 : 0]    rdata        ;
 logic              rvalid       ;
 logic [ 31:  0]    rinfo        ;  //{25'h0,pl_rinfo,pl_rlast}
 logic              rready       ;

 modport slave(
  input   araddr       ,
  input   arvalid      ,
  input   arinfo       ,
  output  arready      ,
  output  rdata        ,
  output  rvalid       ,
  output  rinfo        ,
  input   rready       );

 modport master(
  output  araddr       ,
  output  arvalid      ,
  output  arinfo       ,
  input   arready      ,
  input   rdata        ,
  input   rvalid       ,
  input   rinfo        ,
  output  rready       );

endinterface //mini axi read ddr interface

///////////////////////////////////////////////////////

interface data_itf#(parameter LEN = 384,parameter INFO_LEN = 32);
  
 logic [LEN-1 :0]      data   ;
 logic                 valid  ;
 logic                 ready  ;
 logic [INFO_LEN-1:0]  info   ;

 modport master(
  output  data       ,
  output  valid      ,
  output  info       ,
  input   ready      );

 modport slave(
  input   data       ,
  input   valid      ,
  input   info       ,
  output  ready      );

endinterface //data interface

//////////////////////////////////////////////////////

