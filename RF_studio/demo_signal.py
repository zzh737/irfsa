"""Simplified, deterministic baseband examples, never an AD9361/RF simulation.

Digital symbols use rectangular holds (no RRC or receiver synchronization).
Configured SNR is applied before the illustrative receiver floor/TX2 noise.
"""
import cmath
import math
import random
import struct

MODEL='RECTANGULAR_BASEBAND_DEMO_V1'


class DemoSignal:
    def __init__(self,config,fs):
        self.config,self.fs=config,fs
        self.rng=random.Random(config.seed)
        self.symbol_rng=random.Random(config.seed ^ 0xA5A5A5A5)
        self.index=0;self.symbol_index=-1;self.symbol=0;self.phase=0
        self.mode=config.plan()['modulation']
        self.rs=config.plan()['symbol_rate_hz']

    def context(self,mask):
        return dict(model=MODEL,modulation=self.mode,tx1=bool(mask&1),tx2=bool(mask&2),
                    offset_hz=self.config.tx1_offset_hz,symbol_rate_hz=self.rs,
                    undersampled=self.config.bandwidth_hz+2*abs(self.config.tx1_offset_hz)>self.fs*.8)

    def window(self,mask):
        c=self.config;mode=self.mode
        ratio=10**(c.snr_db/10)
        amplitude=640*math.sqrt(ratio/(ratio+1))
        sigma=640/math.sqrt(2*(ratio+1))
        if not getattr(c,'tx1_noise',True):amplitude,sigma=640,0
        values=[]
        for _ in range(1024):
            t=self.index/self.fs
            if mode.startswith('AM') and mode not in ('AM','AM-DSB-WC'):
                message=2*math.pi*c.bandwidth_hz*t/2
                if mode=='AM-DSB-SC':clean=math.sqrt(2)*math.cos(message)
                else:
                    clean=cmath.exp(1j*message*(-1 if c.sideband=='LSB' else 1))
                    if mode=='AM-SSB-WC':
                        carrier=10**(c.carrier_ratio_db/20);clean=(clean+carrier)/math.sqrt(1+carrier*carrier)
            elif mode in ('AM','AM-DSB-WC','FM'):
                mode='AM' if mode=='AM-DSB-WC' else mode
                message=2*math.pi*(c.bandwidth_hz/(2 if mode=='AM' else 10))*t
                clean=((1+c.am_depth*math.cos(message))/math.sqrt(1+c.am_depth**2/2)
                       if mode=='AM' else cmath.exp(4j*math.sin(message)))
            else:
                order=int(mode[:-3])
                symbol_index=math.floor(self.index*self.rs/self.fs)
                if symbol_index!=self.symbol_index:
                    self.symbol=self.symbol_rng.randrange(order);self.symbol_index=symbol_index
                if mode.endswith('PSK'):
                    clean=cmath.exp(1j*(2*math.pi*self.symbol/order+math.pi/order))
                elif mode.endswith('QAM'):
                    side=int(math.sqrt(order));clean=complex(2*(self.symbol%side)-side+1,2*(self.symbol//side)-side+1)/math.sqrt(2*(order-1)/3)
                elif mode.endswith('ASK'):
                    # Nonnegative ASK levels, normalized to unit mean symbol power.
                    clean=self.symbol/math.sqrt((order-1)*(2*order-1)/6)
                else:
                    clean=cmath.exp(1j*self.phase)
                    self.phase=(self.phase+2*math.pi*(self.symbol-(order-1)/2)*self.rs/self.fs)%(2*math.pi)
            clean*=cmath.exp(2j*math.pi*c.tx1_offset_hz*t)
            # The background and TX2 here are illustrative white noise, not a channel model.
            noise=complex(self.rng.gauss(0,32),self.rng.gauss(0,32))
            if mask&1:
                noise+=amplitude*clean+complex(self.rng.gauss(0,sigma),self.rng.gauss(0,sigma))
            if mask&2:
                noise+=complex(self.rng.gauss(0,180),self.rng.gauss(0,180))
            values.extend(max(-2048,min(2047,round(v))) for v in (noise.real,noise.imag))
            self.index+=1
        return struct.pack('<2048h',*values)
