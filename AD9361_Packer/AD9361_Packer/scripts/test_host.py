from pathlib import Path
import sys,tempfile,struct,zlib,json
R=Path(__file__).resolve().parents[1];sys.path.insert(0,str(R/'host'))
from ku5p import Recorder,INDEX,Ids,unpack_response,unpack_tx,pack_request,RadioError
from rf_protocol import fragment_window,Snapshot,ControlMessage
from waveform_config import WaveformConfig
with tempfile.TemporaryDirectory() as td:
    path=Path(td)/'test'
    rec=Recorder(path,7,25000000,2400000000,depth=2)
    raw=struct.pack('<2048h',*range(-1024,1024))
    def packets(seq):return fragment_window(raw,capture_id=7,window_seq=seq,sample_index=seq*1024,fs_eff_hz=25000000,lo_hz=2400000000)
    for k in (3,1,0,2):rec.feed(packets(0)[k],('192.168.10.2',40000),'192.168.10.2')
    rec.feed(packets(0)[0],('192.168.10.2',40000),'192.168.10.2')
    # Window 1 is incomplete, window 2 corrupt, window 3 is intact.
    for p in packets(1)[:2]:rec.feed(p,('192.168.10.2',40000),'192.168.10.2')
    for p in packets(2):
        bad=p[:-1]+bytes([p[-1]^1]);rec.feed(bad,('192.168.10.2',40000),'192.168.10.2')
    for p in packets(3):rec.feed(p,('192.168.10.2',40000),'192.168.10.2')
    rec.close()
    assert path.with_suffix('.iq').read_bytes()==raw*2
    index=path.with_suffix('.index.bin').read_bytes()
    first=INDEX.unpack_from(index);second=INDEX.unpack_from(index,INDEX.size)
    assert (first[0],second[0],second[2],second[3])==(0,3,3072,4096)
    assert rec.stats['bad_crc']==4 and rec.stats['missing_or_conflicting_windows']==2
    ids=Ids(Path(td)/'ids.db');assert ids.reserve('request')==1;assert ids.reserve('request',128)==129;ids.close()
    ids=Ids(Path(td)/'ids.db');assert ids.reserve('request')==130;ids.close()
    for mode in ('AM','FM',*[f'{n}{m}' for n in (2,4,8,16) for m in ('ASK','FSK','PSK')]):
        assert len(WaveformConfig(modulation=mode).plan()['registers'])==16
    # Responses produced by the actual controller RTL are decoded by the CLI.
    lines=(R/'reports/controller/responses.hex').read_text().splitlines()
    for line in lines:
        h,b=unpack_response(bytes.fromhex(line))
        if h[1]==2:unpack_tx(b)
        elif h[6]==6:assert len(b)==32   # GET_RX_INFO discovery body
        else:Snapshot.unpack(b)
report=R/'reports/host';report.mkdir(exist_ok=True)
(report/'result.json').write_text(json.dumps({'passed':True,'gap_index':True,'crc_rejection':True,'durable_ids':True,'RTL_response_decode':True,'hardware_verified':False},indent=2))
print('HOST CHECKS PASSED')
