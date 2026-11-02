"""Read-only UART snapshots timed near individual PHY address probes."""
import json,time
from read_hardware_diagnostics import R,UARTClient,diagnostics

c=UARTClient('COM4',115200,R/'reports/hardware_fix_20261024/uart_diagnostics_ids.sqlite',timeout=.6,retries=1)
rows=[]
try:
    c.discover();c.request(0x102,version=2)
    for address in (0,1,2,3):
        before=time.monotonic();d=diagnostics(c);p=d['phy']
        if p['state']!=15 or p['timer']<5000000:
            time.sleep(.06);before=time.monotonic();d=diagnostics(c);p=d['phy']
        if p['state']!=15:continue
        # Baseline and timed requests have the same serial instruction length.
        target=before+p['timer']/125000000+(address+1)*.000768
        delay=target-time.monotonic()
        if delay>.025:time.sleep(delay-.025)
        while time.monotonic()<target:pass
        sample=diagnostics(c)
        row=dict(target_address=address,phy=sample['phy'],mdio=sample['mdio_wire'])
        rows.append(row);print(json.dumps(row),flush=True)
except Exception as e:
    rows.append(dict(error=str(e)));print(type(e).__name__,str(e),flush=True)
finally:
    c.close()
    (R/'reports/hardware_fix_20261024/HW04_phy_timed.json').write_text(json.dumps(rows,indent=2))
