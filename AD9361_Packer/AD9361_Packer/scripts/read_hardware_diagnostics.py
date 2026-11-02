"""Read HW01..HW09 diagnostics via UART; never configure or enable TX."""
from pathlib import Path
import argparse,json,struct,sys,time

R=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(R.parent/'operate'))
import backend  # sets the matching host/vendor import paths
from radio_links import UARTClient
from ku5p import pack_request,unpack_response

def diagnostics(client):
    rid=client.ids.reserve('request')
    packet=pack_request(2,rid,0,0x103,client.boot)
    for _ in range(3):
        client.serial.write(packet)
        deadline=time.monotonic()+.8
        while time.monotonic()<deadline:
            for frame in client.frames(client.serial.read(max(1,client.serial.in_waiting))):
                h,payload=unpack_response(frame)
                if h[4:7]!=(rid,0,0x103):continue
                if h[9]!=client.boot:raise RuntimeError('Board restarted during diagnostics')
                if h[7]:raise RuntimeError('Diagnostics status '+str(h[7]))
                w=struct.unpack('>32I',payload)
                if w[0]!=1 or w[1] not in (0x48573031,0x48573032,0x48573033,0x48573034,0x48573035,0x48573036,0x48573037,0x48573038,0x48573039,0x48573139,0x48573230,0x48573231,0x48573232,0x48573233):raise RuntimeError('Unknown diagnostics schema')
                p=w[2:10];r=w[10:18];flags=p[1]
                detail=r[7]
                tune_fault=dict(reason=detail>>28,state=(detail>>21)&127,
                    scan=(detail>>12)&511,best_eye=(detail>>7)&31,
                    current_eye=(detail>>2)&31,tx_scan=bool(detail&2),verify=bool(detail&1)) \
                    if w[1]>=0x48573032 and r[1]&0x4000 and r[3]>>28==5 and ((r[3]>>8)&3)>=2 else None
                # HW19 schema (layout unchanged in HW20/HW21): TX quadrature calibration evidence in radio words 0/1/6.
                quad=dict(warn=bool(r[1]&(1<<16)),mode=('default_phase','last_phase','search','none_converged')[(r[1]>>17)&3],
                    phase=(r[1]>>19)&31,pass_map=f'{r[0]:032b}'[::-1],
                    status_0a7=f'0x{r[6]>>24:02x}',status_0a8=f'0x{(r[6]>>16)&255:02x}',
                    tx1_lo_ssb_converged=(r[6]>>24)&3==3,tx2_lo_ssb_converged=(r[6]>>16)&3==3)                     if w[1]>=0x48573139 else None
                return dict(signature=w[1].to_bytes(4,'big').decode('ascii'),boot_id=client.boot,
                    phy=dict(configured=bool(flags&(1<<16)),fault=bool(flags&(1<<15)),
                        link_up=bool(flags&(1<<14)),address=(flags>>9)&31,
                        step=(flags>>4)&31,state=flags&15,id1=p[2]>>16,id2=p[2]&65535,
                        register=(p[3]>>16)&31,last_read=p[3]&65535,
                        bmsr=p[4]>>16,advertisement=p[4]&65535,
                        gigabit_control=p[5]>>16,phy_status=p[5]&65535,
                        error_code=p[6],timer=p[7]),
                    radio=dict(flags=r[1],step=r[2]>>21,register=(r[2]>>8)&1023,
                        last_read=r[2]&255,command=f'{r[3]:08x}{r[4]:08x}',
                        elapsed_cycles=r[5],fault_step=r[6]&65535,timer_or_tune_detail=r[7],tune_fault=tune_fault,tx_quadrature=quad),
                    clocks=dict(locked=bool(w[18]>>31),reset=bool(w[18]&(1<<30)),raw_edges=None if w[1]>=0x48573036 else (w[18]>>15)&32767,core_edges=None if w[1]>=0x48573036 else w[18]&32767) if w[1]>=0x48573033 else None,
                    pn=dict(last_iq=f'{w[19]:08x}{w[20]>>16:04x}',samples=w[20]&65535,
                        good=w[21]>>16,frame_errors=w[21]&65535,
                        iq_match=w[22]>>16,sequence_match=w[22]&65535) if w[1]==0x48573034 else None,
                    data_path=dict(rx_samples=w[19],rx_frame_errors=w[20],tx1_nonzero_samples=w[21],
                        tx2_nonzero_samples=w[22],counter_bits=32,passive=True,
                        rx_sampling_phase_deg=166.5 if (getattr(client,'firmware_version',0) or 0)>=15 else 90,
                        tx_clock_phase_deg=0) if w[1]>=0x48573037 else None,
                    digital_interface=dict(mode='fixed_delay',rx_delay='0x04',tx_delay='0x0a' if (getattr(client,'firmware_version',0) or 0)>=17 else '0x70',pn_training=False) if w[1]>=0x48573035 else None,
                    rx_frame_pairs=dict(pair_00=w[24]>>16,pair_01=w[24]&65535,
                        pair_10=w[25]>>16,pair_11=w[25]&65535,
                        saturates_at=65535 if w[1]==0x48573038 else None,
                        modulo=65536 if w[1]>=0x48573039 else None) if w[1]>=0x48573038 else None,
                    rx_live_frame=dict(recent_pairs=[f'{(w[26]>>n)&3:02b}' for n in range(30,-1,-2)],
                        trace_hex=f'{w[26]:08x}',transitions=w[27],transition_counter_bits=32,
                        snapshot_period_data_cycles=1024) if w[1]>=0x48573039 else None,
                    interface_readback={f'0x{addr:03x}':f'0x{((sum(w[28+k]<<(32*(3-k)) for k in range(4)))>>(8*n))&255:02x}'
                        for n,addr in enumerate((0x003,0x006,0x007,0x010,0x011,0x012,0x013,0x014,
                                                0x015,0x017,0x03d,0x03e,0x3f4,0x3f5,0x3f6,0x004))} if w[1]>=0x48573038 else None,
                    mdio_wire=dict(level=bool(w[23]>>31),transmitted_low_seen=bool(w[23]&(1<<30)),
                        received_low_seen=bool(w[23]&(1<<29)),transmit_echo_fault=bool(w[23]&(1<<28)),
                        acknowledgments=(w[23]>>16)&4095,frames=w[23]&65535) if w[1]>=0x48573034 else None,
                    words=[f'{x:08x}' for x in w])
    raise TimeoutError('No diagnostics response')

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--port',default='COM4');ap.add_argument('--output',type=Path)
    ap.add_argument('--state',type=Path,default=R/'reports/hardware_fix_20261024/uart_diagnostics_ids.sqlite',
        help='Persistent request IDs prevent replay of a previously cached snapshot')
    args=ap.parse_args()
    client=UARTClient(args.port,115200,args.state,timeout=.6,retries=2)
    try:
        client.discover()
        # A discovery itself may be an idempotent replay from an old tool run.
        # An additional status request synchronizes the high-water mark before
        # allocating a new diagnostics request. All commands remain read-only.
        status=client.request(0x102,version=2)
        result=dict(status=status,diagnostics=diagnostics(client))
    finally:client.close()
    text=json.dumps(result,indent=2,ensure_ascii=False)
    print(text)
    if args.output:
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(text,encoding='utf-8')

if __name__=='__main__':main()
