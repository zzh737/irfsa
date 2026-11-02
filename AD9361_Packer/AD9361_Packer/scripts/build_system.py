"""Build separately from the open GUI checkout."""
from source_manifest import *
from sim_utils import B
import subprocess,sys,json,hashlib,datetime
out=R/'build/ku5p_system';out.mkdir(parents=True,exist_ok=True)
report=R/'reports/system_build';report.mkdir(parents=True,exist_ok=True)
candidate=report/'ku5p_system_candidate.bit'
if candidate.exists():
    history=report/'history'/datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    history.mkdir(parents=True)
    candidate.rename(history/candidate.name)
sources=design_sources(['ku5p_top'])
for generator in ('generate_adc_cal.py','generate_radio_rom.py','generate_decimator.py','generate_dsp_roms.py'):
    subprocess.run([sys.executable,str(R/'scripts'/generator)],check=True,stdout=subprocess.DEVNULL)
(R/'scripts/system_sources.tcl').write_text('set ku5p_sources [list '+' '.join('{'+str(p).replace('\\','/')+'}' for p in sources)+']\n',encoding='utf-8')
(R/'scripts/system_sources.json').write_text(json.dumps([str(p.relative_to(R)) for p in sources],indent=2))
inputs=sources+list((R/'rtl/rom').glob('*.mem'))+list((R/'constraints').glob('ku5p_*.xdc'))+[R/'scripts'/n for n in ('ku5p_post_synth.tcl','ku5p_post_opt.tcl','ku5p_io_config.tcl','build_system.tcl','ku5p_pre_bitstream.tcl','ku5p_post_bitstream.tcl')]
input_hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
(report/'input_hashes.json').write_text(json.dumps(input_hashes,indent=2))
with (report/'build.log').open('w') as f:
    p=subprocess.run([str(B/'vivado.bat'),'-mode','batch','-source',str(R/'scripts/build_system.tcl'),
                      '-log',str(report/'vivado.log'),'-journal',str(report/'vivado.jou')],cwd=R,stdout=f,stderr=subprocess.STDOUT)
print((report/'build.log').read_text(errors='replace')[-5000:])
if p.returncode==0:
    if any(hashlib.sha256((R/f).read_bytes()).hexdigest()!=h for f,h in input_hashes.items()):
        raise RuntimeError('Design inputs changed during build; candidate is not releasable')
    subprocess.run([sys.executable,str(R/'scripts/release_manifest.py')],check=True)
sys.exit(p.returncode)
