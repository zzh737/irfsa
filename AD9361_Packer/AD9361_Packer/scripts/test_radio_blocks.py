"""Exercise divider/PLL/trim calibration against ADI's original C calculations."""
from sim_utils import *
from source_manifest import design_sources
import random,json,os,re
# Restore the normal native driver oracle (the optional trim verification build
# uses the same executable name).
subprocess.run([__import__('sys').executable,str(R/'scripts/generate_radio_trace.py')],check=True,stdout=subprocess.DEVNULL)
cc=Path(r'D:\Xilinx\2025.2\win64\tools\vcxx')
env=dict(os.environ)
env['PATH']=str(cc/'libexec')+os.pathsep+str(cc/'x86_64-w64-mingw32/lib-dll')+os.pathsep+env['PATH']
rng=random.Random(49361)
hzs=[300000000,6000000000,1300000000,1300000002,4000000000,4000000002,2400000000]
hzs+=[rng.randrange(150000000,3000000001)*2 for _ in range(25)]
checks=[]
addresses=[0x27a,0x279,0x282,0x278,0x291,0x285,0x290,0x27b,0x27e,0x27f,0x280,0x273,0x274,0x275,0x272,0x271]
for fdd,hz in [(mode,hz) for mode in (0,1) for hz in hzs]:
    oracle_env=dict(env,ORACLE_LO=str(hz)) if not fdd else dict(env,
        ORACLE_LO=str(915000000 if hz==2400000000 else 2400000000),ORACLE_TX=str(hz))
    p=subprocess.run([str(R/'reports/radio_oracle/oracle.exe')],env=oracle_env,capture_output=True,text=True,check=True)
    regs={}
    for line in p.stdout.splitlines():
        words=line.split()
        if words and words[0] in ('W','M'):
            a=int(words[1],16);v=int(words[-1],16)
            regs[a]=v if words[0]=='W' else (regs.get(a,0)&~int(words[2],16))|v
    # Partial registers contain unrelated static bits; compare only PLL fields.
    masks=[255]*16;masks[1]=15;masks[7]=63;masks[14]=7
    expected=sum((regs[a]&masks[i])<<(8*i) for i,a in enumerate(addresses))
    expected|=(regs[5]&15)<<128;expected|=(regs[5]&240)<<136
    bitmask=sum(v<<(8*i) for i,v in enumerate(masks))|(255<<128)|(255<<136)
    if fdd:
        # Live TX writes only the high divider nibble of shared register 0x005.
        # Its low nibble must retain the independent RX divider.
        expected &= ~(255<<128)
        bitmask &= ~(255<<128)
    checks.append(f"""
    @(negedge clk);fdd={fdd};lo=64'd{hz};start=1;@(negedge clk);start=0;
    wait(done);#1;
    if(fault||(values&144'h{bitmask:036x})!=144'h{expected:036x})$fatal(1,"PLL mismatch FDD={fdd} LO={hz} actual=%h expected={expected:036x}",values);
    """)
tb='''~timescale 1ns/1ps
module tb_radio_blocks;
reg clk=0;always #4 clk=~clk;
reg rst=1,start=0,fdd=0;reg [63:0] lo;wire done,fault;wire [143:0] values;wire [1:0] band;
ad9361_frequency_plan dut(clk,rst,start,lo,fdd,done,fault,values,band);
initial begin repeat(5)@(negedge clk);rst=0;
'''+''.join(checks)+'''
@(negedge clk);lo=299999999;start=1;@(negedge clk);start=0;
wait(done);#1;if(!fault)$fatal(1,"invalid frequency accepted");
$display("PLL GOLDEN CHECKS PASSED");$finish;end
initial begin #10000000;$fatal(1,"PLL timeout");end
endmodule
'''
out=run_sim('radio_blocks',tb,design_sources(['ad9361_frequency_plan']))
(out/'result.json').write_text(json.dumps({'passed':True,'native_ADI_golden_frequencies':len(hzs),'TDD_cases':len(hzs),'FDD_cases':len(hzs),'hardware_verified':False},indent=2))
