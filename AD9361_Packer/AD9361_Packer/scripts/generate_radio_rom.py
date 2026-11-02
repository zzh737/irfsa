"""Convert the audited ADI trace to bounded PL transactions, not CPU code."""
from pathlib import Path
import re,json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'reports/radio_oracle';D=R/'rtl/rom'
def word(op,a=0,v=0,m=0,t=0):return op<<60|a<<48|v<<40|m<<32|t

# Read-only evidence at the end of explicit setup/retune. No periodic polling,
# test signal, delay adjustment, or ready/fault qualification uses these bytes.
interface_addresses=(0x003,0x006,0x007,0x010,0x011,0x012,0x013,0x014,
                     0x015,0x017,0x03d,0x03e,0x3f4,0x3f5,0x3f6,0x004)
interface_snapshot=[word(9,a,v=n) for n,a in enumerate(interface_addresses)]
# Runtime lock/ENSM checks: ADI's ad9361_check_cal_done allows ~600 ms for
# lock bits; a wide VCO jump failed the old 100 ms limit (HW18 item 3).
LIVE_CHECK=125000000
# A stale LOCK bit can still read 1 right after the new PLL words; let the
# synthesizer drop lock and re-lock before checking (HW18 R5).
LOCK_SETTLE=word(3,t=1000*125)
# Per-phase cal-done is 50 ms in ad9361_tune.sv; default + last + 32-phase
# search + final run is at most 35 runs, so the CALL needs a 3 s budget.
QUAD_CALL=word(5,v=2,t=375000000)
dynamic={0x23a:0,0x239:1,0x242:2,0x238:3,0x251:4,0x245:5,0x250:6,
         0x23b:7,0x23e:8,0x23f:9,0x240:10,0x233:11,0x234:12,0x235:13,0x232:14,0x231:15}
banks=[];manifests=[]
for hz in (300000000,2400000000,6000000000):
 lines=(O/f'trace_{hz}.txt').read_text(encoding='ascii').splitlines()
 program=[];quad_skip=False;reads=set()
 for line in lines:
  p=line.split()
  if not p:continue
  op=p[0]
  if quad_skip:
   if op=='R' and p[1]=='0a8':quad_skip=False
   continue
  if op=='W' and p[1]=='0a0':
   program.append(QUAD_CALL);quad_skip=True;continue
  if op=='R':
   a=int(p[1],16);reads.add(a)
   if a==0x037:program.append(word(2,a,8,0xf8,125000000))
  elif op in ('W','M'):
   a=int(p[1],16);m=int(p[2],16) if op=='M' else 255;v=int(p[-1],16)
   # Apply the fixed 2R2T channel count after digital-interface setup.
   if a==2 and op=='W' and v==0xdc:continue
   base=a if a<0x270 else a-0x40
   is_dynamic=base in dynamic and not(base in (0x239,0x23b) and op!='M')
   if is_dynamic:program.append(word(6 if op=='W' else 7,a,dynamic[base],m))
   elif a==5 and op=='M':program.append(word(7,a,16 if m==15 else 17,m))
   else:
    if a==0x016 and op=='W' and v==1:
     # Baseband DC calibration requires ALERT; verify the live ENSM state.
     program.append(word(2,0x017,5,15,300000000))
    program.append(word(1 if op=='W' else 4,a,v,m))
  elif op=='P':
   # ADI allows 20000 polls: calibration control may take 24 s.
   a=int(p[1],16)
   program.append(word(2,a,int(p[3],16),int(p[2],16),3000000000 if a==0x016 else 300000000))
  elif op=='D':program.append(word(3,t=int(p[1])*125))
  elif op=='ADC':
   assert list(map(int,p[1:]))==[800000000,200000000,7]
   program.append(word(5,v=0,t=125000000))
  elif op=='TIA':
   assert int(p[1])==10000000
   program.append(word(5,v=1,t=125000000))
 assert not quad_skip
 # FDD ready, fixed 2R2T paths, zero-IQ/max-attenuation TX mute at startup.
 program += [word(2,0x017,10,15,125000000),word(5,v=3,t=500000000),
             word(1,0x002,0xdc),word(2,0x002,0xdc,255,12500000),
             word(2,0x05e,0x80,0x80,12500000),word(2,0x247,2,2,12500000),
             word(2,0x287,2,2,12500000)] + interface_snapshot + [word(15)]
 assert len(program)<2048
 manifests.append({'lo_reference_hz':hz,'words':len(program),'trace_sha256':hashlib.sha256((O/f'trace_{hz}.txt').read_bytes()).hexdigest()})
 banks+=program+[word(15)]*(2048-len(program))
(D/'radio_init.mem').write_text(''.join(f'{w:016x}\n' for w in banks),encoding='ascii')
# Source table: common RX/TX LO uses ADI's TDD VCO table, reference 80 MHz.
src=(R/'vendor/no-os/drivers/rf-transceiver/ad9361/ad9361.c').read_text(encoding='utf-8')
text=src.split('static const struct SynthLUT SynthLUT_TDD',1)[1].split('};',1)[0]
rows=[list(map(int,re.findall(r'\d+',m))) for m in re.findall(r'\{([^{}]+)\}',text)]
assert len(rows)==159 and all(len(r)==13 for r in rows)
rows=rows[106:159]
packed=[];thresholds=[]
for r in rows:
 mhz,level,varactor,bias_ref,bias_tcf,offset,var_ref,cp,c2,c1,r1,c3,r3=r
 vals=[0x40|level,varactor,bias_ref|(bias_tcf<<3),offset<<3,var_ref,0,0x70,cp,c2<<4|c1,r1<<4|c3,r3]
 packed.append(sum(v<<(8*j) for j,v in enumerate(vals)));thresholds.append(mhz)
packed += [packed[-1]]*(64-len(packed));thresholds += [thresholds[-1]]*(64-len(thresholds))
(D/'vco_values.mem').write_text(''.join(f'{v:022x}\n' for v in packed),encoding='ascii')
(D/'vco_thresholds.mem').write_text(''.join(f'{v:04x}\n' for v in thresholds),encoding='ascii')
# The ADI driver selects FDD VCO tables when RX and TX LOs differ, TDD tables
# when they are equal. The frequency thresholds are identical in these tables.
fdd_text=src.split('static const struct SynthLUT SynthLUT_FDD',1)[1].split('};',1)[0]
fdd_rows=[list(map(int,re.findall(r'\d+',m))) for m in re.findall(r'\{([^{}]+)\}',fdd_text)][106:159]
assert [r[0] for r in fdd_rows]==thresholds[:53]
fdd_packed=[]
for r in fdd_rows:
 mhz,level,varactor,bias_ref,bias_tcf,offset,var_ref,cp,c2,c1,r1,c3,r3=r
 vals=[0x40|level,varactor,bias_ref|(bias_tcf<<3),offset<<3,var_ref,0,0x70,cp,c2<<4|c1,r1<<4|c3,r3]
 fdd_packed.append(sum(v<<(8*j) for j,v in enumerate(vals)))
fdd_packed += [fdd_packed[-1]]*(64-len(fdd_packed))
(D/'vco_fdd_values.mem').write_text(''.join(f'{v:022x}\n' for v in fdd_packed),encoding='ascii')
# RX-only live script: both PLL tables are explicitly refreshed as in ADI's
# other-PLL fixup; TX frequency, attenuation, enables and digital clock stay put.
rx_banks=[]
for hz in (300000000,2400000000,6000000000):
 lines=(O/f'rx_trace_{hz}.txt').read_text(encoding='ascii').splitlines()
 program=[];final={}
 for line in lines:
  p=line.split()
  if not p:continue
  op=p[0]
  if op in ('W','M'):
   a=int(p[1],16);m=int(p[2],16) if op=='M' else 255;v=int(p[-1],16)
   base=a if a<0x270 else a-0x40
   dyn=base in dynamic and not(base in (0x239,0x23b) and op!='M')
   if dyn:program.append(word(6 if op=='W' else 7,a,dynamic[base],m))
   elif a==5 and op=='M':program.append(word(7,a,16 if m==15 else 17,m))
   else:program.append(word(1 if op=='W' else 4,a,v,m))
   # Final gain/mode control writes are read back before RX START can succeed.
   # 0x109 is not read back here: while the chip is (or was) in AGC it
   # returns the live AGC index (HW15: 0x28 at rx bank word 595), and the
   # bw/gain script that always follows writes and checks it in MGC.
   if a in (0x10c,0xfa):final[a]=(v,m)
  elif op=='P':
   if p[1] in ('247','287'):program.append(LOCK_SETTLE)
   program.append(word(2,int(p[1],16),int(p[3],16),int(p[2],16),LIVE_CHECK))
  elif op=='D':program.append(word(3,t=int(p[1])*125))
 # Read back programmed PLL words, not only the LOCK bits.
 for base in (0x230,0x270):
  for a,n in ((base+3,11),(base+4,12),(base+5,13),(base+2,14),(base+1,15)):
   program.append(word(8,a,n,7 if a in (base+5,base+2) else 255,12500000))
 for a,(v,m) in final.items():program.append(word(2,a,v,m,12500000))
 program += [word(2,0x247,2,2,LIVE_CHECK),word(2,0x287,2,2,LIVE_CHECK)] + interface_snapshot + [word(15)]
 assert len(program)<2048
 assert not any(((w>>48)&0xfff) in (0x002,0x073,0x074,0x075,0x076,0x014,0x015,0x016) for w in program if (w>>60) in (1,4,6,7))
 rx_banks+=program+[word(15)]*(2048-len(program))
(D/'radio_rx.mem').write_text(''.join(f'{w:016x}\n' for w in rx_banks),encoding='ascii')
program=[]
for line in (O/'tx_trace_300000000.txt').read_text(encoding='ascii').splitlines():
 p=line.split()
 if not p:continue
 op=p[0]
 if op in ('W','M'):
  a=int(p[1],16);m=int(p[2],16) if op=='M' else 255;v=int(p[-1],16)
  base=a if a<0x270 else a-0x40
  dyn=base in dynamic and not(base in (0x239,0x23b) and op!='M')
  if dyn:program.append(word(6 if op=='W' else 7,a,dynamic[base],m))
  elif a==5 and op=='M':program.append(word(7,a,16 if m==15 else 17,m))
  else:program.append(word(1 if op=='W' else 4,a,v,m))
 elif op=='P':
  if p[1] in ('247','287'):program.append(LOCK_SETTLE)
  program.append(word(2,int(p[1],16),int(p[3],16),int(p[2],16),LIVE_CHECK))
 elif op=='D':program.append(word(3,t=int(p[1])*125))
for base in (0x230,0x270):
 for a,n in ((base+3,11),(base+4,12),(base+5,13),(base+2,14),(base+1,15)):
  program.append(word(8,a,n,7 if a in (base+5,base+2) else 255,12500000))
# UG-570 p.13 and ADI ad9361_do_calib_run: TX quadrature calibration runs
# in ALERT, then restores normal SPI-controlled FDD. Preserve the RX capture
# session; a real LO change has a brief calibration gap, not a radio reset.
# ADI ad9361_do_calib_run(TX_QUAD_CAL): tracking_control(false,false,false),
# ALERT, the full ad9361_tx_quad_calib register setup (same values as the
# init trace), then tracking restored as init leaves it (0x18B=AD, 0x169=CF;
# BB+RF DC and both-channel quad tracking do not depend on AGC/MGC), FDD.
# 0x0AA (tx_quad_lpf_tia_match) follows the live RX LO gain-table band.
tracking_off=[word(1,0x16a,0x75),word(1,0x16b,0x95),word(1,0x18b,0x85),
              word(4,0x16f,0x00,0xe0),word(1,0x169,0xcc)]
tracking_on=[word(1,0x16a,0x75),word(1,0x16b,0x95),word(1,0x18b,0xad),
             word(4,0x16f,0x00,0xe0),word(1,0x169,0xcf)]
quad_setup=[word(4,0x0a3,0x80,0xc0),word(1,0x0a9,0xff),word(1,0x0a2,0x7f),
            word(1,0x0a5,0x03),word(1,0x0a6,0x03),word(13,0x0aa),
            word(1,0x0a4,0xf0),word(1,0x0ae,0x00)]
program += tracking_off + [word(1,0x014,0x05),word(2,0x017,5,15,LIVE_CHECK)] + quad_setup + [QUAD_CALL] + tracking_on + \
           [word(1,0x014,0x29),word(2,0x017,10,15,LIVE_CHECK),
            word(2,0x247,2,2,LIVE_CHECK),word(2,0x287,2,2,LIVE_CHECK)] + interface_snapshot + [word(15)]
assert len(program)<2048
assert not any(((w>>48)&0xfff) in (0x002,0x003,0x015,0x016) for w in program if (w>>60) in (1,4,6,7,13))
_writes=[((w>>48)&0xfff,(w>>40)&255) for w in program if w>>60==1]
_call=next(i for i,w in enumerate(program) if w>>60==5)
# Tracking is off before ALERT/calibration and restored before FDD.
assert [v for a,v in _writes if a==0x18b]==[0x85,0xad]
_at=lambda a,v:[i for i,w in enumerate(program) if w>>60==1 and (w>>48)&0xfff==a and (w>>40)&255==v]
assert _at(0x18b,0x85)[0]<_at(0x014,0x05)[0]<_call<_at(0x18b,0xad)[0]<_at(0x014,0x29)[0]
assert sum(1 for w in program if w>>60==13 and (w>>48)&0xfff==0x0aa)==1
assert [(w>>40)&255 for w in program if w>>60==1 and (w>>48)&0xfff==0x014]==[0x05,0x29]
(D/'radio_tx.mem').write_text(''.join(f'{w:016x}\n' for w in program+[word(15)]*(2048-len(program))),encoding='ascii')
(D/'radio_manifest.json').write_text(json.dumps({'profiles':manifests,'sample_rate_hz':25000000,
 'two_rx_two_tx_framing':True,'hardware_validation':False,'live_callbacks':['ADC','TIA','TX quadrature','LVDS fixed delay RX=04 TX=0A']},indent=2),encoding='ascii')
print(manifests)
from generate_rx_profiles import BANDWIDTHS
bw_banks=[]
for bw in BANDWIDTHS:
 lines=(O/f'bw_trace_{bw}.txt').read_text().split('BW_BEGIN\n',1)[1].split('BW_RESULT',1)[0].splitlines()
 program=[word(1,0x014,5),word(2,0x017,5,15,12500000)]
 for line in lines:
  p=line.split()
  if not p:continue
  if p[0] in ('W','M'):
   a=int(p[1],16);v=int(p[-1],16);mask=int(p[2],16) if p[0]=='M' else 255
   program.append(word(4 if p[0]=='M' else 1,a,v,mask))
  elif p[0]=='P':program.append(word(2,int(p[1],16),int(p[3],16),int(p[2],16),125000000))
  elif p[0]=='TIA':program.append(word(5,v=1,t=125000000))
  elif p[0]=='ADC':program.append(word(5,v=0,t=125000000))
 # Gain mode is written in ALERT (ADI disables RX around the 0x0FA write);
 # the manual gain index is written after returning to FDD, as ADI's
 # ad9361_set_rx_gain() does on a running receiver. HW14 board evidence:
 # 0x109 written in ALERT read back the old index (0x0f), failing START for
 # every gain except the boot default 10 dB. 10=dynamic write, 11=dynamic
 # check (re-polls until the timeout), 12=dynamic RMW. Value selector 1 is
 # the manual index; ad9361_radio.sv skips those words in AGC modes, like
 # ADI, which never writes 0x109 outside MGC.
 program += [word(12,0x0fa,0,3),word(11,0x0fa,0,3,12500000),word(12,0x15c,2,15),
             word(1,0x014,0x29),word(2,0x017,10,15,12500000),
             word(12,0x109,1,0x7f),word(11,0x109,1,0x7f,12500000),word(15)]
 program=[word(2,a,v,m,LIVE_CHECK) if w>>60==2 and t==12500000 else w
          for w in program for a,v,m,t in [((w>>48)&0xfff,(w>>40)&255,(w>>32)&255,w&0xffffffff)]]
 assert len(program)<128
 bw_banks+=program+[word(15)]*(128-len(program))
(D/'radio_bw.mem').write_text(''.join(f'{w:016x}\n' for w in bw_banks))
