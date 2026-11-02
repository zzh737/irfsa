"""PC parameter presentation and capability checks for the existing FPGA image."""
from __future__ import annotations

import math

AM_MODES=('AM-SSB-WC','AM-SSB-SC','AM-DSB-WC','AM-DSB-SC')
UI_MODES=AM_MODES+('FM',)+tuple(f'{n}{family}' for family in ('ASK','FSK','PSK')
                              for n in (2,4,8,16))+('16QAM','64QAM','256QAM')
SPECIAL_FIELDS=dict(sideband=('边带选择','sideband',('USB / 上边带','LSB / 下边带')),
                    carrier_ratio=('载波 / 边带功率比 / dB','carrier_ratio',None),
                    am_depth=('AM 调制度 · 0＜μ≤1','am_depth',None),
                    fm_index=('调频指数 β · 当前固件固定 4','fm_index',None),
                    rolloff=('RRC 滚降系数 α · 当前固定 0.35','rolloff',None))
EXTRA_DEFAULTS=dict(sideband='USB / 上边带',carrier_ratio='6',fm_index='4',rolloff='0.35',
                    rx_center='2400',rx_bandwidth='20',rx_gain_mode='手动增益',rx_gain='10',
                    rx_follow='1',tx1_noise='1',
                    # PC-side RX filter (kHz relative to the RX LO); off by default.
                    rx_filter='0',filter_type='BPF · 带通',filter_f1='-300',filter_f2='300',
                    filter_ripple='0.1',filter_stop='60',filter_transition='20')
FILTER_TYPES=('LPF · 低通','HPF · 高通','BPF · 带通','BSF · 带阻')
# Firmware 23: TX1 offset (register 6) is the carrier and the "基带带宽" field is the
# one-sided baseband bandwidth B for every modulation (RF occupancy 2B, SSB B). Older
# firmware reads the 0x100 bandwidth as RF occupancy, and HW21/HW22 place SSB around the
# offset as its band centre.
BASEBAND_FIRMWARE=23


def planner_mode(mode):
    """UI modulation name -> waveform_config.MODES key."""
    mode=display_mode(mode)
    return 'AM' if mode=='AM-DSB-WC' else mode


def rf_occupancy(values):
    """TX1 RF occupancy in MHz: 2B, or B for SSB."""
    bw=float(values['bandwidth'])
    return bw if 'SSB' in values.get('modulation','') else 2*bw


def baseband_firmware_warning(values,firmware):
    """Critical warning for firmware older than 23 (different bandwidth/offset meaning)."""
    if firmware is None:return ''
    try:firmware=int(firmware)
    except (TypeError,ValueError):return ''
    if firmware>=BASEBAND_FIRMWARE:return ''
    ssb='SSB' in values.get('modulation','')
    if ssb:
        text=f'固件 {firmware} < {BASEBAND_FIRMWARE}：'+('SSB 频偏仍按边带中心解释，边带会偏 B/2' if firmware>=21 else 'SSB 位置与界面一致')
    else:
        text=f'固件 {firmware} < {BASEBAND_FIRMWARE}：板端把带宽当作射频占用，实际射频占用只有界面的一半'
    return text+'（与训练标签不一致）。请烧录 HW23 后再录制。'

FILTER_KEYS=('rx_filter','filter_type','filter_f1','filter_f2','filter_ripple','filter_stop','filter_transition')


def filter_spec(values,fs):
    """FilterSpec for the draft when the RX filter is on, else None. Raises FilterError."""
    if values.get('rx_filter','0')!='1':return None
    import rx_filter
    if fs>rx_filter.MAX_FS:
        raise rx_filter.FilterError(rx_filter.RATE_LIMIT_TEXT)
    return rx_filter.parse_spec(values['filter_type'],values['filter_f1'],values['filter_f2'],
                                values['filter_ripple'],values['filter_stop'],values['filter_transition'],fs)
COMMON_KEYS=('modulation','center','bandwidth','offset','snr','tx1_noise','atten1','atten2',
             'noise_low','noise_high','seed')
RX_KEYS=('rx_follow','rx_center','rx_bandwidth','rx_gain_mode','rate')
HW06_FIXED_RX={}
RX_BANDWIDTHS=('0.2','0.5','1','2','5','10','15','20')


def normalize_hw06_draft(values):
    """Adapt saved UI drafts to fixed HW06 controls; never sends hardware commands."""
    fixed=dict(HW06_FIXED_RX,baud='115200',fm_index='4')
    if display_mode(values.get('modulation','')).endswith(('ASK','PSK','QAM')):
        fixed['rolloff']='0.35'
    changed=[key for key,value in fixed.items() if values.get(key)!=value]
    values.update(fixed)
    return changed


def display_mode(mode):
    return 'AM-DSB-WC' if mode=='AM' else mode


def mode_fields(mode):
    mode=display_mode(mode)
    if mode not in UI_MODES:
        raise ValueError('请选择列表中的调制方式。')
    result=[]
    if 'SSB' in mode: result.append('sideband')
    if mode=='AM-SSB-WC': result.append('carrier_ratio')
    if mode=='AM-DSB-WC': result.append('am_depth')
    if mode=='FM': result.append('fm_index')
    if mode.endswith(('ASK','PSK','QAM')): result.append('rolloff')
    return tuple(result)


def numeric(values,key,low=None,high=None):
    try: value=float(values[key])
    except (ValueError,TypeError): raise ValueError('请输入有效数值：'+key) from None
    if not math.isfinite(value): raise ValueError('参数必须为有限数值：'+key)
    if low is not None and not low<=value<=high:
        raise ValueError(f'{key} 范围为 {low:g}～{high:g}。')
    return value


def validate_tx(values):
    """Validate even modes that must wait for an FPGA update. Ignore hidden values."""
    fields=mode_fields(values['modulation'])
    center=numeric(values,'center',300,6000)
    bw=numeric(values,'bandwidth',.005,10)
    offset=numeric(values,'offset',-10,10)
    if values.get('tx1_noise','1') not in ('0','1'): raise ValueError('TX1 内部噪声开关无效。')
    numeric(values,'snr',-10,20)
    for key in ('atten1','atten2'):
        a=numeric(values,key,0,89.75)
        if not math.isclose(a*4,round(a*4),abs_tol=1e-7):
            raise ValueError('发射衰减必须按 0.25 dB 步进设置。')
    nl=numeric(values,'noise_low',-10,10); nh=numeric(values,'noise_high',-10,10)
    if not .01-1e-9<=nh-nl<=20: raise ValueError('TX2 噪声频段宽度应为 0.01～20 MHz。')
    try: seed=int(values['seed'],0)
    except (TypeError,ValueError): raise ValueError('随机种子需为非零 u32。') from None
    if not 0<seed<=0xffffffff: raise ValueError('随机种子需为非零 u32。')
    for key in fields:
        if key=='sideband':
            if values[key] not in SPECIAL_FIELDS[key][2]: raise ValueError('请选择 USB 或 LSB。')
        elif key=='am_depth':
            if not 0<numeric(values,key)<=1: raise ValueError('AM 调制度需大于 0 且不超过 1。')
        else:
            numeric(values,key,*dict(carrier_ratio=(-30,40),fm_index=(.01,100),rolloff=(.05,1))[key])
    # offset is the carrier; the band is offset ± B (SSB: one side only).
    if 'SSB' in values['modulation']:
        left,right=(offset-bw,offset) if values.get('sideband','').startswith('LSB') else (offset,offset+bw)
    else:left,right=offset-bw,offset+bw
    if left< -10 or right>10: raise ValueError('TX1 占用频段必须落在发射本振 ±10 MHz 内。')
    return values


def validate_draft(values):
    validate_tx(values)
    return validate_rx(values)


def validate_rx(values):
    numeric(values,'rx_bandwidth',.2,20)
    if values['rx_follow'] not in ('0','1'): raise ValueError('RX 跟随选项无效。')
    numeric(values,'center' if values['rx_follow']=='1' else 'rx_center',300,6000)
    if values['rx_gain_mode'] not in ('手动增益','慢速 AGC','快速 AGC'): raise ValueError('请选择 RX 增益模式。')
    if values['rx_gain_mode']=='手动增益':
        center=numeric(values,'center' if values['rx_follow']=='1' else 'rx_center')
        limits=(-1,73) if center<=1300 else (-3,71) if center<=4000 else (-10,62)
        gain=numeric(values,'rx_gain',*limits)
        if gain!=round(gain):raise ValueError('接收手动增益按 1 dB 步进设置。')
    if values['rate'] not in ('1 MSPS · FIR 抽取','25 MSPS · 原始采样'): raise ValueError('请选择 IQ 输出采样率。')
    return values


def tx_firmware_reason(values):
    mode=display_mode(values['modulation'])
    # All listed modulation families are implemented by the matching firmware.
    if mode=='FM' and numeric(values,'fm_index')!=4:
        return '当前 FPGA 的 FM 调频指数固定为 4，修改后需更新 FPGA。'
    if mode.endswith(('ASK','PSK','QAM')) and numeric(values,'rolloff')!=.35:
        return '当前 FPGA 的 RRC 滚降系数固定为 0.35，修改后需更新 FPGA。'
    return ''


def rx_firmware_reason(values):
    if str(values['rx_bandwidth']) not in RX_BANDWIDTHS: return '请选择列表中的 RX 校准带宽档位。'
    return ''


def active_parameters(values):
    validate_draft(values)
    keys=COMMON_KEYS+mode_fields(values['modulation'])+RX_KEYS
    if values['rx_gain_mode']=='手动增益': keys+=('rx_gain',)
    result={k:values[k] for k in keys}
    result['modulation']=display_mode(result['modulation'])
    if values['rx_follow']=='1': result['rx_center']=values['center']
    return result
