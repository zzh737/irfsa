from sim_utils import *
import json
tb=r'''~timescale 1ns/1ps
module tb_i2c;
reg clk=0;always #4 clk=~clk;
reg rst=1,start=0,wr=0;reg [12:0] addr;reg [7:0] wd;
wire done,fault,busy;wire [7:0] rd;tri1 scl,sda;
reg sl=0,dl=0;assign scl=sl?1'b0:1'bz;assign sda=dl?1'b0:1'bz;
eeprom_i2c #(.QUARTER(8)) dut(clk,rst,start,wr,addr,wd,done,fault,rd,busy,scl,sda);
task getbyte(output reg[7:0] v,input bit nack);
 integer k;begin
  for(k=7;k>=0;k=k-1)begin @(posedge scl);#1;v[k]=sda;end
  @(negedge scl);dl=!nack;
  // Stretch one ACK beyond the master's normal high-clock request.
  sl=1;#400;sl=0;@(posedge scl);@(negedge scl);dl=0;
 end
endtask
task start_seen;
 begin @(negedge sda);while(!scl)@(negedge sda);end
endtask
task putbyte(input reg[7:0] v);
 integer k;begin
  for(k=7;k>=0;k=k-1)begin dl=!v[k];@(posedge scl);@(negedge scl);end
  dl=0;@(posedge scl);#1;if(sda!==1)$fatal(1,"master must NACK final read byte");
  @(negedge scl);
 end
endtask
reg [7:0] v;integer transactions=0;
initial begin
 start_seen();getbyte(v,0);if(v!=8'ha0)$fatal(1,"device address");
 getbyte(v,0);if(v!=8'h1f)$fatal(1,"address high");
 getbyte(v,0);if(v!=8'h17)$fatal(1,"address low");
 getbyte(v,0);if(v!=8'h96)$fatal(1,"write data");
 @(posedge scl);@(posedge sda);if(!scl)$fatal(1,"STOP missing");transactions=transactions+1;
 start_seen();getbyte(v,0);if(v!=8'ha0)$fatal(1,"read prefix");
 getbyte(v,0);getbyte(v,0);
 start_seen();getbyte(v,0);if(v!=8'ha1)$fatal(1,"repeated START read address");
 putbyte(8'hb7);@(posedge sda);transactions=transactions+1;
 start_seen();getbyte(v,1);transactions=transactions+1;
end
task command(input bit w,input bit expect_fault);
 begin
 @(negedge clk);wr=w;addr=13'h1f17;wd=8'h96;start=1;
 @(negedge clk);start=0;wait(done);#1;
 if(fault!=expect_fault)$fatal(1,"fault expected=%d got=%d",expect_fault,fault);
 repeat(10)@(negedge clk);
 end
endtask
initial begin
 repeat(5)@(negedge clk);rst=0;command(1,0);command(0,0);
 if(rd!=8'hb7)$fatal(1,"read data=%h",rd);
 command(0,1);
 // Bus stuck low must time out and release both open-drain drivers.
 sl=1;command(0,1);sl=0;
 if(transactions!=3||dut.scl_low||dut.sda_low)$fatal(1,"release/transaction count");
 $display("I2C CHECKS PASSED");$finish;
end
initial begin #25000000;$fatal(1,"I2C timeout");end
endmodule'''
out=run_sim('i2c',tb,[R/'rtl/eeprom_i2c.sv'])
(out/'result.json').write_text(json.dumps(dict(passed=True,physical_wire_model=True,repeated_start=True,clock_stretch=True,nack=True,stuck_bus=True,hardware_verified=False),indent=2))
