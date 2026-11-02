"""KU5P pure-PL radio CLI. Python 3.10+, standard library only at runtime."""
from __future__ import annotations
import argparse,contextlib,json,os,select,socket,sqlite3,struct,time,zlib
from pathlib import Path
from dataclasses import asdict
from waveform_config import WaveformConfig
from rf_protocol import ControlMessage,RFConfig,StreamConfig,Snapshot,STATUSES
H=struct.Struct('>4sBBHIIHHIII')
TX_HEAD=struct.Struct('>IQiIIIHHIIIIii') # see unpack_tx: explicit offsets below
INDEX=struct.Struct('>IIQQIiHHI')
class RadioError(RuntimeError):pass
class RadioTimeout(RadioError):pass

def validate_rx_start(actual,config_id,capture_id,rf,fs):
    """Validate an acknowledged START; PHY management status is advisory.

    On HW06 the MDIO probe may fail while RGMII/UDP works. An authenticated
    CRC-checked RFCT response and matching live capture are control-path evidence;
    CRC-checked RFIQ windows establish whether usable data is being received.
    """
    wanted=dict(state=2,active_config_id=config_id,capture_id=capture_id,
        lo_hz=rf.lo_hz,adc_sample_rate_hz=rf.adc_sample_rate_hz,fs_eff_hz=fs,
        rx_bandwidth_hz=rf.rx_bandwidth_hz,rx_gain_mdB=rf.rx_gain_mdB if rf.gain_mode==0 else -2147483648)
    differences=[f'{key}={getattr(actual,key)} (expected {value})'
                 for key,value in wanted.items() if getattr(actual,key)!=value]
    # Bit 0: RF ready without fault. Bit 2: capture running. Bit 1: MDIO link.
    if actual.status_flags&5!=5:
        differences.append(f'status_flags=0x{actual.status_flags:04x} (RF_READY + RUNNING required)')
    if ((actual.status_flags>>3)&3)!=rf.gain_mode:differences.append('gain mode readback mismatch')
    if differences:raise RadioError('RX START 读回不匹配：'+'; '.join(differences))
    if not actual.status_flags&2:
        return 'MDIO 链路标志未就绪，但 UDP START 已应答；继续接收，以有效 IQ 数据为准。'
    return None

class Ids:
    def __init__(self,path):
        path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
        self.db=sqlite3.connect(path,timeout=10)
        self.db.execute('PRAGMA synchronous=FULL')
        self.db.execute('CREATE TABLE IF NOT EXISTS ids(name TEXT PRIMARY KEY,value INTEGER NOT NULL)')
        self.db.commit()
    def reserve(self,name,floor=0):
        with self.db:
            self.db.execute('BEGIN IMMEDIATE')
            row=self.db.execute('SELECT value FROM ids WHERE name=?',(name,)).fetchone()
            value=max(row[0] if row else 0,floor)+1
            if value>0xffffffff:raise RadioError(name+' ID exhausted; never wrap')
            self.db.execute('INSERT OR REPLACE INTO ids VALUES(?,?)',(name,value))
        return value
    def close(self):self.db.close()
    def align(self,name,floor):
        with self.db:
            self.db.execute('INSERT INTO ids VALUES(?,?) ON CONFLICT(name) DO UPDATE SET value=MAX(value,excluded.value)',(name,floor))
def pack_request(version,rid,config,opcode,boot,body=b''):
    p=H.pack(b'RFCT',version,0,32,rid,config,opcode,0,len(body),boot,0)+body
    return p[:28]+struct.pack('>I',zlib.crc32(p))+p[32:]
def unpack_response(packet):
    if len(packet)<32:raise RadioError('short response')
    h=H.unpack_from(packet)
    if h[:4]!=(b'RFCT',packet[4],1,32) or h[1] not in (1,2) or len(packet)!=32+h[8]:
        raise RadioError('invalid response header')
    startup_reply=(h[7]==8 or (h[7]==0 and
        ((h[1]==1 and h[6] in (5,6)) or (h[1]==2 and h[6] in (0x102,0x103,0x104)))))
    if h[9]==0 and not startup_reply:raise RadioError('invalid zero boot ID')
    if zlib.crc32(packet[:28]+bytes(4)+packet[32:])!=h[10]:raise RadioError('response CRC mismatch')
    expected=160 if h[1]==2 else (64 if h[6]==6 else 128)
    if len(packet)!=expected:raise RadioError('invalid response length')
    return h,packet[32:]
def unpack_tx(body):
    u32=lambda o:struct.unpack_from('>I',body,o)[0]
    i32=lambda o:struct.unpack_from('>i',body,o)[0]
    a,b=struct.unpack_from('>HH',body,28)
    regs=list(struct.unpack_from('>16I',body,56))
    mode=regs[0];order=1<<regs[1] if 1<=regs[1]<=8 else 0
    modulation=({0:'AM-DSB-WC',1:'FM'}.get(mode) if mode<2 else str(order)+{2:'ASK',3:'FSK',4:'PSK'}.get(mode,'UNKNOWN')) if regs[13] else None
    if mode==5:modulation=f'{order}QAM'
    if mode in (6,7,8):modulation={6:'AM-DSB-SC',7:'AM-SSB-SC',8:'AM-SSB-WC'}[mode]
    return dict(schema=u32(0),center_hz=struct.unpack_from('>Q',body,4)[0],
        bandwidth_hz=u32(12),snr_db=i32(16)/1000,requested_mask=u32(20),applied_mask=u32(24),
        attenuation1_db=a/4,attenuation2_db=b/4,radio_flags=u32(32),fault_index=u32(36),
        clip_count1=u32(40),clip_count2=u32(44),noise_low_hz=i32(48),noise_high_hz=i32(52),
        registers=regs,modulation=modulation,seed=regs[13],
        snr_definition='TX1 internal clean/noise power ratio before DAC; RX SNR unmeasured',
        request_high=u32(120),capture_high=u32(124))
class Client:
    def __init__(self,bind='192.168.10.1',peer='192.168.10.2',state=None,port=40001,timeout=.5,retries=12):
        self.peer=(peer,port);self.timeout=timeout;self.retries=retries;self.boot=0
        self.ids=Ids(state or Path(__file__).parent/'.ku5p_ids.sqlite')
        self.sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
        if hasattr(socket,'SO_EXCLUSIVEADDRUSE'):self.sock.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1)
        self.sock.bind((bind,port))
        self.sock.setblocking(False)
        self.pump=lambda:None
    def close(self):self.sock.close();self.ids.close()
    def exchange(self,version,op,body=b'',config=0,discover=False,floor=0):
        rid=self.ids.reserve('request',floor)
        packet=pack_request(version,rid,config,op,0 if discover else self.boot,body)
        for _ in range(self.retries+1):
            self.sock.sendto(packet,self.peer);deadline=time.monotonic()+self.timeout
            while time.monotonic()<deadline:
                self.pump()
                r,_,_=select.select([self.sock],[],[],.002)
                if not r:continue
                p,source=self.sock.recvfrom(2048)
                if source!=self.peer:continue
                try:h,payload=unpack_response(p)
                except RadioError:continue
                if (h[1],h[4],h[5],h[6])!=(version,rid,config,op):continue
                if not discover and (h[9]!=self.boot or h[7]==9):
                    raise RadioError('board restarted; capture invalid, reconnect and reconfigure')
                if discover:self.boot=h[9]
                return h[7],payload
        raise RadioTimeout(f'RFCT {op:#x} result unknown after identical retries')
    def discover(self):
        floor=0
        for _ in range(4):
            status,body=self.exchange(2,0x102,discover=True,floor=floor)
            tx=unpack_tx(body)
            if status==0:
                self.ids.align('request',tx['request_high'])
                self.ids.align('capture',tx['capture_high'])
                return tx
            if status not in (10,11):raise RadioError(STATUSES.get(status,str(status)))
            floor=tx['request_high']
        raise RadioError('could not synchronize request IDs with the peer')
    def request(self,op,body=b'',config=0,version=1):
        for _ in range(4):
            status,result=self.exchange(version,op,body,config)
            if status in (10,11):
                self.discover();continue # allocate a fresh ID after synchronization
            if status==6:
                time.sleep(.05);continue # business retry uses a fresh request ID
            if status:raise RadioError(f'RFCT {op:#x}: {STATUSES.get(status,status)}')
            return Snapshot.unpack(result) if version==1 else unpack_tx(result)
        raise RadioError('board remained busy or request IDs could not synchronize')
    def set_tx(self,c:WaveformConfig):
        p=c.plan();body=struct.pack('>QIiHHii16II',c.center_hz,c.bandwidth_hz,round(c.snr_db*1000),
            round(c.tx1_attenuation_db*4),round(c.tx2_attenuation_db*4),
            c.noise_low_hz,c.noise_high_hz,*p['registers'],0)
        result=self.request(0x100,body,version=2)
        if result['applied_mask'] or result['center_hz']!=c.center_hz or result['registers']!=p['registers']:
            raise RadioError('TX configuration readback mismatch')
        return result
    def enable(self,tx1=None,tx2=None):
        state=self.request(0x102,version=2);mask=state['applied_mask']
        if tx1 is not None:mask=(mask&~1)|int(tx1)
        if tx2 is not None:mask=(mask&~2)|(int(tx2)<<1)
        result=self.request(0x101,struct.pack('>I',mask),version=2)
        if result['applied_mask']!=mask:raise RadioError('TX channel readback mismatch')
        return result

class RXClient(Client):
    """RX-only v1 transport, with the board's high-water discovery extension."""
    def exchange(self,version,op,*args,**kwargs):
        if version!=1 or op not in (1,2,3,4,5,6):
            raise RadioError('RX Ethernet accepts only RFCT v1 RX commands; TX requires UART.')
        retries=self.retries
        try:
            # The board completes deferred RX operations within five seconds.
            if op in (3,4):self.retries=max(retries,int(6/self.timeout))
            return super().exchange(version,op,*args,**kwargs)
        finally:self.retries=retries

    def discover(self):
        floor=0
        for _ in range(4):
            status,body=self.exchange(1,6,discover=True,floor=floor)
            if len(body)!=32:raise RadioError('Invalid RX discovery response')
            schema,rid,cfg,capture,adc,bw,gain,modes=struct.unpack('>8I',body)
            self.firmware_version=(modes>>16) or None
            if schema!=1:raise RadioError('Unsupported RX discovery schema')
            if self.boot==0:raise RadioError('网口已应答，但 EEPROM 启动编号未就绪；请通过 UART 查看启动故障。')
            self.ids.align('request',rid)
            self.ids.align('config',cfg)
            self.ids.align('capture',capture)
            if status==0:
                return dict(request_high=rid,config_high=cfg,capture_high=capture,
                            adc_sample_rate_hz=adc,rx_bandwidth_hz=bw,rx_gain_mdB=gain,modes=modes,firmware_version=(modes>>16) or None)
            if status not in (10,11):raise RadioError(STATUSES.get(status,str(status)))
            floor=rid
        raise RadioError('Could not synchronize RX identifiers')

    def request(self,op,body=b'',config=0,version=1):
        if op not in (1,2,3,4,5) or version!=1:
            raise RadioError('Use RX discovery for opcode 6; TX requires UART.')
        return super().request(op,body,config,version)

    def set_tx(self,*args,**kwargs):raise RadioError('TX configuration requires UART.')
    def enable(self,*args,**kwargs):raise RadioError('TX switching requires UART.')


class Recorder:
    """Keep only complete, CRC-valid windows. Index preserves every sample gap."""
    reorder_timeout=.1
    # Set before the first packet to start at the first window that arrives instead of
    # window 0 (after a dead time that discarded the stream); earlier windows are no gap.
    join_stream=False
    def __init__(self,path,capture,fs,lo,depth=128):
        self.path=Path(path);self.path.parent.mkdir(parents=True,exist_ok=True)
        self.iq=self.path.with_suffix('.iq').open('xb',buffering=4*1024*1024)
        try:self.index=self.path.with_suffix('.index.bin').open('xb',buffering=1024*1024)
        except BaseException:self.iq.close();raise
        self.capture,self.fs,self.lo=capture,fs,lo;self.depth=depth
        self.pending={};self.next=0;self.highest=-1;self.offset=0;self.stats={}
        self.last_valid_at=None
    def count(self,key,n=1):self.stats[key]=self.stats.get(key,0)+n
    def feed(self,p,source,peer):
        self.count('udp_datagrams');self.count('udp_bytes',len(p))
        if source!=(peer,40000):self.count('wrong_peer');return
        if len(p)!=1088:self.count('bad_length');return
        h=struct.unpack_from('>4sBBHIIIHHQQIiHHiII',p)
        if h[:5]!=(b'RFIQ',1,1,64,1) or h[8]!=4 or h[13]!=256 or h[17]!=0 or h[14]&~15:
            self.count('bad_header_or_old_capture');return
        if h[5]!=self.capture:
            self.count('bad_header_or_old_capture');self.count('old_capture');return
        seq,frag,idx=h[6],h[7],h[9]
        if frag>3 or (not h[14]&8 and idx!=seq*1024) or h[10]!=self.lo or h[11]!=self.fs or h[12]!=0:
            self.count('wrong_metadata');return
        payload=p[64:]
        if zlib.crc32(payload)!=h[16]:self.count('bad_crc');return
        if self.join_stream:
            # Part of the first window seen may already be gone (discarded with the dead
            # time), whatever order its fragments arrive in: start at the next window.
            self.join_stream=False;self.next=seq+1;self.stats['joined_at_window']=seq+1
        if seq<self.next:self.count('late_or_duplicate');return
        self.last_valid_at=time.monotonic()
        self.highest=max(self.highest,seq);self.count('datagrams')
        meta=(h[9],h[10],h[11],h[12],h[14],h[15])
        entry=self.pending.get(seq)
        if entry is None:entry=[meta,[None]*4,time.monotonic(),False];self.pending[seq]=entry
        if entry[0]!=meta or (entry[1][frag] is not None and entry[1][frag]!=payload):
            entry[3]=True;self.count('conflict')
        entry[1][frag]=payload
        self.flush()
    def flush(self,force=False):
        while self.next<=self.highest:
            e=self.pending.get(self.next)
            if e and not e[3] and all(x is not None for x in e[1]):
                raw=b''.join(e[1]);meta=e[0]
                self.iq.write(raw)
                self.index.write(INDEX.pack(self.next,self.capture,meta[0],self.offset,self.fs,meta[5],meta[4],0,zlib.crc32(raw)))
                if hasattr(self,'accepted_window'):self.accepted_window(self.next,raw,meta)
                self.offset+=4096;self.pending.pop(self.next);self.next+=1;self.count('complete_windows')
            else:
                # A whole missing window has no entry of its own. Age it from
                # the packets waiting behind it, including a lost first window.
                oldest=e[2] if e else min((v[2] for v in self.pending.values()),default=time.monotonic())
                if not (force or self.highest-self.next>=self.depth or time.monotonic()-oldest>self.reorder_timeout):break
                if e:
                    self.pending.pop(self.next);self.next+=1;self.count('missing_or_conflicting_windows')
                else:
                    # Skip a whole empty range in one step. A sequence jump
                    # must not freeze the GUI or block the emergency command.
                    following=min((s for s in self.pending if s>self.next),default=self.highest+1)
                    self.count('missing_or_conflicting_windows',following-self.next);self.next=following
    def close(self):
        self.flush(force=True);self.iq.close();self.index.close()
def capture(client,args):
    # Open the IQ socket before START so the first window can be received.
    with contextlib.closing(socket.socket(socket.AF_INET,socket.SOCK_DGRAM)) as sock:
        sock.setsockopt(socket.SOL_SOCKET,socket.SO_RCVBUF,64*1024*1024)
        if hasattr(socket,'SO_EXCLUSIVEADDRUSE'):sock.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1)
        sock.bind((args.bind,40000));sock.setblocking(False)
        return _capture(client,args,sock)

def _capture(client,args,sock):
    info=client.discover()
    tx=None
    fs=25000000 if args.rate=='25m' else 1000000
    before=client.request(5)
    if before.state not in (0,4):raise RadioError('RX is owned by another session; stop it explicitly first')
    if before.state==4:client.request(4)
    center=args.center if args.center is not None else before.lo_hz or 2400000000
    config=client.ids.reserve('config',before.active_config_id)
    cid=client.ids.reserve('capture',max(before.capture_id,info['capture_high']))
    rec=Recorder(args.output,cid,fs,center)
    def pump():
        budget=time.monotonic()+.002
        for _ in range(256):
            try:p,source=sock.recvfrom(2048)
            except BlockingIOError:break
            rec.feed(p,source,client.peer[0])
            if time.monotonic()>=budget:break
    client.pump=pump
    metadata=dict(format='little-endian interleaved int16 I,Q; original ADC scale, no normalization',
        index_format='big-endian >IIQQIiHHI: window_seq,capture_id,sample_index,file_byte_offset,fs_hz,rx_gain_mdB,flags,reserved,window_crc32',
        index_record_bytes=INDEX.size,points_per_window=1024,capture_id=cid,boot_id=client.boot,
        fs_hz=fs,center_hz=center,rx_bandwidth_hz=20000000,rx_gain_mdB=10000,
        tx=tx,absolute_power_calibrated=False,hardware_validated_by_this_tool=False)
    configuration_attempted=False
    try:
        configuration_attempted=True
        client.request(1,RFConfig(center,25000000,20000000,10000,0,0).pack(),config)
        client.request(2,StreamConfig(1,fs,25000000//fs,0,1024,1024,0,0,0).pack(),config)
        actual=client.request(3,struct.pack('>I',cid),config)
        metadata['start_snapshot']=asdict(actual)
        warning=validate_rx_start(actual,config,cid,RFConfig(center,25000000,20000000,10000,0,0),fs)
        if warning:metadata['start_link_warning']=warning
        end=time.monotonic()+args.seconds;next_status=time.monotonic()+1
        while time.monotonic()<end:
            r,_,_=select.select([sock],[],[],.01)
            if r:pump()
            rec.flush()
            if time.monotonic()>=next_status:
                status=client.request(5)
                if status.state!=2 or status.capture_id!=cid:raise RadioError('capture stopped or radio failed')
                next_status=time.monotonic()+1
    except KeyboardInterrupt:metadata['interrupted']=True
    except BaseException as exc:metadata['error']=str(exc);raise
    finally:
        try:
            if configuration_attempted:
                state=client.request(5)
                if state.state not in (0,4) and state.capture_id!=cid:
                    raise RadioError('RX session changed; did not stop the replacement capture')
                metadata['stop_snapshot']=asdict(client.request(4))
                deadline=time.monotonic()+.15
                while time.monotonic()<deadline:pump();time.sleep(.001)
        finally:
            client.pump=lambda:None;rec.close()
            metadata['receiver_stats']=rec.stats
            metadata['file_bytes']=rec.offset
            Path(args.output).with_suffix('.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    return metadata
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--bind',default='192.168.10.1');p.add_argument('--peer',default='192.168.10.2')
    p.add_argument('--state',type=Path,default=Path(__file__).parent/'.ku5p_ids.sqlite')
    sub=p.add_subparsers(dest='command',required=True)
    sub.add_parser('status');sub.add_parser('stop')
    tx=sub.add_parser('tx-config')
    tx.add_argument('--mode',default='4PSK');tx.add_argument('--center',type=int,default=2400000000)
    tx.add_argument('--bandwidth',type=int,default=1000000);tx.add_argument('--snr',type=float,default=10)
    tx.add_argument('--atten1',type=float,default=20);tx.add_argument('--atten2',type=float,default=30)
    tx.add_argument('--noise-low',type=int,default=-500000);tx.add_argument('--noise-high',type=int,default=500000)
    tx.add_argument('--offset',type=int,default=0);tx.add_argument('--seed',type=lambda s:int(s,0),default=0x12345678)
    en=sub.add_parser('tx-enable');en.add_argument('--tx1',choices=['on','off']);en.add_argument('--tx2',choices=['on','off'])
    cap=sub.add_parser('capture');cap.add_argument('--seconds',type=float,default=10)
    cap.add_argument('--rate',choices=['25m','1m'],default='25m');cap.add_argument('--center',type=int)
    cap.add_argument('--output',type=Path,required=True)
    args=p.parse_args()
    if args.command=='capture' and args.seconds<=0:p.error('--seconds must be positive')
    if args.command=='tx-config':
        config=WaveformConfig(args.mode,args.center,args.bandwidth,args.snr,args.atten1,args.atten2,
            args.noise_low,args.noise_high,args.seed,args.offset)
        config.plan() # reject invalid settings before opening sockets
    if args.command in ('tx-config','tx-enable'):
        p.error('TX control uses UART. Use Radio Studio; no TX commands are sent over Ethernet.')
    with contextlib.closing(RXClient(args.bind,args.peer,args.state)) as client:
        info=client.discover()
        if args.command=='status':result={'rx':asdict(client.request(5)),'discovery':info}
        elif args.command=='stop':result=asdict(client.request(4))
        elif args.command=='tx-config':result=client.set_tx(config)
        elif args.command=='tx-enable':result=client.enable(None if args.tx1 is None else args.tx1=='on',None if args.tx2 is None else args.tx2=='on')
        else:result=capture(client,args)
        print(json.dumps(result,indent=2))
if __name__=='__main__':main()
