`timescale 1ns/1ps
// Combined vendor register request bus, NOT a raw AXI-Lite slave.
// MODE=0 Hann/rectangular FFT power; MODE=1 copies one 4096-byte frame.
// Multi-bit command/response mailboxes remain stable across toggle handshakes.
module rf_custom_op(
 input wire gp_clk,gp_rst,hp_clk,hp_rst,
 input wire [31:0] reg_awaddr,reg_wdata,input wire reg_wvalid,output wire reg_wready,
 input wire [31:0] reg_araddr,input wire reg_arvalid,output wire reg_arready,
 output reg [31:0] reg_rdata,output reg reg_rvalid,input wire reg_rready,
 output wire [31:0] ddr_awaddr,output wire [511:0] ddr_wdata,
 output wire [71:0] ddr_winfo,output wire ddr_wvalid,input wire ddr_wready,
 output wire [31:0] ddr_araddr,ddr_arinfo,output wire ddr_arvalid,
 input wire ddr_arready,input wire [511:0] ddr_rdata,
 input wire ddr_rvalid,output wire ddr_rready,
 output wire status_busy,status_done,status_error);
 reg [31:0] input_addr,output_addr,input_bytes,output_bytes,frame_seq,mode,window_mode;
 reg [31:0] cmd_input,cmd_output,cmd_inbytes,cmd_outbytes,cmd_mode,cmd_window;
 reg busy,done,error;
 reg [31:0] error_code;
 assign status_busy=busy;
 assign status_done=done;
 assign status_error=error;
 reg req_toggle=0,ack_toggle=0;
 (* ASYNC_REG="TRUE" *) reg [1:0] req_sync=0,ack_sync=0;
 reg ack_seen=0;
 reg [31:0] hp_error;
 wire wr=reg_wvalid&&reg_wready;
 wire [17:0] wa=reg_awaddr[17:0],ra=reg_araddr[17:0];
 assign reg_wready=!gp_rst;
 assign reg_arready=!gp_rst&&(!reg_rvalid||reg_rready);
 always @(posedge gp_clk) begin
   if(gp_rst) begin
     input_addr<=0;output_addr<=0;input_bytes<=4096;output_bytes<=4096;
     frame_seq<=0;mode<=0;window_mode<=1;busy<=0;done<=0;error<=0;error_code<=0;
     cmd_input<=0;cmd_output<=0;cmd_inbytes<=0;cmd_outbytes<=0;cmd_mode<=0;cmd_window<=1;
     req_toggle<=0;ack_sync<=0;ack_seen<=0;reg_rvalid<=0;reg_rdata<=0;
   end else begin
     ack_sync<={ack_sync[0],ack_toggle};
     if(ack_sync[1]!=ack_seen) begin
       ack_seen<=ack_sync[1];busy<=0;done<=1;
       error<=(hp_error!=0);error_code<=hp_error;
     end
     if(wr && !busy) case(wa)
       18'h00:input_addr<=reg_wdata;
       18'h04:output_addr<=reg_wdata;
       18'h08:input_bytes<=reg_wdata;
       18'h0c:output_bytes<=reg_wdata;
       18'h18:frame_seq<=reg_wdata;
       18'h24:mode<=reg_wdata;
       18'h2c:window_mode<=reg_wdata;
       18'h10:begin
         if(reg_wdata[1]) begin done<=0;error<=0;error_code<=0;end
         else if(reg_wdata[0]) begin
           cmd_input<=input_addr;cmd_output<=output_addr;
           cmd_inbytes<=input_bytes;cmd_outbytes<=output_bytes;cmd_mode<=mode;
           cmd_window<=window_mode;
           req_toggle<=~req_toggle;busy<=1;done<=0;error<=0;error_code<=0;
         end
       end
     endcase
     if(reg_rvalid&&reg_rready) reg_rvalid<=0;
     if(reg_arvalid&&reg_arready) begin
       reg_rvalid<=1;
       case(ra)
         18'h00:reg_rdata<=input_addr;
         18'h04:reg_rdata<=output_addr;
         18'h08:reg_rdata<=input_bytes;
         18'h0c:reg_rdata<=output_bytes;
         18'h10:reg_rdata<=0;
         18'h14:reg_rdata<={29'b0,error,done,busy};
         18'h18:reg_rdata<=frame_seq;
         18'h1c:reg_rdata<=error_code;
         18'h20:reg_rdata<=32'h20261022;
         18'h24:reg_rdata<=mode;
         18'h28:reg_rdata<=32'h00000003; // bit0 COPY, bit1 FFT power
         18'h2c:reg_rdata<=window_mode;
         default:reg_rdata<=32'hdeadbeef;
       endcase
     end
   end
 end
 localparam IDLE=0,READ_REQ=1,READ_DATA=2,WRITE_DATA=3,
   FFT_FEED=4,FFT_WAIT=5,FFT_WRITE=6,CHECK_CMD=7;
 reg [2:0] state=IDLE;
 reg [31:0] src,dst;
 reg [5:0] beat;
 reg [511:0] held_data;
 reg fft_start,fft_window,is_fft;
 reg bad_mode,bad_frame,overlap;
 reg [3:0] lane;
 wire fft_in_ready,fft_out_valid;
 wire [31:0] fft_power;
 fft1024_power U_fft(.clk(hp_clk),.rst(hp_rst),.start(fft_start),
   .window_hann(fft_window),.s_iq(held_data[lane*32+:32]),
   .s_valid(state==FFT_FEED),.s_ready(fft_in_ready),
   .m_power(fft_power),.m_valid(fft_out_valid),.m_ready(state==FFT_WAIT),
   .m_last(),.busy(),.done());
 // These are internal 64-byte transfers; PL DDR physical DQ remains x64.
 assign ddr_araddr=src;
 assign ddr_arinfo=32'h1;
 assign ddr_arvalid=(state==READ_REQ)&&!hp_rst;
 assign ddr_rready=(state==READ_DATA)&&!hp_rst;
 assign ddr_awaddr=dst;
 assign ddr_wdata=held_data;
 assign ddr_winfo={1'b0,64'hffffffffffffffff,6'b0,1'b1};
 assign ddr_wvalid=(state==WRITE_DATA||state==FFT_WRITE)&&!hp_rst;
 always @(posedge hp_clk) begin
   if(hp_rst) begin
     state<=IDLE;req_sync<=0;ack_toggle<=0;hp_error<=0;
     src<=0;dst<=0;beat<=0;held_data<=0;
     fft_start<=0;fft_window<=1;is_fft<=0;lane<=0;
     bad_mode<=0;bad_frame<=0;overlap<=0;
   end else begin
     fft_start<=0;
     req_sync<={req_sync[0],req_toggle};
     case(state)
       IDLE:if(req_sync[1]!=ack_toggle) begin
         hp_error<=0;
         // Register validation results before choosing the next operation.
         // This bounds the GP mailbox -> HP crossing without putting the
         // address subtractors and the entire state decoder in one path.
         bad_mode<=cmd_mode>1;
         bad_frame<=cmd_inbytes!=4096||cmd_outbytes!=4096||
           (cmd_mode==0 && cmd_window>1)||
           cmd_input[5:0]!=0||cmd_output[5:0]!=0||
           cmd_input>32'hfffff000||cmd_output>32'hfffff000;
         overlap<=(cmd_input<=cmd_output && cmd_output-cmd_input<4096)||
                  (cmd_output<=cmd_input && cmd_input-cmd_output<4096);
         src<=cmd_input;dst<=cmd_output;beat<=0;
         is_fft<=cmd_mode==0;fft_window<=cmd_window[0];lane<=0;
         state<=CHECK_CMD;
       end
       CHECK_CMD:begin
         if(bad_mode)begin hp_error<=1;ack_toggle<=req_sync[1];state<=IDLE;end
         else if(bad_frame)begin hp_error<=2;ack_toggle<=req_sync[1];state<=IDLE;end
         else if(overlap)begin hp_error<=3;ack_toggle<=req_sync[1];state<=IDLE;
         end else begin
           state<=READ_REQ;
           if(is_fft)fft_start<=1;
         end
       end
       READ_REQ:if(ddr_arready)state<=READ_DATA;
       READ_DATA:if(ddr_rvalid)begin
         held_data<=ddr_rdata;lane<=0;
         state<=is_fft ? FFT_FEED : WRITE_DATA;
       end
       FFT_FEED:if(fft_in_ready)begin
         if(lane==15)begin
           lane<=0;
           if(beat==63)begin beat<=0;state<=FFT_WAIT;end
           else begin beat<=beat+1'b1;src<=src+64;state<=READ_REQ;end
         end else lane<=lane+1'b1;
       end
       FFT_WAIT:if(fft_out_valid)begin
         held_data[lane*32+:32]<=fft_power;
         if(lane==15)begin lane<=0;state<=FFT_WRITE;end
         else lane<=lane+1'b1;
       end
       FFT_WRITE:if(ddr_wready)begin
         if(beat==63)begin state<=IDLE;ack_toggle<=req_sync[1];end
         else begin beat<=beat+1'b1;dst<=dst+64;state<=FFT_WAIT;end
       end
       WRITE_DATA:if(ddr_wready) begin
         if(beat==63)begin state<=IDLE;ack_toggle<=req_sync[1];end
         else begin beat<=beat+1'b1;src<=src+64;dst<=dst+64;state<=READ_REQ;end
       end
     endcase
   end
 end
endmodule
