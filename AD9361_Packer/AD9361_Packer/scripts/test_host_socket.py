"""Real localhost UDP sockets: both clients discover IDs after another controller."""
from pathlib import Path
import sys,socket,threading,tempfile,struct,zlib,json
R=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(R/'host'),r'D:\FPGA_programs\FPAI_30T\ps\system']
from ku5p import Client,H
from rf_protocol import Snapshot
from control import ControlClient,IdStore
class Peer:
    def __init__(self):
        self.s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
        self.s.bind(('127.0.0.2',0));self.s.settimeout(.05)
        self.stop=threading.Event();self.high=500;self.cache={};self.wires=[];self.errors=[]
        self.drop=True;self.t=threading.Thread(target=self.run);self.t.start()
    def run(self):
        try:
            while not self.stop.is_set():
                try:p,a=self.s.recvfrom(2048)
                except socket.timeout:continue
                self.wires.append(p);h=H.unpack_from(p)
                assert h[10]==zlib.crc32(p[:28]+bytes(4)+p[32:])
                if p in self.cache:r=self.cache[p]
                else:
                    status=11 if h[4]<=self.high else 0
                    if not status:self.high=h[4]
                    if h[1]==2:
                        b=bytearray(128);struct.pack_into('>I',b,0,1)
                        struct.pack_into('>II',b,120,self.high,99)
                    else:b=Snapshot(status_flags=7).pack()
                    r=H.pack(b'RFCT',h[1],1,32,h[4],h[5],h[6],status,len(b),42,0)+b
                    r=r[:28]+struct.pack('>I',zlib.crc32(r))+r[32:]
                    self.cache[p]=r
                if self.drop:self.drop=False;continue
                # A bad CRC must never be accepted as the response.
                self.s.sendto(r[:-1]+bytes([r[-1]^1]),a);self.s.sendto(r,a)
        except BaseException as exc:self.errors.append(exc)
    def close(self):
        self.stop.set();self.t.join();self.s.close()
        if self.errors:raise self.errors[0]
with tempfile.TemporaryDirectory() as td:
    peer=Peer()
    try:
        c=Client('127.0.0.1','127.0.0.2',Path(td)/'pc',port=peer.s.getsockname()[1],timeout=.02,retries=2)
        try:
            tx=c.discover();assert tx['capture_high']==99 and c.boot==42
            assert c.request(5).status_flags==7
            assert peer.wires[0]==peer.wires[1]
        finally:c.close()
        with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as s:
            s.bind(('127.0.0.1',0));ids=IdStore(Path(td)/'wujing')
            try:
                c=ControlClient(s,peer.s.getsockname(),ids,interval=.02,retries=2)
                c.discover_ku5p()
                assert c.boot==42 and c.capture_floor==99
                assert c.request(5).status_flags==7
                assert ids.reserve('capture',c.capture_floor)==100
            finally:ids.close()
    finally:peer.close()
out=R/'reports/host_socket';out.mkdir(exist_ok=True)
(out/'result.json').write_text(json.dumps(dict(passed=True,real_localhost_UDP=True,PC_to_wujing_controller_switch=True,identical_retries=True,CRC_rejection=True,hardware_verified=False),indent=2))
print('HOST SOCKET CHECKS PASSED')
