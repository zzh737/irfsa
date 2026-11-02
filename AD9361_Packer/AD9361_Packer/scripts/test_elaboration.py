from sim_utils import *
from source_manifest import design_sources
sources=design_sources(['ku5p_top'])
tb='''~timescale 1ns/1ps
module tb_elaboration;
reg sys=0, reset_n=0;
always #2.5 sys=~sys;
ku5p_top dut(.sys_clk_p(sys),.sys_clk_n(~sys),.reset_n(reset_n),.uart_rx(1'b1));
realtime t0,t1;
integer boot,k;
initial begin
 for(boot=0;boot<8;boot=boot+1) begin
  reset_n=0; #(101.137+boot*0.293); reset_n=1;
  wait(dut.locked && dut.tx_div_reset==0);
  repeat(4) @(posedge dut.tx_clk);
  for(k=0;k<16;k=k+1) begin
   @(posedge dut.tx_clk); t0=$realtime;
   @(posedge dut.tx_clk90); t1=$realtime;
   if(t1-t0<1.999 || t1-t0>2.001) $fatal(1,"TX phase %f",t1-t0);
   @(negedge dut.tx_clk);
   if($realtime-t0<3.999 || $realtime-t0>4.001) $fatal(1,"TX duty");
   @(negedge dut.tx_clk90);
   if($realtime-t0<5.999 || $realtime-t0>6.001) $fatal(1,"TX90 duty");
  end
 end
 $display("ELABORATION PASSED; TX DIVIDER PHASE PASSED 8 resets 128 cycles"); $finish;
end
initial begin #2000000; $fatal(1,"Clock startup timeout"); end
endmodule
'''
run_sim('elaboration',tb,sources,unisim=True)
