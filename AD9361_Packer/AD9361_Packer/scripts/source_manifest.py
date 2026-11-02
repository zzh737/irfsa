"""Select only instantiated vendor modules; no CPU or unrelated reference designs."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
def design_sources(tops):
    pool=list((R/'rtl').glob('*.sv'))+list((R/'rtl').glob('*.v'))
    pool+=list((R/'vendor/verilog-ethernet/rtl').glob('*.v'))
    pool=[p for p in pool if p.name not in ('iddr.v','oddr.v','ssio_ddr_in.v')]
    pool+=list((R/'vendor/verilog-ethernet/lib/axis/rtl').glob('*.v'))
    pool+=[R/'vendor/verilog-ethernet/example/VCU118/fpga_1g/rtl/mdio_master.v']
    modules={};texts={}
    for p in pool:
        s=re.sub(r'/\*.*?\*/|//[^\n]*','',p.read_text(),flags=re.S)
        texts[p]=s
        for m in re.findall(r'\bmodule\s+(\w+)',s):modules[m]=p
    selected=set();pending=list(tops)
    while pending:
        m=pending.pop()
        if m not in modules:continue # Xilinx primitives resolve from UNISIM
        p=modules[m]
        if p in selected:continue
        selected.add(p)
        for dep in modules:
            if re.search(r'\b'+dep+r'\s*(?:#\s*\(|\w+\s*\()',texts[p]):pending.append(dep)
    return sorted(selected)
