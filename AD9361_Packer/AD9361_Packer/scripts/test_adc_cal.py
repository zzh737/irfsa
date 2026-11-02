from sim_utils import *
import random,json
rng=random.Random(20261023)
rom=bytes(int(x,16) for x in (R/'rtl/rom/adc_cal.mem').read_text().split())
cases=[(a,b,c,t) for a,b,c in [(0,0,1),(63,127,7),(20,50,3)]+[(rng.randrange(64),rng.randrange(128),rng.randrange(1,8)) for _ in range(30)] for t in (0,1)]
blocks=[]
for a,b,c,t in cases:
    product=c*(16*a+b+14)
    expected=rom[product*64:product*64+45]
    for i in range(45):blocks.append(f"expected[{i}]=8'h{expected[i]:02x};")
    blocks.append(f"run_case(8'd{a},8'd{b},8'd{c},1'b{t},0);")
for a,b,c in ((64,0,1),(0,128,1),(0,0,0),(0,0,8)):
    blocks.append(f"run_case(8'd{a},8'd{b},8'd{c},0,1);")
tb=r'''~timescale 1ns/1ps
module tb_adc_cal;
reg clk=0;always #4 clk=~clk;reg rst=1,start=0,tia=0;
wire done,fault,busy,ss,sw;wire [9:0] sa;wire [7:0] sd;reg ack=0;reg [7:0] rd=0;
reg [7:0] a,b,c,expected[0:44];integer writes=0,delay=0;
ad9361_adc_cal dut(clk,rst,start,tia,3'd7,done,fault,busy,ss,sw,sa,sd,ack,rd);
always @(posedge clk)begin
 ack<=0;
 if(ss)begin
  delay<=4;
  if(!sw)case(sa)
   10'h1eb:rd<=a;10'h1ec:rd<=b;10'h1e6:rd<=c;
   default:$fatal(1,"invalid trim address");
  endcase
  else begin
   if(sa!=(tia?(10'h1db+writes):(10'h200+writes)))$fatal(1,"calibration address");
   if(sd!==expected[writes+(tia?40:0)])$fatal(1,"calibration byte addr=%h got=%h",sa,sd);
   writes<=writes+1;
  end
 end
 if(delay>0)begin delay<=delay-1;if(delay==1)ack<=1;end
end
task run_case(input reg[7:0] aa,bb,cc,input bit tt,bad);
 begin
 @(negedge clk);a=aa;b=bb;c=cc;tia=tt;writes=0;start=1;
 @(negedge clk);start=0;wait(done);#1;
 if(fault!=bad||writes!=(bad?0:(tt?5:40)))$fatal(1,"ADC result fault=%d writes=%d",fault,writes);
 repeat(3)@(negedge clk);
 end
endtask
initial begin repeat(5)@(negedge clk);rst=0;
'''+''.join(blocks)+r'''
$display("ADC CAL CHECKS PASSED");$finish;end
initial begin #1000000;$fatal(1,"ADC test timeout");end
endmodule'''
out=run_sim('adc_cal',tb,[R/'rtl/ad9361_adc_cal.sv'])
(out/'result.json').write_text(json.dumps(dict(passed=True,valid_cases=len(cases),invalid_cases=4,hardware_verified=False),indent=2))
