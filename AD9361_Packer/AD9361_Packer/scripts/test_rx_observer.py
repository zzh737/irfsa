"""Check live, stalled and resumed frame evidence across unrelated clocks."""
from sim_utils import *
import json
tb=r'''~timescale 1ns/1ps
module tb_rx_observer;
reg data_clk=0,clk=0;always #5 data_clk=~data_clk;always #3.7 clk=~clk;
reg reset=1,rst=1;reg [1:0] frame=0;reg [1:0] phase=0;integer mode=0;
wire [31:0] trace,transitions;
ad9361_rx_observer dut(data_clk,reset,frame,clk,rst,trace,transitions);
always @(negedge data_clk)begin
 phase<=phase+1;
 case(mode)
  0:frame<=phase[1]?0:3;
  1:frame<=0;
  2:frame<=3;
  3:frame<=phase[0]?1:2;
 endcase
end
integer i;reg [31:0] before_count;
initial begin
 #210;reset=0;rst=0;
 #25000;
 if(transitions<1000)$fatal(1,"No live transitions");
 if(trace!=32'hf0f0f0f0&&trace!=32'h3c3c3c3c&&trace!=32'h0f0f0f0f&&trace!=32'hc3c3c3c3)
  $fatal(1,"Incoherent level frame trace %h",trace);
 mode=1;#25000;before_count=transitions;#15000;
 if(trace!=0||transitions!=before_count)$fatal(1,"Stalled low frame evidence");
 mode=2;#25000;
 if(trace!=32'hffffffff||transitions!=before_count+1)$fatal(1,"Stalled high frame evidence");
 mode=3;#25000;
 if(trace!=32'h66666666&&trace!=32'h99999999)$fatal(1,"Mixed edge trace %h",trace);
 if(transitions<before_count+1000)$fatal(1,"Resume not detected");
 // Data-domain reset alone must not leave the snapshot handshake stuck.
 reset=1;#120;reset=0;mode=1;#25000;
 if(trace!=0)$fatal(1,"Reset snapshot did not recover");
 mode=0;#25000;
 if(transitions<1000)$fatal(1,"Reset transition counter did not recover");
 $display("RX OBSERVER PASSED: live, held-low, held-high, mixed, reset, resume");$finish;
end
initial begin #250000;$fatal(1,"Observer timeout");end
endmodule'''
out=run_sim('rx_observer',tb,[R/'rtl/ad9361_rx_observer.sv'])
(out/'result.json').write_text(json.dumps(dict(passed=True,unrelated_clocks=True,
    coherent_frame_trace=True,stuck_low_high=True,reset_recovery=True,hardware_verified=False),indent=2))
