from sim_utils import *
from source_manifest import design_sources
import json
tb=r'''~timescale 1ns/1ps
module tb_data_interface;
reg clk=0;always #5 clk=~clk;
reg rst=1;reg [5:0] rise=0,fall=0;reg [1:0] frame=0;
wire rv,fe,st;wire [47:0] iq;wire [5:0] tr,tf;wire tframe;
reg [47:0] tx=48'hfedcba987654;reg tv=1;
ad9361_frame_core dut(clk,rst,rise,fall,frame,rv,iq,fe,tx,tv,st,tr,tf,tframe);
task slot(input [1:0] f,input [5:0] i,q);
 begin @(negedge clk);frame=f;fall=i;rise=q;end
endtask
integer count=0;reg [47:0] expected=48'hfedcba987654;
always @(posedge clk)begin #1;
 if(rv)begin if(iq!=expected)$fatal(1,"IQ lane/half ordering %h",iq);count=count+1;end
 if(!rst&&$time>100)begin
  case(dut.tx_phase)
   0:if(tf!=tx[11:6]||tr!=tx[23:18]||!tframe)$fatal;
   1:if(tf!=tx[5:0]||tr!=tx[17:12]||!tframe)$fatal;
   2:if(tf!=tx[35:30]||tr!=tx[47:42]||tframe)$fatal;
   3:if(tf!=tx[29:24]||tr!=tx[41:36]||tframe)$fatal;
  endcase
 end
end
initial begin
 repeat(5)@(negedge clk);rst=0;
 repeat(5)begin
  slot(3,expected[11:6],expected[23:18]);slot(3,expected[5:0],expected[17:12]);
  slot(0,expected[35:30],expected[47:42]);slot(0,expected[29:24],expected[41:36]);
 end
 slot(2,0,0);slot(0,0,0);
 repeat(5)begin
  slot(3,expected[11:6],expected[23:18]);slot(3,expected[5:0],expected[17:12]);
  slot(0,expected[35:30],expected[47:42]);slot(0,expected[29:24],expected[41:36]);
 end
 @(negedge clk);if(count<8)$fatal(1,"did not resynchronize");
 $display("DATA INTERFACE CHECKS PASSED");$finish;
end
initial begin #1000000;$fatal(1,"interface timeout");end
endmodule'''
out=run_sim('data_interface',tb,design_sources(['ad9361_frame_core']))
(out/'result.json').write_text(json.dumps({'passed':True,'iq_order':True,'resync':True,'hardware_verified':False},indent=2))
