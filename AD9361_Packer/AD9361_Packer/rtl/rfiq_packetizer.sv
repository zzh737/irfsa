// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Stop drains committed windows; only the unfinished input window is discarded.
module rfiq_packetizer #(parameter BANK_BITS=5)(  // HW22: 32 windows (was 16)
 input wire clk,rst,run,
 input wire [31:0] stream_id,capture_id,fs_hz,input wire [63:0] lo_hz,
 input wire signed [31:0] gain_mdb,
 input wire sample_valid,input wire [15:0] sample_i,sample_q,input wire sample_clipped,
 output wire hdr_valid,input wire hdr_ready,
 output wire [7:0] data,output wire valid,input wire ready,output wire last,
 output reg [63:0] samples,datagrams,dropped,
 output wire [1:0] occupied,output wire idle,output wire [31:0] fifo_points
);
 localparam BANKS=1<<BANK_BITS;
 (* ram_style="block" *)reg [31:0] iq[0:BANKS*1024-1];
 reg [31:0] crc[0:BANKS*4-1],seqno[0:BANKS-1];
 reg [15:0] winflags[0:BANKS-1];
 reg [BANKS-1:0] full;
 reg [9:0] wr_count;
 reg [BANK_BITS-1:0] wr_bank,wr_head,rd_bank,rd_head;
 reg skip,clipped,gap,active,payload,was_run;
 reg [31:0] sequence_num,crc_acc;
 reg [1:0] frag;reg [10:0] pos;
 reg [31:0] stream_l,capture_l,fs_l,gain_l;reg [63:0] lo_l;
 wire start=run&&!was_run;
 wire selected_skip=wr_count==0?full[wr_head]:skip;
 wire [BANK_BITS-1:0] selected_bank=wr_count==0?wr_head:wr_bank;
 wire overload=sample_clipped;
 wire [31:0] word_data={sample_q,sample_i};
 function automatic [31:0] crc_word(input [31:0] c,w);
  reg [31:0] v;integer k;begin v=c^w;
   for(k=0;k<32;k=k+1)v=(v>>1)^(v[0]?32'hedb88320:0);
   crc_word=v;
  end
 endfunction
 wire [31:0] next_crc=crc_word(crc_acc,word_data);
 wire [63:0] start_index={22'b0,seqno[rd_bank],10'b0};
 wire [511:0] header={32'h52464951,8'd1,8'd1,16'd64,stream_l,capture_l,
  seqno[rd_bank],14'b0,frag,16'd4,start_index,lo_l,fs_l,32'd0,
  16'd256,winflags[rd_bank],gain_l,crc[{rd_bank,frag}],32'd0};
 wire [10:0] ahead_pos=pos+((valid&&ready)?11'd1:11'd0);
 wire [7:0] ahead_word=ahead_pos<64?8'd0:(ahead_pos-11'd64)>>2;
 reg [31:0] read_word;
 always @(posedge clk)begin
  if(run&&!start&&sample_valid&&!selected_skip)iq[{selected_bank,wr_count}]<=word_data;
  read_word<=iq[{rd_bank,frag,ahead_word}];
 end
 assign data=pos<64?header[511-8*pos[5:0]-:8]:(read_word>>(8*pos[1:0]));
 assign hdr_valid=active&&!payload;
 assign valid=active&&payload;
 assign last=pos==1087;
 assign idle=!active&&!(|full)&&!run;
 reg [BANK_BITS:0] count_full;
 always @*begin
  count_full=0;for(integer a=0;a<BANKS;a=a+1)count_full=count_full+full[a];
 end
 assign fifo_points=count_full*1024;
 assign occupied=count_full==0?0:(count_full>=3?3:count_full[1:0]);
 always @(posedge clk)begin
  if(rst)begin
   full<=0;wr_count<=0;wr_bank<=0;wr_head<=0;rd_bank<=0;rd_head<=0;
   skip<=0;clipped<=0;gap<=0;active<=0;payload<=0;was_run<=0;
   sequence_num<=0;crc_acc<=32'hffffffff;frag<=0;pos<=0;
   samples<=0;datagrams<=0;dropped<=0;
   stream_l<=0;capture_l<=0;fs_l<=0;gain_l<=0;lo_l<=0;
  end else begin
   was_run<=run;
   if(start)begin
    // Controller must wait for idle before another START.
    full<=0;wr_count<=0;wr_head<=0;rd_head<=0;sequence_num<=0;
    crc_acc<=32'hffffffff;gap<=0;clipped<=0;skip<=0;
    samples<=0;datagrams<=0;dropped<=0;
    stream_l<=stream_id;capture_l<=capture_id;fs_l<=fs_hz;gain_l<=gain_mdb;lo_l<=lo_hz;
   end else if(run&&sample_valid)begin
    samples<=samples+1;wr_count<=wr_count+1;
    if(wr_count==0)begin wr_bank<=wr_head;skip<=full[wr_head];clipped<=overload;end
    else clipped<=clipped|overload;
    if(!selected_skip)begin
     crc_acc<=next_crc;
     if(wr_count[7:0]==255)begin crc[{selected_bank,wr_count[9:8]}]<=~next_crc;crc_acc<=32'hffffffff;end
    end
    if(wr_count==1023)begin
     sequence_num<=sequence_num+1;
     if(selected_skip)begin dropped<=dropped+1;gap<=1;end
     else begin
      full[selected_bank]<=1;seqno[selected_bank]<=sequence_num;wr_head<=wr_head+1;
      winflags[selected_bank]<={13'b0,(clipped|overload),(sequence_num==0),gap};gap<=0;
     end
    end
   end else if(!run)begin wr_count<=0;crc_acc<=32'hffffffff;end
   if(!active&&full[rd_head])begin active<=1;rd_bank<=rd_head;frag<=0;pos<=0;payload<=0;end
   if(hdr_valid&&hdr_ready)payload<=1;
   if(valid&&ready)begin
    if(last)begin
     datagrams<=datagrams+1;payload<=0;pos<=0;frag<=frag+1;
     if(frag==3)begin active<=0;full[rd_bank]<=0;rd_head<=rd_head+1;end
    end else pos<=pos+1;
   end
  end
 end
endmodule
