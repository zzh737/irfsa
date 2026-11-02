"""Frame-coherent dashboard text from existing RF/FFT/classification telemetry."""
import json, mmap, os, struct, time
from pathlib import Path
GLYPHS=json.loads(Path(__file__).with_name('dashboard_glyphs.json').read_text(encoding='utf-8'))

class Dashboard:
    def __init__(self, base=0x400c0000):
        self.fd=os.open('/dev/mem',os.O_RDWR|os.O_SYNC)
        self.mm=mmap.mmap(self.fd,0x6000,flags=mmap.MAP_SHARED,prot=mmap.PROT_READ|mmap.PROT_WRITE,offset=base)
        if struct.unpack_from('<I',self.mm,0x120)[0]!=0x44534831:
            self.close();raise RuntimeError('Dashboard bitstream is not loaded')
        self.state=None
    def close(self):
        self.mm.close();os.close(self.fd)
    def stage(self, class_id):
        if struct.unpack_from('<I',self.mm,0x104)[0]&1:return False
        c=self.state
        if not c:return True
        valid=class_id!=255
        cells=[32]*4096
        def put(row,col,text,palette=0):
            for i,ch in enumerate(text):
                if col+i<80 and 0<=row<30:cells[row*128+col+i]=(palette<<8)|GLYPHS.get(ch,ord('?'))
        rf=c['rf'];fs=c['fs'];lo=c['lo'];decision=c['decision'];timing=c['timing']
        put(1,2,'中心频率 %.3f MHz    接收带宽 %.0f kHz'%(lo/1e6,rf['rx_bandwidth_hz']/1000))
        put(2,2,'手动增益 %.0f dB    采样率 %.0f MSPS    通道 RX%d'%(rf['rx_gain_mdB']/1000,fs/1e6,rf['rx_channel']+1),2)
        put(3,4,'实时频谱',1);put(3,36,'相对电平 dB',2);put(3,54,'信号识别',2)
        for row,label in [(5,'  0'),(7,'-15'),(9,'-30'),(11,'-45'),(13,'-60')]:put(row,1,label,2)
        put(14,4,'历史瀑布图',1);put(14,30,'强度: 低 -> 高',2)
        put(15,0,'现在',2);put(24,0,'较早',2)
        for col,hz in [(4,lo-fs/2),(24,lo),(44,lo+fs/2)]:
            put(26,col,'%.2f'%(hz/1e6),2)
        put(27,43,'MHz',2)
        conf=decision['confidence'] if valid else 0
        put(8,54,'聚合置信度 %5.1f%%'%(conf*100),2)
        put(9,54,'█'*round(conf*20),1)
        put(11,54,'候选类别',2)
        top=decision.get('top_candidates',[]) if valid else []
        for row,item in zip([12,13,14],top):
            put(row,54,item['label'].replace('AM-',''))
            put(row,63,'█'*round(item['probability']*6),1)
            put(row,70,'%5.1f%%'%(item['probability']*100),2)
        put(16,54,'接收状态',2)
        put(18,54,'射频前端  '+('运行中' if valid else '未知'),3 if valid else 4)
        put(19,54,'数据接收  '+('正常' if valid else '无有效数据'),3 if valid else 4)
        put(20,54,'识别处理  '+('正常' if valid else '等待'),3 if valid else 4)
        put(22,54,'聚合帧数  %d / %d'%(decision.get('aggregation_frames',0),decision.get('history_frames',0)),2)
        put(23,54,'最新数据  %d ms前'%round(c['age_ms']),2)
        put(24,54,'前端丢窗  %d'%c['status'].get('drop_windows',0),2)
        put(25,54,'前端溢出  %d'%c['status'].get('overflow_events',0),2)
        offset=(c['peak'] if c['peak']<512 else c['peak']-1024)*fs/1024
        put(28,2,'谱峰 %.3f MHz  相对频偏 %+.1f kHz  频率分辨率 %.1f Hz'%((lo+offset)/1e6,offset/1000,fs/1024))
        put(29,2,'频谱耗时 %.2f ms  识别耗时 %.2f ms  间断计数 %d'%(timing['fft_us']/1000,timing['inference_us']/1000,c['gaps']),2)
        # Every cell is staged into the inactive text bank before the worker's
        # existing COMMIT. No separate writer may touch this register region.
        for i,value in enumerate(cells):struct.pack_into('<I',self.mm,0x2000+i*4,value)
        return True

