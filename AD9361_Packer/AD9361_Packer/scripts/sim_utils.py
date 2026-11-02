"""Batch XSIM helpers. A nonzero exit or HDL fatal always fails the test."""
from pathlib import Path
import subprocess, shutil
R=Path(__file__).resolve().parents[1]
B=Path(r'D:\Xilinx\2025.2\Vivado\bin')
def run_sim(name, tb, sources, top=None, unisim=False):
    out=R/'reports'/name;out.mkdir(parents=True,exist_ok=True)
    top=top or ('tb_'+name)
    if unisim:sources=[*sources,B.parent/'data/verilog/src/glbl.v']
    (out/(top+'.sv')).write_text(tb.replace('~timescale',chr(96)+'timescale'),encoding='utf-8')
    for p in (R/'rtl/rom').glob('*.mem'):shutil.copyfile(p,out/p.name)
    (out/'sources.prj').write_text('\n'.join('sv work "'+str(p).replace('\\','/')+'"' for p in [*sources,out/(top+'.sv')])+'\n',encoding='utf-8')
    commands=[('xvlog',['-prj','sources.prj']),
              ('xelab',[top,*(['glbl'] if unisim else []),'-s','test_snapshot',*(['-L','unisims_ver'] if unisim else [])]),
              ('xsim',['test_snapshot','-runall'])]
    for tool,args in commands:
        log=out/(tool+'.log')
        with log.open('w') as f:
            p=subprocess.run([str(B/(tool+'.bat')),*map(str,args)],cwd=out,stdout=f,stderr=subprocess.STDOUT,timeout=600)
        s=log.read_text(errors='replace')
        if p.returncode or 'Fatal:' in s or 'FATAL' in s or 'ERROR:' in s or 'cannot be opened for reading' in s:raise RuntimeError(s[-12000:])
    print(s[-1200:]);return out

