"""Physical-unit planner for the pure-PL signal source. Standard library only."""
from dataclasses import dataclass,asdict
import math,json,argparse
MODES={'AM':0,'FM':1,**{f'{m}ASK':2 for m in (2,4,8,16)},
       **{f'{m}FSK':3 for m in (2,4,8,16)},**{f'{m}PSK':4 for m in (2,4,8,16)},
       **{f'{m}QAM':5 for m in (16,64,256)},'AM-DSB-WC':0,'AM-DSB-SC':6,
       'AM-SSB-SC':7,'AM-SSB-WC':8}
FS=25_000_000
def step(hz):return round(hz/FS*2**32)&0xffffffff
def rf_bandwidth(mod,baseband_hz):
    """RF occupancy of a one-sided baseband bandwidth: B for SSB, 2B otherwise."""
    return baseband_hz if MODES.get(mod) in (7,8) else 2*baseband_hz
def occupied_band(mod,baseband_hz,carrier_hz,sideband='USB'):
    """(low, high) relative to the TX LO. carrier_hz = TX1 offset = the carrier."""
    if MODES.get(mod) in (7,8):
        return (carrier_hz-baseband_hz,carrier_hz) if sideband=='LSB' else (carrier_hz,carrier_hz+baseband_hz)
    return (carrier_hz-baseband_hz,carrier_hz+baseband_hz)
@dataclass(frozen=True)
class WaveformConfig:
    modulation:str='QPSK'
    center_hz:int=2_400_000_000
    bandwidth_hz:int=1_000_000
    snr_db:float=10
    tx1_attenuation_db:float=20
    tx2_attenuation_db:float=30
    noise_low_hz:int=-500_000
    noise_high_hz:int=500_000
    seed:int=0x12345678
    tx1_offset_hz:int=0
    am_depth:float=.5
    sideband:str='USB'
    carrier_ratio_db:float=6
    tx1_noise:bool=True
    def plan(self):
        mod={'BPSK':'2PSK','QPSK':'4PSK','OOK':'2ASK'}.get(self.modulation.upper(),self.modulation.upper())
        if mod not in MODES:raise ValueError('unsupported modulation')
        if not 300_000_000<=self.center_hz<=6_000_000_000:raise ValueError('center must be 300 MHz..6 GHz')
        # Firmware >= 23: bandwidth_hz is the one-sided baseband bandwidth B for every
        # modulation. RF occupancy is 2B for double-sideband/IQ modes and B for SSB, so the
        # same B gives AM-DSB and AM-SSB the same message (DSB occupies twice as much).
        if not 5_000<=self.bandwidth_hz<=10_000_000:raise ValueError('baseband bandwidth must be 5 kHz..10 MHz')
        if not -10<=self.snr_db<=20:raise ValueError('digital SNR must be -10..20 dB')
        for a in (self.tx1_attenuation_db,self.tx2_attenuation_db):
            if not 0<=a<=89.75 or abs(a*4-round(a*4))>1e-8:raise ValueError('attenuation must be 0..89.75 dB in 0.25 dB steps')
        noise_bw=self.noise_high_hz-self.noise_low_hz
        if not 10_000<=noise_bw<=20_000_000:raise ValueError('noise bandwidth must be 10 kHz..20 MHz')
        # Reserve 2.5 MHz on each Nyquist edge at 25 MSPS; common analog BW=20 MHz.
        # Firmware >= 23: tx1_offset_hz (cfg[6]) is the carrier for every modulation.
        edges=occupied_band(mod,self.bandwidth_hz,self.tx1_offset_hz,self.sideband)
        if max(*(abs(e) for e in edges),abs(self.noise_low_hz),abs(self.noise_high_hz))>10_000_000:
            raise ValueError('the union of both TX bands must fit LO +/-10 MHz')
        if not 0<self.am_depth<=1:raise ValueError('AM depth must be (0,1]')
        if not 0<self.seed<2**32:raise ValueError('seed must be a nonzero u32')
        m=int(mod[:-3]) if mod.endswith(('ASK','FSK','PSK','QAM')) else 2
        ratio=10**(self.snr_db/10)
        # Keep total TX1 complex RMS fixed at 512 DAC codes before clipping.
        sig=512*math.sqrt(ratio/(1+ratio));noi=512/math.sqrt(2*(1+ratio))
        # TX1 internal noise off (firmware >= 18 honours cfg[11]=0): clean signal keeps 512 codes RMS.
        if not self.tx1_noise:sig,noi=512,0
        if MODES[mod]==0:sig/=math.sqrt(1+self.am_depth**2/2)
        if MODES[mod]==6:sig*=math.sqrt(2)
        if MODES[mod]==8:
            if not -30<=self.carrier_ratio_db<=40:raise ValueError('carrier/sideband power ratio must be -30..40 dB')
            sig/=math.sqrt(1+10**(self.carrier_ratio_db/10))
        if self.sideband not in ('USB','LSB'):raise ValueError('sideband must be USB or LSB')
        # rf = RF occupancy; the waveform formulas below were written in terms of it.
        rf=rf_bandwidth(mod,self.bandwidth_hz)
        rs=rf/(m+1) if MODES[mod]==3 else rf/1.35
        # AM tone at B: the highest message frequency equals the baseband bandwidth, so DSB
        # spans carrier±B and SSB carrier..carrier+B (USB) / carrier-B..carrier (LSB).
        message_hz=self.bandwidth_hz if MODES[mod] in (0,6,7,8) else rf/10
        regs=[MODES[mod],int(math.log2(m)),step(rs),step(message_hz),
              step(.4*rf),step(rs),step(self.tx1_offset_hz),
              step(rf/1.15),step(noise_bw/1.15),
              step((self.noise_low_hz+self.noise_high_hz)/2),
              round(sig*65536),round(noi*65536),round(512/math.sqrt(2)*65536),
              self.seed,round(self.am_depth*32768),step(-(m-1)*rs/2)]
        if MODES[mod] in (7,8):
            regs[14]=round(16384*math.sqrt(10**(self.carrier_ratio_db/10))) if MODES[mod]==8 else 0
            regs[15]=int(self.sideband=='LSB')
            # cfg[4] = signed carrier-to-sideband-centre step (+B/2 USB, -B/2 LSB). Firmware >= 23
            # puts the SSB carrier at cfg[6] and centres TX1 noise at cfg[6]+cfg[4] (the sideband).
            regs[4]=step(-self.bandwidth_hz/2 if self.sideband=='LSB' else self.bandwidth_hz/2)
        return {'registers':regs,'sample_rate_hz':FS,'modulation':mod,'symbol_rate_hz':rs,
                'baseband_bandwidth_hz':self.bandwidth_hz,'rf_bandwidth_hz':rf,'occupied_band_hz':edges,
                'tx1_snr_definition':'pre-DAC clean power / TX1 internal noise power, within configured band' if self.tx1_noise else 'TX1 internal noise disabled',
                'spectrum_definition':'bandwidth = one-sided baseband B; RF occupancy 2B (SSB: B). AM: tone at B/2; FM: Carson 2B; ASK/PSK: RRC beta .35; noise: RRC beta .15 edges',
                'requested':asdict(self),'absolute_power_calibrated':False}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--modulation',default='QPSK');p.add_argument('--bandwidth',type=int,default=1_000_000)
    p.add_argument('--snr',type=float,default=10);a=p.parse_args()
    print(json.dumps(WaveformConfig(modulation=a.modulation,bandwidth_hz=a.bandwidth,snr_db=a.snr).plan(),indent=2))
