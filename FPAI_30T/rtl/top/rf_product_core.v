`timescale 1ns/1ps
// Product register router + Custom Op + frame-coherent display. One read
// response at a time; routing is held until reg_rready accepts the response.
module rf_product_core(
 input wire gp_clk,gp_rst,hp_clk,hp_rst,
 input wire [31:0] reg_awaddr,reg_wdata,input wire reg_wvalid,output wire reg_wready,
 input wire [31:0] reg_araddr,input wire reg_arvalid,output wire reg_arready,
 output wire [31:0] reg_rdata,output wire reg_rvalid,input wire reg_rready,
 output wire [31:0] ddr_awaddr,output wire [511:0] ddr_wdata,
 output wire [71:0] ddr_winfo,output wire ddr_wvalid,input wire ddr_wready,
 output wire [31:0] ddr_araddr,ddr_arinfo,output wire ddr_arvalid,
 input wire ddr_arready,input wire [511:0] ddr_rdata,
 input wire ddr_rvalid,output wire ddr_rready,
 input wire pix_clk,pix_rst,input wire [11:0] x,y,input wire de,hs,vs,
 output wire video_de,video_hs,video_vs,output wire [23:0] video_rgb);
 wire display_write=reg_awaddr[17:0]>=18'h100;
 wire local_read=reg_araddr[17:0]==18'h28||(reg_araddr[17:0]>=18'h30&&reg_araddr[17:0]<=18'h3c);
 wire display_read=reg_araddr[17:0]>=18'h100||local_read;
 wire op_wr,op_ar,op_rvalid;wire [31:0] op_rdata,display_data;
 wire op_busy,op_done,op_error,display_busy,display_commit;
 reg pending=0,read_display=0;reg [31:0] held_display;
 reg [31:0] accepted_count,completed_count,error_count,display_count;
 reg done_seen;
 reg [31:0] local_data;
 always @*begin
   case(reg_araddr[17:0])
     18'h28:local_data=7;
     18'h30:local_data=accepted_count;
     18'h34:local_data=completed_count;
     18'h38:local_data=error_count;
     18'h3c:local_data=display_count;
     default:local_data=32'hdeadbeef;
   endcase
 end
 always @(posedge gp_clk)begin
   if(gp_rst)begin accepted_count<=0;completed_count<=0;error_count<=0;display_count<=0;done_seen<=0;end
   else begin
     done_seen<=op_done;
     if(reg_wvalid&&reg_wready&&reg_awaddr[17:0]==18'h10&&reg_wdata[0]&&!reg_wdata[1]&&!op_busy)
       accepted_count<=accepted_count+1'b1;
     if(op_done&&!done_seen)begin
       completed_count<=completed_count+1'b1;
       if(op_error)error_count<=error_count+1'b1;
     end
     if(display_commit)
       display_count<=display_count+1'b1;
   end
 end
 wire accept_read=reg_arvalid&&reg_arready;
 assign reg_wready=display_write ? !gp_rst : op_wr;
 assign reg_arready=!gp_rst&&!pending&&(display_read||op_ar);
 assign reg_rvalid=pending&&(read_display||op_rvalid);
 assign reg_rdata=read_display ? held_display : op_rdata;
 always @(posedge gp_clk)begin
   if(gp_rst)begin pending<=0;read_display<=0;held_display<=0;end
   else begin
     if(reg_rvalid&&reg_rready)pending<=0;
     if(accept_read)begin
       pending<=1;read_display<=display_read;
       held_display<=local_read ? local_data : display_data;
     end
   end
 end
 rf_custom_op U_rf_custom_op(
 .gp_clk(gp_clk),.gp_rst(gp_rst),.hp_clk(hp_clk),.hp_rst(hp_rst),
 .reg_awaddr(reg_awaddr),.reg_wdata(reg_wdata),
 .reg_wvalid(reg_wvalid&&!display_write),.reg_wready(op_wr),
 .reg_araddr(reg_araddr),.reg_arvalid(accept_read&&!display_read),.reg_arready(op_ar),
 .reg_rdata(op_rdata),.reg_rvalid(op_rvalid),.reg_rready(reg_rready&&pending&&!read_display),
 .ddr_awaddr(ddr_awaddr),.ddr_wdata(ddr_wdata),.ddr_winfo(ddr_winfo),
 .ddr_wvalid(ddr_wvalid),.ddr_wready(ddr_wready),
 .ddr_araddr(ddr_araddr),.ddr_arinfo(ddr_arinfo),.ddr_arvalid(ddr_arvalid),
 .ddr_arready(ddr_arready),.ddr_rdata(ddr_rdata),.ddr_rvalid(ddr_rvalid),.ddr_rready(ddr_rready),
 .status_busy(op_busy),.status_done(op_done),.status_error(op_error));
 spectrum_display U_display(gp_clk,gp_rst,reg_awaddr[17:0],reg_wdata,
 reg_wvalid&&reg_wready&&display_write,reg_araddr[17:0],display_data,
 pix_clk,pix_rst,x,y,de,hs,vs,video_de,video_hs,video_vs,video_rgb,display_busy,display_commit);
endmodule
