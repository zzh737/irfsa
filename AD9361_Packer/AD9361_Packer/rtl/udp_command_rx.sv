// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Store-and-validate control datagrams before exposing any command side effects.
module udp_command_rx(
 input wire clk,rst,
 input wire hdr_valid,output wire hdr_ready,
 input wire [47:0] dest_mac,input wire [3:0] version,ihl,
 input wire [15:0] ip_length,input wire [2:0] ip_flags,input wire [12:0] fragment_offset,
 input wire [31:0] source_ip,dest_ip,input wire [15:0] source_port,dest_port,udp_length,udp_checksum,
 input wire [7:0] data,input wire valid,output wire ready,input wire last,user,
 output reg command_valid,input wire command_ready,output reg [1023:0] command_bytes,
 output reg [15:0] command_length,output reg [31:0] bad_packets
);
 reg active,acceptable,checking,bad;
 reg [15:0] pos,length_l,checksum_l;
 reg [31:0] crc,sum;reg [7:0] previous;
 function automatic [31:0] crc_byte(input [31:0] c,input [7:0] d);
  reg [31:0] v;integer n;begin v=c^d;for(n=0;n<8;n=n+1)v=(v>>1)^(v[0]?32'hedb88320:0);crc_byte=v;end
 endfunction
 wire [31:0] crc_next=crc_byte(crc,(pos>=28&&pos<32)?8'd0:data);
 wire [31:0] sum_next=sum+(pos[0]?{16'd0,previous,data}:(last?{16'd0,data,8'd0}:32'd0));
 wire [31:0] folded=(sum>>16)+(sum&32'hffff);
 wire [31:0] folded_twice=(folded>>16)+(folded&32'hffff);
 assign hdr_ready=!active&&!checking&&!command_valid;
 assign ready=active;
 always @(posedge clk)begin
  if(rst)begin
   active<=0;checking<=0;command_valid<=0;command_bytes<=0;bad_packets<=0;
   pos<=0;crc<=0;sum<=0;bad<=0;acceptable<=0;command_length<=0;
  end else begin
   if(command_valid&&command_ready)command_valid<=0;
   if(hdr_valid&&hdr_ready)begin
    active<=1;acceptable<=dest_mac==48'h020000000002&&version==4&&ihl==5&&
     !ip_flags[0]&&!ip_flags[2]&&fragment_offset==0&&ip_length==udp_length+20&&
     source_ip==32'hc0a80a01&&dest_ip==32'hc0a80a02&&
     source_port==40001&&dest_port==40001&&udp_length>=40&&udp_length<=1480;
    pos<=0;length_l<=udp_length-8;checksum_l<=udp_checksum;crc<=32'hffffffff;
    sum<={16'd0,source_ip[31:16]}+{16'd0,source_ip[15:0]}+
     {16'd0,dest_ip[31:16]}+{16'd0,dest_ip[15:0]}+32'd17+
     {16'd0,udp_length}+{16'd0,udp_length}+{16'd0,source_port}+{16'd0,dest_port}+{16'd0,udp_checksum};
    bad<=0;command_bytes<=0;
   end
   if(valid&&ready)begin
    if(pos<128)command_bytes[1023-8*pos-:8]<=data;
    pos<=pos+1;previous<=data;crc<=crc_next;sum<=sum_next;bad<=bad|user;
    if(last)begin active<=0;checking<=1;command_length<=pos+1;end
   end
   if(checking)begin
    checking<=0;
    if(acceptable&&!bad&&command_length==length_l&&command_length>=32&&
     command_bytes[1023-:32]==32'h52464354&&
     command_bytes[991-:8]==1&&command_length<=128&&
     command_bytes[983-:8]==0&&command_bytes[975-:16]==32&&
     command_bytes[959-:32]!=0&&command_bytes[879-:16]==0&&
     command_bytes[863-:32]==command_length-32&&
     command_bytes[799-:32]==~crc&&(checksum_l==0||folded_twice==65535))command_valid<=1;
    else bad_packets<=bad_packets+1;
   end
  end
 end
endmodule
