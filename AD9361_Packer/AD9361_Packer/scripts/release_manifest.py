"""Record reproducible build inputs and offline acceptance evidence."""
from pathlib import Path
import hashlib,json,re,datetime
from source_manifest import R,design_sources
out=R/'reports/system_build';bit=out/'ku5p_system_candidate.bit'
log=(out/'build.log').read_text(errors='replace')
if 'KU5P_CANDIDATE_BUILD_COMPLETE' not in log or not bit.exists():
    raise SystemExit('No completed timing-qualified candidate build')
if 'CRITICAL WARNING:' in log:
    raise SystemExit('Implementation has a Critical Warning; no qualified release manifest')
cdc=(out/'routed_cdc.rpt').read_text()
if re.search(r'^CDC-\d+\s+Critical\s+[1-9]\d*',cdc,re.M):
    raise SystemExit('Critical CDC findings remain')
s=(out/'routed_timing.rpt').read_text()
m=re.search(r'WNS\(ns\).*?\n\s*-+.*?\n\s*([-\d.]+)\s+[-\d.]+\s+\d+\s+\d+\s+([-\d.]+)',s,re.S)
if not m or min(map(float,m.groups()))<0:raise SystemExit('Routed timing not qualified')
files=design_sources(['ku5p_top'])+list((R/'rtl/rom').glob('*.mem'))+list((R/'constraints').glob('ku5p_*.xdc'))+[R/'scripts'/n for n in ('ku5p_post_synth.tcl','ku5p_post_opt.tcl','ku5p_io_config.tcl','build_system.tcl','ku5p_pre_bitstream.tcl','ku5p_post_bitstream.tcl')]
hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
prior=out/'input_hashes.json'
if prior.exists() and hashes!=json.loads(prior.read_text()):raise SystemExit('Build input hashes changed')
checks={}; evidence={}
for name in ('radio_supervisor','calibration_timeout','radio_blocks','adc_cal','i2c','boot_journal','data_interface','lvds','decimator','waveform_sim','packetizer_sim','ethernet','phy','command_rx_sim','controller','cache','split_control','host','host_socket'):
    p=R/'reports'/name/'result.json'
    if not p.exists():raise SystemExit('Missing offline acceptance evidence: '+name)
    checks[name]=json.loads(p.read_text())
    evidence[str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
p=R/'reports/radio_oracle/cal_verify.json'
checks['radio_oracle']=json.loads(p.read_text())
evidence[str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
p=R/'reports/elaboration/xsim.log'
checks['elaboration']={'passed':'ELABORATION PASSED' in p.read_text(errors='replace')}
evidence[str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
for name in ('routed_timing.rpt','drc.rpt','route_status.rpt','routed_cdc.rpt','methodology.rpt','bus_skew.rpt','check_timing.rpt'):
    p=out/name
    evidence[str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
if any(x.get('passed') is not True for x in checks.values()):raise SystemExit('An offline acceptance check failed')
manifest=dict(created_local=datetime.datetime.now().isoformat(),part='xcku5p-ffvb676-2-i',top='ku5p_top',Vivado='2025.2',
    artifact=str(bit.relative_to(R)),sha256=hashlib.sha256(bit.read_bytes()).hexdigest(),
    setup_WNS_ns=float(m[1]),hold_WHS_ns=float(m[2]),inputs=hashes,checks=checks,evidence_sha256=evidence,
    hardware_connected=False,hardware_verified=False,flash_programmed=False,
    implementation_critical_warnings=0,cdc_critical_findings=0,
    external_timing_budgets='Candidate PHY/FMC assumptions; board eye and RF tests required',
    cdc_review='Separate asynchronous reset sources synchronized before combining; release gate rejects Critical CDC. Multi-bit/handshake warnings still require the structural review in docs/时序与CDC审查.md')
review=R/'reports/hw06_review/offline_checks.json'
if review.exists():
    manifest['HW06_review']=json.loads(review.read_text(encoding='utf-8'))
    rerun=manifest['HW06_review']['rtl_checks_rerun']
    manifest['historical_checks_not_rerun']=[name for name in checks if name not in rerun]
    manifest['qualification_scope']='Targeted HW06 regressions plus fresh full implementation; other listed checks are historical evidence, not rerun against HW06. No HW06 board test.'
review=R/'reports/hw07_review/offline_checks.json'
if review.exists():
    manifest['HW07_review']=json.loads(review.read_text(encoding='utf-8'))
    rerun=manifest['HW07_review']['rtl_checks_rerun']
    p=R/'reports/lvds_aperture/result.json'
    manifest['checks']['lvds_aperture']=json.loads(p.read_text())
    if manifest['checks']['lvds_aperture'].get('passed') is not True:
        raise SystemExit('Independent LVDS aperture check failed')
    manifest['evidence_sha256'][str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
    manifest['historical_checks_not_rerun']=[name for name in checks if name not in rerun]
    manifest['qualification_scope']='Targeted HW07 LVDS wire-timing checks plus fresh full implementation; other tests are historical evidence. RF output and board RX after programming remain unverified.'
    manifest['HW07_qualification']='Full HW07 synthesis/place/route followed by correction of STA-only PHASESHIFT_MODE edge pairing on that routed checkpoint; no RTL or physical MMCM phase change in the qualification step. All release gates rerun.'
    for name in ('qualify_hw07_phase.py','qualify_hw07_phase.tcl'):
        p=R/'scripts'/name
        manifest['evidence_sha256'][str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
review=R/'reports/hw08_rx_diagnostics/offline_checks.json'
if review.exists():
    manifest['HW08_review']=json.loads(review.read_text(encoding='utf-8'))
    rerun=manifest['HW08_review']['rtl_checks_rerun']
    manifest['historical_checks_not_rerun']=[name for name in checks if name not in rerun]
    manifest['qualification_scope']='HW08 RX diagnostics only: radio SPI supervisor regression and full top elaboration rerun; fresh synthesis/place/route and all release gates. RX no-sample fault remains unresolved pending physical frame/register evidence.'
    manifest['HW08_qualification']='Fresh full build using WAVEFORM mode for the fixed AD9361 RX clock from the start. No post-route phase edit, no timing-budget relaxation.'
    manifest['live_board_baseline']='HW07: TX RF success reported by user; RX samples 0, frame errors stable at 8. This candidate has not been programmed.'
review=R/'reports/hw09_rx_live/offline_checks.json'
if review.exists():
    manifest['HW09_review']=json.loads(review.read_text(encoding='utf-8'))
    p=R/'reports/rx_observer/result.json'
    manifest['checks']['rx_observer']=json.loads(p.read_text())
    if manifest['checks']['rx_observer'].get('passed') is not True:
        raise SystemExit('RX live observer regression failed')
    manifest['evidence_sha256'][str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
    manifest['historical_checks_not_rerun']=[name for name in checks if name not in ('elaboration','rx_observer')]
    manifest['qualification_scope']='HW09 passive live RX frame evidence only: observer and full top elaboration rerun; fresh full implementation. No functional RX fix claimed; all other regressions are historical.'
    manifest['live_board_baseline']='HW08 boot32: RX IQ0, frame errors2; valid interface register cache. Brief TX1 maximum-attenuation comparison counted TX IQ but RX stayed0. TX returned off. Saturating HW08 frame counters cannot establish current frame activity.'
review=R/'reports/hw10_rx_frame_pulse/offline_checks.json'
if review.exists():
    manifest['HW10_review']=json.loads(review.read_text(encoding='utf-8'))
    manifest['historical_checks_not_rerun']=[name for name in checks if name!='data_interface']
    manifest['qualification_scope']='HW10 enables RX_FRAME pulse mode (0x010 C4 -> CC) in all three initialization banks. Existing IQ framing regression rerun; fresh GUI synthesis/place/route/bitstream through SynthPilot. Other regressions are historical evidence.'
    manifest['live_board_baseline']='HW09: no complete RX IQ; pulse mode disabled. HW10 has not been programmed or tested on the board.'
    manifest['diagnostics_schema']='HW09 retained; no protocol or diagnostics layout change'
review=R/'reports/hw11_tx_rx_conflict/offline_checks.json'
if review.exists():
    manifest['HW11_review']=json.loads(review.read_text(encoding='utf-8'))
    manifest['historical_checks_not_rerun']=[name for name in checks if name!='radio_supervisor']
    manifest['qualification_scope']='HW11 fixed 2R2T physical TX enables with independent zero-IQ/max-attenuation mute; TX retune quadrature calibration enters ALERT and restores FDD while retaining the RX capture session. Radio SPI supervisor regression rerun; fresh SynthPilot GUI project synthesis/implementation/bitstream. Other regressions are historical.'
    manifest['live_board_baseline']='HW10 UART comparison: single physical TX enabled freezes RX_FRAME and RX samples; both TX paths enabled resumes RX. HW11 bitstream has not been programmed.'
review=R/'reports/hw12_features/offline_checks.json'
if review.exists():
    manifest['HW12_review']=json.loads(review.read_text(encoding='utf-8'))
    if manifest['HW12_review'].get('passed') is not True:
        raise SystemExit('HW12 targeted checks failed')
    rerun=manifest['HW12_review']['rtl_checks_rerun']
    manifest['historical_checks_not_rerun']=[name for name in checks if name not in rerun]
    p=R/'reports/hw12_profiles/result.json'
    manifest['checks']['rx_profiles']=json.loads(p.read_text())
    if manifest['checks']['rx_profiles'].get('passed') is not True:
        raise SystemExit('HW12 ADC/TIA profile oracle check failed')
    manifest['evidence_sha256'][str(p.relative_to(R))]=hashlib.sha256(p.read_bytes()).hexdigest()
    manifest['firmware_version']=12
    manifest['qualification_scope']='HW12 QAM/AM waveforms, eight RX bandwidth profiles and MGC/slow/fast AGC; radio/controller/ADC/waveform regressions and independent eight-profile ADI C comparison rerun. Fresh SynthPilot GUI synthesis/implementation/bitstream. Other listed checks are historical. No HW12 board test.'
    manifest['live_board_baseline']='User reported RX works alone on prior firmware; HW11/HW12 TX-RX concurrency and new features await user programming and RF validation.'
    manifest['diagnostics_schema']='HW09 diagnostic opcode 0x103 retained; HW12 version/capabilities at UART 0x104 and UDP GET_RX_INFO high16'
review=R/'reports/hw12a_boot/offline_checks.json'
if review.exists():
    manifest['HW12A_review']=json.loads(review.read_text(encoding='utf-8'))
    manifest['firmware_revision']='A'
    manifest['historical_checks_not_rerun']=[name for name in checks if name not in ('boot_journal','controller','split_control')]
    manifest['qualification_scope']='HW12A blank-page interrupted journal recovery and zero-epoch diagnostic replies; boot_journal/controller/split_control rerun plus fresh SynthPilot GUI synthesis/implementation/bitstream. Other checks are historical HW12 evidence.'
    manifest['live_board_baseline']='UART received zero bytes, UDP discovery timed out; after cold reboot Ethernet negotiated 1 Gbps; JTAG configuration DONE/EOS normal and no configuration CRC error. Root hardware startup fault not yet read. HW12A awaits user programming.'
    manifest['hardware_connected']=True
    manifest['diagnostics_schema']='HW09 retained; UART 0x104 word6 startup status, TX radio_flags bit5 epoch unavailable; zero epoch permitted only for diagnostic/failure replies'
(out/'release_manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps({k:v for k,v in manifest.items() if k not in ('inputs','checks')},indent=2))
