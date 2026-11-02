// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Passive evidence only. Does not reset, qualify, train, or gate the receiver.
module ad9361_rx_observer(
 input wire data_clk,data_reset,input wire [1:0] frame_pair,
 input wire clk,rst,
 output reg [31:0] recent_frames,
 output wire [31:0] transitions
);
 reg [1:0] previous;
 reg [31:0] change_count,change_gray,history,snapshot_hold;
 reg [9:0] period;
 reg request_toggle;
 reg acknowledge_toggle;
 (* ASYNC_REG="TRUE" *)reg [1:0] acknowledge_sync;
 (* ASYNC_REG="TRUE" *)reg [2:0] request_sync;
 (* ASYNC_REG="TRUE" *)reg [31:0] snapshot_sync1,snapshot_sync2;
 (* ASYNC_REG="TRUE" *)reg [31:0] change_sync1,change_sync2;
 function automatic [31:0] decode(input [31:0] g);
  integer n;begin decode[31]=g[31];for(n=30;n>=0;n=n-1)decode[n]=decode[n+1]^g[n];end
 endfunction
 assign transitions=decode(change_sync2);
 always @(posedge data_clk or posedge data_reset)begin
  if(data_reset)begin
   previous<=0;change_count<=0;change_gray<=0;history<=0;
   snapshot_hold<=0;period<=0;request_toggle<=0;acknowledge_sync<=0;
  end else begin
   acknowledge_sync<={acknowledge_sync[0],acknowledge_toggle};
   previous<=frame_pair;history<={history[29:0],frame_pair};period<=period+1;
   if(previous!=frame_pair)begin
    change_count<=change_count+32'd1;
    change_gray<=(change_count+32'd1)^((change_count+32'd1)>>1);
   end
   // Hold an entire 16-cycle trace until the destination acknowledges it.
   if(period==1023&&acknowledge_sync[1]==request_toggle)begin
    snapshot_hold<={history[29:0],frame_pair};request_toggle<=~request_toggle;
   end
  end
 end
 always @(posedge clk)begin
  request_sync<={request_sync[1:0],request_toggle};
  snapshot_sync1<=snapshot_hold;snapshot_sync2<=snapshot_sync1;
  change_sync1<=change_gray;change_sync2<=change_sync1;
  // Request travels one stage farther than the already-held trace bus.
  if(request_sync[2]!=acknowledge_toggle)begin
   recent_frames<=snapshot_sync2;acknowledge_toggle<=request_sync[2];
  end
  if(rst)begin
   request_sync<=0;snapshot_sync1<=0;snapshot_sync2<=0;
   change_sync1<=0;change_sync2<=0;recent_frames<=0;acknowledge_toggle<=0;
  end
 end
endmodule
