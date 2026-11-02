"""Separate UART TX control and RFCT v1 UDP RX control. Never send TX over UDP.

UART contract uses the matching FPGA image: RFCT v2 binary frames,
115200 8N1 fixed. Opening a COM handle is not a successful handshake.
"""
import sys
import time
import struct
from pathlib import Path

sys.path.insert(0,str(Path(__file__).resolve().parent/'vendor'))
import serial
from serial.tools import list_ports
from ku5p import Client, RXClient, Ids, RadioError, H, pack_request, unpack_response
from rf_protocol import Snapshot, STATUSES


def serial_ports():
    return [p.device for p in list_ports.comports()]


class UARTClient(Client):
    # Firmware 19 may run a TX retune up to its 60 s hard limit before replying.
    tx_apply_timeout=65.0
    def __init__(self,port,baud,state,timeout=.4,retries=2,serial_factory=None):
        if str(baud)!='115200':
            raise RadioError('UART 固定为 115200 / 8N1。')
        self.boot=0;self.timeout=timeout;self.retries=retries;self.pump=lambda:None
        self.ids=Ids(state);self.buffer=bytearray()
        try:
            self.serial=(serial_factory or serial.Serial)(port=port,baudrate=int(baud),
                bytesize=8,parity='N',stopbits=1,timeout=.005,write_timeout=.5,
                xonxoff=False,rtscts=False,dsrdtr=False)
        except BaseException:
            self.ids.close();raise

    def close(self):
        try:self.serial.close()
        finally:self.ids.close()

    def discover(self):
        result=super().discover()
        startup=None
        try:
            status,body=self.exchange(2,0x104)
            if status==0 and body[:4]==b'KU5P':
                result['firmware_version']=struct.unpack_from('>I',body,4)[0]
                startup=struct.unpack_from('>I',body,24)[0]
        except RadioError:pass
        if self.boot==0:
            detail=''
            if startup is not None:
                detail=(f"（日志故障={int(bool(startup&0x80000000))}，"
                        f"I²C故障={int(bool(startup&0x10000000))}，"
                        f"地址=0x{(startup>>8)&0x1fff:04X}，读值=0x{startup&255:02X}）")
            raise RadioError('UART 已应答，但 EEPROM 启动编号未就绪'+detail+'；板端暂不接受收发操作。')
        self.firmware_version=result.get('firmware_version')
        return result

    def request(self,*args,**kwargs):
        result=super().request(*args,**kwargs)
        if isinstance(result,dict):result['firmware_version']=getattr(self,'firmware_version',None)
        return result

    def set_tx(self,config):
        # The legacy Client expects SET_TX to clear both enables. This image
        # restores the previous enable mask after its live configuration.
        # Explicit fault recovery reinitializes RF with both transmitters off.
        before=self.request(0x102,version=2)
        plan=config.plan()
        body=struct.pack('>QIiHHii16II',config.center_hz,config.bandwidth_hz,
            round(config.snr_db*1000),round(config.tx1_attenuation_db*4),
            round(config.tx2_attenuation_db*4),config.noise_low_hz,
            config.noise_high_hz,*plan['registers'],0)
        result=self.request(0x100,body,version=2)
        expected=dict(center_hz=config.center_hz,bandwidth_hz=config.bandwidth_hz,
            snr_db=round(config.snr_db*1000)/1000,
            attenuation1_db=round(config.tx1_attenuation_db*4)/4,
            attenuation2_db=round(config.tx2_attenuation_db*4)/4,
            noise_low_hz=config.noise_low_hz,noise_high_hz=config.noise_high_hz,
            registers=plan['registers'],applied_mask=0 if before['radio_flags']&24 else before['applied_mask'])
        if any(result.get(key)!=value for key,value in expected.items()):
            raise RadioError('TX 参数或开关状态读回不匹配，请刷新板端状态。')
        return result

    def frames(self,data):
        self.buffer.extend(data)
        while True:
            start=self.buffer.find(b'RFCT')
            if start<0:
                self.buffer[:]=self.buffer[-3:];return
            if start:del self.buffer[:start]
            if len(self.buffer)<32:return
            h=H.unpack_from(self.buffer)
            if h[1:4]!=(2,1,32) or h[8]!=128:
                del self.buffer[0];continue
            size=32+h[8]
            if len(self.buffer)<size:return
            packet=bytes(self.buffer[:size])
            try:unpack_response(packet)
            except RadioError:
                del self.buffer[0];continue
            del self.buffer[:size]
            yield packet

    def exchange(self,version,op,body=b'',config=0,discover=False,floor=0):
        if version!=2 or op not in (0x100,0x101,0x102,0x104):
            raise RadioError('UART 仅允许 TX 配置、开关和状态命令；RX 使用网口。')
        rid=self.ids.reserve('request',floor)
        packet=pack_request(2,rid,config,op,0 if discover else self.boot,body)
        interval=max(.5,self.timeout) if op==0x100 else self.timeout
        attempts=max(self.retries+1,int(self.tx_apply_timeout/interval)+1) if op==0x100 else self.retries+1
        for _ in range(attempts):
            if self.serial.write(packet)!=len(packet):raise RadioError('UART 帧未完整发送，操作结果未确认。')
            deadline=time.monotonic()+interval
            while time.monotonic()<deadline:
                self.pump()
                data=self.serial.read(min(4096,max(1,self.serial.in_waiting)))
                for response in self.frames(data):
                    h,payload=unpack_response(response)
                    if (h[4],h[5],h[6])!=(rid,config,op):continue
                    if not discover and (h[9]!=self.boot or h[7]==9):
                        raise RadioError('UART 检测到开发板重启，请重新连接。')
                    if discover:self.boot=h[9]
                    return h[7],payload
        raise RadioError('UART 未收到匹配的 RFCT v2 应答。请检查 115200 8N1、配套位流及串口连接；操作结果尚未确认。')


def unknown_tx():
    return dict(center_hz=0,bandwidth_hz=0,snr_db=0,attenuation1_db=0,attenuation2_db=0,
                noise_low_hz=0,noise_high_hz=0,seed=0,registers=[0]*16,modulation=None,
                applied_mask=0,requested_mask=0,radio_flags=0,capture_high=0,request_high=0,
                available=False,source='UART_NOT_CONNECTED')


class SplitClient:
    """Adapter used by the existing recorder. Each operation has exactly one route."""
    def __init__(self):self.tx=None;self.rx=None
    @property
    def boot(self):return self.rx.boot if self.rx else self.tx.boot if self.tx else 0
    @property
    def ids(self):return self.rx.ids
    @property
    def sock(self):return self.rx.sock
    @property
    def peer(self):return self.rx.peer
    @property
    def pump(self):return self.rx.pump if self.rx else lambda:None
    @pump.setter
    def pump(self,value):
        if self.rx:self.rx.pump=value
        if self.tx:self.tx.pump=value
    def request(self,op,body=b'',config=0,version=1):
        if version==2:
            if not self.tx:
                if op==0x102:return unknown_tx()
                raise RadioError('请先完成 UART 协议连接。')
            return self.tx.request(op,body,config,version)
        if not self.rx:raise RadioError('请先完成网口 RX 协议握手。')
        return self.rx.request(op,body,config,version)
    def discover(self):
        if self.rx:return self.rx.discover()
        if self.tx:return self.tx.discover()
        raise RadioError('请先连接 UART 或网口 RX。')

    def set_tx(self,config):
        if not self.tx:raise RadioError('请先连接 UART。')
        return self.tx.set_tx(config)
    def enable(self,*args):
        if not self.tx:raise RadioError('UART 未连接，TX 停止结果无法确认。')
        return self.tx.enable(*args)
    def close(self):
        for link in (self.rx,self.tx):
            if link:link.close()
        self.tx=self.rx=None
