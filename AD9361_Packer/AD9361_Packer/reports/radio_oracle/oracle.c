
#include "ad9361_api.h"
#include "ad9361.h"
#include "no_os_spi.h"
#include "no_os_gpio.h"
#include "no_os_delay.h"
#include "no_os_alloc.h"
#include <stdlib.h>
#include <stdio.h>
extern AD9361_InitParam default_init_param;
static unsigned char regs[1024],gt[128][3];
static struct no_os_spi_desc desc;
static struct no_os_gpio_desc gpio;
static unsigned char readreg(unsigned a){
 unsigned v=regs[a];
 if(a==0x037)v=0x0a;
 if(a==0x017)v=regs[0x017];
 if(a==0x05e||a==0x244||a==0x284)v=0x80;
 if(a==0x247||a==0x287)v=2;
 if(a==0x016)v=0;
 if(a==0x0a7||a==0x0a8)v=3;
 if(a>=0x134&&a<=0x136)v=gt[regs[0x130]][a-0x134];
 printf("R %03x %02x\n",a,v);return v;
}
static void writereg(unsigned a,unsigned v){
 regs[a]=v;
 /* The power-on ENSM state is SLEEP_WAIT, not FDD. Track SPI force-state
    writes so driver save/restore paths retain ALERT during calibration. */
 if(a==0x014){
  if((v&4)||((v&1)&&!(v&0x60)))regs[0x017]=5;
  else if(v&0x20)regs[0x017]=(regs[0x013]&1)?10:6;
  else if(v&0x40)regs[0x017]=8;
  else regs[0x017]=0;
 }
 if(a==0x137&&(v&4)){for(int j=0;j<3;j++)gt[regs[0x130]][j]=regs[0x131+j];}
}
int oracle_rmw(unsigned a,unsigned m,unsigned v){
 printf("M %03x %02x %02x\n",a,m,v);writereg(a,(regs[a]&~m)|(v&m));return 0;
}
int32_t no_os_spi_init(struct no_os_spi_desc **d,const struct no_os_spi_init_param *p){*d=&desc;return 0;}
int32_t no_os_spi_remove(struct no_os_spi_desc *d){return 0;}
int32_t no_os_spi_write_and_read(struct no_os_spi_desc *d,uint8_t *p,uint16_t n){
 unsigned cmd=(p[0]<<8)|p[1],a=cmd&0x3ff,rd=!(cmd&0x8000);
 for(int j=2;j<n;j++,a--){
  if(rd)p[j]=readreg(a);
  else{printf("W %03x %02x\n",a,p[j]);writereg(a,p[j]);}
 }return 0;
}
void no_os_udelay(uint32_t us){printf("D %u\n",us);}
void no_os_mdelay(uint32_t ms){printf("D %u\n",ms*1000);}
struct no_os_time no_os_get_time(void){struct no_os_time t={0,0};return t;}
void *no_os_malloc(size_t n){return malloc(n);}
void *no_os_calloc(size_t n,size_t s){return calloc(n,s);}
void no_os_free(void *p){free(p);}
int32_t no_os_gpio_get(struct no_os_gpio_desc **d,const struct no_os_gpio_init_param *p){*d=&gpio;return 0;}
int32_t no_os_gpio_get_optional(struct no_os_gpio_desc **d,const struct no_os_gpio_init_param *p){*d=0;return 0;}
int32_t no_os_gpio_set_value(struct no_os_gpio_desc *d,uint8_t v){printf("RESET %u\n",v);return 0;}
int32_t no_os_gpio_direction_output(struct no_os_gpio_desc *d,uint8_t v){return no_os_gpio_set_value(d,v);}
int32_t no_os_gpio_direction_input(struct no_os_gpio_desc *d){return 0;}
int32_t no_os_gpio_remove(struct no_os_gpio_desc *d){return 0;}
int32_t ad9361_hdl_loopback(struct ad9361_rf_phy *p,bool e){return 0;}
int32_t ad9361_post_setup(struct ad9361_rf_phy *p){return 0;}
int32_t ad9361_dig_tune(struct ad9361_rf_phy *p,uint32_t f,enum dig_tune_flags g){printf("DIGITAL_TUNE\n");return 0;}
int main(void){
#ifdef CAL_VERIFY
 extern void oracle_calc(void);
 unsigned a,b,c;
 while(scanf("%u %u %u",&a,&b,&c)==3){
  regs[0x1eb]=a;regs[0x1ec]=b;regs[0x1e6]=c;
  printf("CAL %u %u %u\n",a,b,c);oracle_calc();
 }return 0;
#endif
 AD9361_InitParam *p=&default_init_param;
 if(getenv("ORACLE_LO"))p->rx_synthesizer_frequency_hz=p->tx_synthesizer_frequency_hz=strtoull(getenv("ORACLE_LO"),0,10);
 unsigned rx[]={800000000,200000000,100000000,50000000,25000000,25000000};
 for(int j=0;j<6;j++){p->rx_path_clock_frequencies[j]=rx[j];p->tx_path_clock_frequencies[j]=rx[j];}
 p->rf_rx_bandwidth_hz=20000000;p->rf_tx_bandwidth_hz=20000000;
 p->lvds_invert1_control=0;p->lvds_invert2_control=0;
 p->pp_tx_swap_enable=1;p->pp_rx_swap_enable=1;p->two_t_two_r_timing_enable=1;
 /* UG-570 pp.107,109-110: periodic 2R2T framing (1100) needs pulse mode.
    Level mode can hold RX_FRAME high for the entire continuous burst. */
 p->rx_frame_pulse_mode_enable=1;
 p->gc_rx1_mode=0;p->gc_rx2_mode=0;p->digital_interface_tune_skip_mode=2;
 p->tx_attenuation_mdB=89750;p->gpio_resetb.number=0;
 struct ad9361_rf_phy *phy=0;
 int r=ad9361_init(&phy,p);printf("RESULT %d\n",r);
 if(r)return 1;
 r=ad9361_set_rx_rf_gain(phy,0,10);printf("GAIN_RESULT %d\n",r);
 if(getenv("ORACLE_BW")){
  extern int oracle_rx_bandwidth(struct ad9361_rf_phy *,unsigned);
  printf("BW_BEGIN\n");r=oracle_rx_bandwidth(phy,strtoul(getenv("ORACLE_BW"),0,10));
  printf("BW_RESULT %d\n",r);
 }
 /* Fixed 2R2T: keep both TX data paths clocked. PL zero IQ and maximum
    attenuation mute outputs without changing the physical channel count. */
 ad9361_spi_write(phy->spi,0x002,0xdc);
 if(getenv("ORACLE_RX")){
  unsigned long long rx=strtoull(getenv("ORACLE_RX"),0,10);
  printf("RX_BEGIN\n");
  /* Force table loading and the other-PLL fixup so the generated script is
     valid for any previous RX band/table. This does not alter ENSM policy. */
  phy->current_table=(uint32_t)-1;
  phy->current_tx_use_tdd_table=rx!=p->tx_synthesizer_frequency_hz;
  phy->current_rx_use_tdd_table=phy->current_tx_use_tdd_table;
  r=ad9361_rfpll_set_rate(phy->ref_clk_scale[RX_RFPLL],ad9361_to_clk(rx));
  if(!r)r=ad9361_set_rx_rf_gain(phy,0,10);
  printf("RX_RESULT %d\n",r);
 }
 if(getenv("ORACLE_TX")){
  unsigned long long tx=strtoull(getenv("ORACLE_TX"),0,10);
  printf("TX_BEGIN\n");
  phy->current_tx_use_tdd_table=tx!=p->rx_synthesizer_frequency_hz;
  phy->current_rx_use_tdd_table=phy->current_tx_use_tdd_table;
  /* Record the PLL update only. The generated PL script brackets its TX
     quadrature callback with ALERT/FDD, as required by ADI calibration. */
  r=ad9361_rfpll_int_set_rate(phy->ref_clk_scale[TX_RFPLL_INT],
      ad9361_to_clk(tx),80000000);
  printf("TX_RESULT %d\n",r);
 }
 return r!=0;
}
