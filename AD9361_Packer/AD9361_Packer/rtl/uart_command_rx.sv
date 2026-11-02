// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// RFCT v2 is a byte stream, without line endings. No side effects before CRC.
module uart_command_rx #(parameter CLOCK_HZ=125000000)(
 input wire clk,rst,input wire [7:0] data,input wire valid,framing_error,
 output reg command_valid,input wire command_ready,
 output reg [1023:0] command_bytes,output reg [15:0] command_length,
 output reg [31:0] bad_frames
);
 reg [31:0] magic,crc,timer;
 reg [7:0] pos,total;
 reg collecting,checking;
 reg [1023:0] buffer;
 function automatic [31:0] crc_byte(input [31:0] c,input [7:0] d);
  reg [31:0] v;integer k;begin v=c^d;for(k=0;k<8;k=k+1)v=(v>>1)^(v[0]?32'hedb88320:0);crc_byte=v;end
 endfunction
 wire [31:0] next_crc=crc_byte(crc,(pos>=28&&pos<32)?8'd0:data);
 always @(posedge clk)begin
  if(rst)begin
   magic<=0;crc<=0;timer<=0;pos<=0;total<=32;collecting<=0;checking<=0;
   buffer<=0;command_bytes<=0;command_length<=0;command_valid<=0;bad_frames<=0;
  end else begin
   if(command_valid&&command_ready)command_valid<=0;
   if(timer!=0)timer<=timer-1;
   if(collecting&&timer==0)begin collecting<=0;magic<=0;bad_frames<=bad_frames+1;end
   if(framing_error)begin collecting<=0;checking<=0;magic<=0;bad_frames<=bad_frames+1;end
   else if(valid&&!command_valid&&!checking)begin
    timer<=CLOCK_HZ/20; // 50 ms inter-byte timeout; full 128-byte frame is about 11 ms
    if(!collecting)begin
     magic<={magic[23:0],data};
     if({magic[23:0],data}==32'h52464354)begin
      collecting<=1;buffer<={32'h52464354,992'd0};pos<=4;total<=32;
      crc<=crc_byte(crc_byte(crc_byte(crc_byte(32'hffffffff,8'h52),8'h46),8'h43),8'h54);
     end
    end else begin
     buffer[1023-8*pos-:8]<=data;crc<=next_crc;pos<=pos+1;
     if(pos==23)begin
      if(buffer[863-:24]!=0||data>96)begin collecting<=0;magic<=0;bad_frames<=bad_frames+1;end
      else total<=32+data;
     end
     if(pos==total-1)begin collecting<=0;checking<=1;magic<=0;end
    end
   end
   if(checking)begin
    checking<=0;
    if(buffer[991-:8]==2&&buffer[983-:8]==0&&buffer[975-:16]==32&&
       buffer[959-:32]!=0&&buffer[879-:16]==0&&buffer[799-:32]==~crc)begin
     command_bytes<=buffer;command_length<=total;command_valid<=1;
    end else bad_frames<=bad_frames+1;
   end
  end
 end
endmodule
