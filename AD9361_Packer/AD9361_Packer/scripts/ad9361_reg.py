"""Bench-only AD9361 register access over UART (RFCT v2 0x105, firmware 16 only;
firmware 17+ builds lock it with REG_DEBUG=0 and reply UNSUPPORTED).

  python scripts/ad9361_reg.py read 0x007
  python scripts/ad9361_reg.py write 0x007 0x0a

One SPI transaction per command; the board accepts it only while RF is ready
and idle. A wrong write can misconfigure the radio: a board reset (or any TX
0x100 apply) restores the init script values. Not exposed in the GUI.
"""
from pathlib import Path
import argparse,struct,sys

R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R.parent/'operate'))
import backend  # noqa: F401  (sets operate/core and vendor import paths)
from radio_links import UARTClient
from ku5p import RadioError

OPCODE=0x105


def access(client,address,write=False,value=0):
    """Return the register value (read) or the value written (write)."""
    if not 0<=address<=0x3ff or not 0<=value<=0xff:raise ValueError('address 0..0x3ff, value 0..0xff')
    status,body=client.exchange(2,OPCODE,struct.pack('>HBB',address,int(write),value))
    if status:raise RadioError(f'RFCT 0x105 status {status}')
    word=struct.unpack_from('>I',body,0)[0]
    if word>>24!=0x52 or (word>>8)&0x3ff!=address or bool(word&(1<<23))!=bool(write):
        raise RadioError(f'unexpected 0x105 result 0x{word:08x}')
    return word&0xff


# UARTClient.exchange whitelists opcodes; 0x105 is added only for this tool.
class BenchUART(UARTClient):
    def exchange(self,version,op,body=b'',config=0,discover=False,floor=0):
        if op!=OPCODE:return super().exchange(version,op,body,config,discover,floor)
        return _raw_exchange(self,version,op,body,config)


def _raw_exchange(self,version,op,body,config):
    import time
    from ku5p import pack_request,unpack_response
    rid=self.ids.reserve('request')
    packet=pack_request(2,rid,config,op,self.boot,body)
    for _ in range(self.retries+1):
        self.serial.write(packet);deadline=time.monotonic()+self.timeout
        while time.monotonic()<deadline:
            for response in self.frames(self.serial.read(min(4096,max(1,self.serial.in_waiting)))):
                h,payload=unpack_response(response)
                if (h[4],h[5],h[6])!=(rid,config,op):continue
                if h[9]!=self.boot:raise RadioError('board restarted')
                return h[7],payload
    raise RadioError('no 0x105 reply (firmware < 16 or UART busy)')


def open_client(port='COM4',state=None):
    c=BenchUART(port,115200,state or R/'reports/ad9361_reg_ids.sqlite',timeout=.6,retries=2)
    c.discover()
    if (c.firmware_version or 0)<16:c.close();raise RadioError('firmware < 16: 0x105 not available')
    return c


def main():
    ap=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('op',choices=('read','write'));ap.add_argument('address',type=lambda s:int(s,0))
    ap.add_argument('value',nargs='?',type=lambda s:int(s,0),default=0);ap.add_argument('--port',default='COM4')
    a=ap.parse_args()
    c=open_client(a.port)
    try:print(f'0x{a.address:03x} = 0x{access(c,a.address,a.op=="write",a.value):02x}')
    finally:c.close()


if __name__=='__main__':main()
