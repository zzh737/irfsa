from sim_utils import *
from source_manifest import design_sources
import json
tb=r'''~timescale 1ns/1ps
module tb_boot_journal;
reg clk=0;always #4 clk=~clk;
reg rst=1;wire ready,fault;wire [31:0] id;
wire go,wr;wire [12:0] addr;wire [7:0] data;
reg done=0,err=0;reg [7:0] rd;reg [7:0] memory[0:8191];reg [2:0] delay_count=0;
reg pending=0,pwr;reg [12:0] pa;reg [7:0] pd;
boot_journal #(.WRITE_WAIT(5)) dut(clk,rst,ready,fault,id,go,wr,addr,data,done,err,rd);
always @(posedge clk)begin
 done<=0;
 if(go)begin pending<=1;delay_count<=3;pwr<=wr;pa<=addr;pd<=data;end
 if(pending)begin
  if(delay_count!=0)delay_count<=delay_count-1;
  else begin
   pending<=0;done<=1;
   if(pwr)begin memory[pa]<=pd;rd<=0;end else rd<=memory[pa];
  end
 end
end
task reboot;
 begin @(negedge clk);rst=1;repeat(5)@(negedge clk);rst=0;wait(ready||fault);#1;end
endtask
integer j,k;integer saved;
initial begin
 for(j=0;j<8192;j=j+1)memory[j]=255;
 // First boot: cut power after invalidation, before any header byte.
 @(negedge clk);rst=1;repeat(5)@(negedge clk);rst=0;
 wait(dut.state==8&&dut.pos==0);@(negedge clk);rst=1;
 if(memory[13'h1f10]!=0||memory[13'h1f00]!=255)$fatal(1,"missing blank-page interruption");
 for(k=1;k<=20;k=k+1)begin reboot();if(fault||id!=k)$fatal(1,"boot epoch %d got %d",k,id);end
 // Power loss during body update burns no published ID.
 @(negedge clk);rst=1;repeat(5)@(negedge clk);rst=0;
 wait(dut.state==8&&dut.pos==6);@(negedge clk);rst=1;repeat(5)@(negedge clk);
 reboot();if(fault||id!=21)$fatal(1,"torn update recovery");
 // Corruption of a committed slot must never silently lower the epoch.
 memory[13'h1f00+12]=memory[13'h1f00+12]^1;
 reboot();if(!fault||id!=0)$fatal(1,"committed CRC corruption accepted");
 // Foreign contents are preserved and fault closed.
 for(j=0;j<8192;j=j+1)memory[j]=255;
 memory[13'h1f00]=8'h55;reboot();
 if(!fault||memory[13'h1f00]!=8'h55)$fatal(1,"foreign EEPROM data overwritten");
 $display("BOOT JOURNAL CHECKS PASSED");$finish;
end
initial begin #10000000;$fatal(1,"journal timeout");end
endmodule'''
out=run_sim('boot_journal',tb,design_sources(['boot_journal']))
(out/'result.json').write_text(json.dumps({'passed':True,'boots':21,'torn_write':True,'blank_page_invalidation_recovery':True,'corruption_fail_closed':True,'hardware_verified':False},indent=2))
