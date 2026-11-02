"""Effectful commands keep replay protection for their latest ID; superseded slots
are reused, so a long command burst never fills the 256-slot cache (HW22).
Read queries never occupy a slot."""
from sim_utils import *
from source_manifest import design_sources
import sys,json
sys.path.insert(0,str(R/'host'))
from rf_protocol import ControlMessage,RFConfig,decode_control
rf=RFConfig(2400000000,25000000,20000000,10000,0,0).pack()
# 600 effectful commands well inside the 60 s retention: HW21 answered BUSY from #129.
N=600
requests=[ControlMessage(0,rid,1,1,0,42,rf).pack() for rid in range(1,N+1)]
queries=[ControlMessage(0,rid,0,5,0,42).pack() for rid in range(N+100,N+260)]
blocks=[]
def send(packet,count):
    return f'''@(negedge clk);cmd=1024'h{packet.ljust(128,bytes(1)).hex()};cl={len(packet)};cv=1;
 do @(posedge clk);while(!cr);@(negedge clk);cv=0;wait(responses=={count});'''
for n,p in enumerate(requests,1):blocks.append(send(p,n))
blocks.append(f'if(dut.request_high!={N}||dut.seconds>=60)$fatal(1,"burst state");')
for n,p in enumerate(queries,N+1):blocks.append(send(p,n))
blocks.append(send(requests[-1],N+161))   # latest ID: exact replay
blocks.append(send(requests[0],N+162))    # superseded ID: stale (11)
blocks.append(send(requests[-1],N+163))   # latest slot still live
tb=r'''~timescale 1ns/1ps
module tb_cache;
reg clk=0;always #4 clk=~clk;reg rst=1,cv=0;reg [1023:0] cmd;reg [15:0] cl;wire cr;
wire hv,v,last;wire [15:0] len;wire [7:0] d;
rfct_controller #(.CLOCK_HZ(10000000)) dut(
 .clk(clk),.rst(rst),.boot_id(32'd42),.link_up(1'b1),
 .command_uart(1'b0),.command_valid(cv),.command_ready(cr),.command_bytes(cmd),.command_length(cl),
 .hdr_valid(hv),.hdr_ready(1'b1),.reply_length(len),.data(d),.valid(v),.ready(1'b1),.last(last),
 .radio_ready(1'b1),.radio_fault(1'b0),.radio_busy(1'b0),.radio_done(1'b0),.applied_mask(2'd0),.radio_fault_index(16'd0),.quad_warn(1'b0),.quad_mode(2'd0),
 .dsp_ack(1'b0),.packet_idle(1'b1),.fifo_points(32'd0),.sample_count(64'd0),.datagrams(64'd0),.drop_windows(64'd0),.overflow_events(64'd0),
 .clip_count1(32'd0),.clip_count2(32'd0),.data_fault(1'b0));
integer f,responses=0;
always @(posedge clk)if(v)begin $fwrite(f,"%02x",d);if(last)begin $fwrite(f,"\n");responses=responses+1;end end
initial begin
 f=$fopen("responses.hex","w");repeat(5)@(negedge clk);rst=0;
'''+''.join(blocks)+r'''
 $fclose(f);$display("CACHE CHECKS PASSED");$finish;
end
initial begin #200000000;$fatal(1,"cache timeout responses=%d",responses);end
endmodule'''
out=run_sim('cache',tb,design_sources(['rfct_controller']))
p=[bytes.fromhex(x) for x in (out/'responses.hex').read_text().splitlines()]
statuses=[decode_control(x).status for x in p]
assert len(p)==N+163 and statuses[:N]==[0]*N,sorted(set(statuses[:N]))
assert statuses[N:N+160]==[0]*160
assert p[N-1]==p[N+160]==p[N+162] and statuses[N+161]==11,statuses[N+160:]
(out/'result.json').write_text(json.dumps(dict(passed=True,cache_slots=256,commands_without_busy=N,
    queries_without_cache_slots=160,latest_id_exact_replay=True,superseded_id_stale=True,
    hardware_verified=False),indent=2))
