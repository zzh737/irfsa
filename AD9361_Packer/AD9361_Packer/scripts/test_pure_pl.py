"""Run real Vivado xsim simulations without changing the open GUI project."""
import pathlib, subprocess, shutil, json
R=pathlib.Path(__file__).resolve().parents[1]
BIN=pathlib.Path(r'D:\Xilinx\2025.2\Vivado\bin')
OUT=R/'reports'/'pure_pl_sim'
OUT.mkdir(parents=True,exist_ok=True)
for p in (R/'sim').glob('*.mem'):shutil.copy2(p,OUT/p.name)
def run(tool,args,log):
    with (OUT/log).open('w',encoding='utf-8') as f:
        p=subprocess.run([str(BIN/(tool+'.bat')),*map(str,args)],cwd=OUT,
                         stdout=f,stderr=subprocess.STDOUT)
    output=(OUT/log).read_text(encoding='utf-8',errors='replace')
    if p.returncode:raise RuntimeError(output)
    return output
run('xvlog',['--sv',R/'rtl/ad9361_spi.v',R/'rtl/ad9361_init_sequencer.sv',
             R/'rtl/iq_test_tone.sv',R/'sim/tb_pure_pl.sv'],'compile.log')
run('xelab',['tb_pure_pl','-s','pure_pl_tb'],'elaborate.log')
output=run('xsim',['pure_pl_tb','-runall'],'simulate.log')
if 'ALL PURE PL UNIT TESTS PASSED' not in output or 'Fatal' in output:raise RuntimeError(output)
print(output)
(OUT/'result.json').write_text(json.dumps({'passed':True,'tests':[
 'SPI CPHA1 frame length, command and readback','ROM write and masked read-modify-write',
 'poll/delay/timeout','tone period, orientation, hold, disable'],
 'board_verified':False},indent=2),encoding='utf-8')
