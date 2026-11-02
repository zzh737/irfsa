"""Compare all eight compressed ADC/TIA profiles with the original ADI C.

Uses report-only C copies. Does not regenerate any implementation input.
"""
from pathlib import Path
import json, os, random, re, subprocess
from generate_rx_profiles import BANDWIDTHS, VARIABLE, divider
from generate_adc_cal import cal

R=Path(__file__).resolve().parents[1]
O=R/'reports/radio_oracle'
T=R/'reports/hw12_profiles';T.mkdir(exist_ok=True)
D=R/'vendor/no-os/drivers/rf-transceiver/ad9361'
source=(O/'ad9361_cal_oracle.c').read_text(encoding='utf-8')
source=source.replace('phy.rxbbf_div=7;', 'phy.rxbbf_div=atoi(getenv("PROFILE_DIV"));')
source=source.replace('ad9361_rx_tia_calib(&phy,10000000);', 'ad9361_rx_tia_calib(&phy,atoi(getenv("PROFILE_BW"))/2);')
(T/'cal_oracle.c').write_text(source,encoding='utf-8')
compiler=Path(r'D:\Xilinx\2025.2\win64\tools\vcxx\libexec\clang.exe')
env=dict(os.environ)
env['PATH']=str(compiler.parent)+os.pathsep+str(compiler.parent.parent/'x86_64-w64-mingw32/lib-dll')+os.pathsep+env['PATH']
files=[O/'oracle.c',T/'cal_oracle.c',R/'archive/softcore_prototype/firmware/ad9361_defaults.c',
       *[D/f for f in ('ad9361_api.c','ad9361_util.c','ad9361_ext_band_ctrl.c')],R/'vendor/no-os/util/no_os_util.c']
cmd=[str(compiler),'-DCAL_VERIFY','-fuse-ld=lld','-O1','-ffunction-sections','-fdata-sections','-Wl,--gc-sections',
     '-include',str(O/'app_config.h'),'-I'+str(O),'-I'+str(D),'-I'+str(R/'vendor/no-os/include'),
     *map(str,files),'-lm','-o',str(T/'oracle.exe')]
result=subprocess.run(cmd,env=env,capture_output=True,text=True)
(T/'compile.log').write_text(result.stdout+result.stderr)
result.check_returncode()
rng=random.Random(112)
triples=[(0,0,1),(63,127,7),(0,0,7),(63,127,1)]+[(rng.randrange(64),rng.randrange(128),rng.randrange(1,8)) for _ in range(60)]
rom=(R/'rtl/rom/rx_cal_profiles.mem').read_text().splitlines()
aliases={17:15,20:18,23:21,43:41,44:42}
constant=cal(4000);checked=0
for profile,bw in enumerate(BANDWIDTHS):
    p=subprocess.run([str(T/'oracle.exe')],input=''.join(f'{a} {b} {c}\n' for a,b,c in triples),
                     env=dict(env,PROFILE_DIV=str(divider(bw)),PROFILE_BW=str(bw)),text=True,capture_output=True,check=True)
    writes={};key=None
    for line in p.stdout.splitlines()+['CAL END']:
        if line.startswith('CAL'):
            if key is not None:
                a,b,c=key;product=c*(16*a+b+14)
                packed=int(rom[profile*8192+product],16)
                expected=[]
                for n in range(45):
                    k=aliases.get(n,n)
                    expected.append((packed>>(8*VARIABLE.index(k)))&255 if k in VARIABLE else
                                    (0xe0 if profile<5 else 0x60) if n==40 else constant[n])
                actual=[writes[x] for x in [*range(0x200,0x228),*range(0x1db,0x1e0)]]
                assert actual==expected,(profile,key,[(i,x,y) for i,(x,y) in enumerate(zip(actual,expected)) if x!=y])
                checked+=1
            key=tuple(map(int,line.split()[1:])) if line!='CAL END' else None;writes={}
        elif line.startswith('W'):
            _,a,v=line.split();writes[int(a,16)]=int(v,16)
result=dict(passed=True,profiles_hz=BANDWIDTHS,trim_cases=checked,coefficients_per_case=45,
            oracle='Original ADI ADC/TIA functions with selected divider/bandwidth',hardware_verified=False)
(T/'result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
