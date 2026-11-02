// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Persistent, nonwrapping RFCT boot epoch. Reserves AT24C64D 0x1f00..0x1fff.
// Eight separate 32-byte pages. Existing unrelated data causes a closed fault.
// Never exposes an ID until its commit marker and all fields read back correctly.
module boot_journal #(parameter WRITE_WAIT=1250000)(
 input wire clk,rst,output reg ready,fault,output reg [31:0] boot_id,
 output reg io_start,io_write,output reg [12:0] io_address,output reg [7:0] io_data,
 input wire io_done,io_fault,input wire [7:0] io_read_data
);
 reg [4:0] state;reg [2:0] slot,max_slot,target;reg [4:0] pos;
 reg [135:0] entry;reg [31:0] highest,next_id,timer;
 function automatic [31:0] crc96(input [95:0] bits_in);
  reg [31:0] c;reg [7:0] b;integer j,k;
  begin c=32'hffffffff;
   for(j=0;j<12;j=j+1)begin b=bits_in[95-8*j-:8];c=c^b;
    for(k=0;k<8;k=k+1)c=(c>>1)^(c[0]?32'hedb88320:0);
   end
   crc96=~c;
  end
 endfunction
 wire [95:0] fields={32'h4b354249,next_id,~next_id};
 wire [135:0] new_entry={fields,crc96(fields),8'ha5};
 wire valid_entry=entry[135:104]==32'h4b354249 && entry[103:72]!=0 &&
  entry[71:40]==~entry[103:72] && entry[39:8]==crc96(entry[135:40]) && entry[7:0]==8'ha5;
 reg known_header;
 always @*begin
  known_header=1;
  for(integer j=0;j<4;j=j+1)
   if(entry[135-8*j-:8]!=8'hff && entry[135-8*j-:8]!=fields[95-8*j-:8])known_header=0;
 end
 task automatic fail;begin fault<=1;ready<=0;boot_id<=0;state<=31;end endtask
 task automatic issue(input bit wr,input [2:0] s,input [4:0] p,input [7:0] d);
  begin io_write<=wr;io_address<=13'h1f00+{s,5'b0}+p;io_data<=d;io_start<=1;end
 endtask
 always @(posedge clk)begin
  io_start<=0;
  if(rst)begin
   state<=0;ready<=0;fault<=0;boot_id<=0;slot<=0;max_slot<=7;target<=0;pos<=0;
   entry<=0;highest<=0;next_id<=0;timer<=0;io_write<=0;io_address<=0;io_data<=0;
  end else begin
   if(timer!=0)timer<=timer-1;
   case(state)
    0:begin issue(0,slot,pos,0);state<=1;end
    1:if(io_done)begin
     if(io_fault)fail();
     else begin entry[135-8*pos-:8]<=io_read_data;
      if(pos==16)state<=2;else begin pos<=pos+1;state<=0;end
     end
    end
    2:begin
     // A blank page is invalidated BEFORE its first header byte is written.
     // Losing power in that interval leaves FF body + 00 commit, a known
     // uncommitted page, not foreign data. Preserve all other content checks.
     if(!known_header || (entry[135:104]==32'hffffffff && entry[135:8]!=128'hffffffffffffffffffffffffffffffff) ||
        (!valid_entry && entry[7:0]!=0 && entry[7:0]!=8'hff))fail();
     else begin
      if(valid_entry&&entry[103:72]>highest)begin highest<=entry[103:72];max_slot<=slot;end
      if(slot==7)state<=3;else begin slot<=slot+1;pos<=0;state<=0;end
     end
    end
    3:if(highest==32'hffffffff)fail();
      else begin next_id<=highest+1;target<=max_slot+1;state<=4;end
    // Invalidate the old commit byte before replacing this page's contents.
    4:begin issue(1,target,16,0);state<=5;end
    5:if(io_done)begin if(io_fault)fail();else begin timer<=WRITE_WAIT;state<=6;end end
    6:if(timer==0)begin issue(0,target,16,0);state<=7;end
    7:if(io_done)begin
     if(io_fault||io_read_data!=0)fail();else begin pos<=0;state<=8;end
    end
    8:begin issue(1,target,pos,new_entry[135-8*pos-:8]);state<=9;end
    9:if(io_done)begin if(io_fault)fail();else begin timer<=WRITE_WAIT;state<=10;end end
    10:if(timer==0)begin if(pos==16)begin pos<=0;state<=11;end else begin pos<=pos+1;state<=8;end end
    11:begin issue(0,target,pos,0);state<=12;end
    12:if(io_done)begin
     if(io_fault||io_read_data!=new_entry[135-8*pos-:8])fail();
     else if(pos==16)begin boot_id<=next_id;ready<=1;state<=30;end
     else begin pos<=pos+1;state<=11;end
    end
    30:begin end
    31:begin end
    default:fail();
   endcase
  end
 end
endmodule
