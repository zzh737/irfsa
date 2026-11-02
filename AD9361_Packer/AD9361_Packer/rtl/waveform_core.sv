// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Config is immutable until rst. Samples are complex at 25 MSPS; clk >= 100 MHz.
// Q14 internal units, Q16 gain in DAC codes. No runtime software is required.
module waveform_core(
 input wire clk,rst,sample_strobe,input wire [511:0] config_words,
 input wire tx1_enable,tx2_enable,
 output wire sample_valid,output reg signed [11:0] tx1_i,tx1_q,tx2_i,tx2_q,
 output reg [31:0] clip_count1,clip_count2,
 output wire signed [31:0] debug_clean_i,debug_clean_q,debug_noise_i,debug_noise_q
);
 wire [31:0] cfg[0:15];
 genvar n;
 generate for(n=0;n<16;n=n+1)begin assign cfg[n]=config_words[n*32+:32];end endgenerate
 reg signed [15:0] sine[0:4095];
 initial $readmemh("sine.mem",sine);
 wire [31:0] random_word[0:3];
 wire signed [15:0] gauss[0:3];
 generate for(n=0;n<4;n=n+1)begin:randoms
  gaussian_prng #(.LANE(n+1)) prng(clk,rst,cfg[13],random_word[n],gauss[n]);
 end endgenerate
 wire [3:0] symbol_index=random_word[0][3:0] & ((5'd1<<cfg[1][2:0])-1);
 function automatic [3:0] gray_decode(input [3:0] x);
  gray_decode={x[3],x[3]^x[2],x[3]^x[2]^x[1],x[3]^x[2]^x[1]^x[0]};
 endfunction
 reg signed [5:0] qam_i,qam_q;
 reg signed [17:0] qam_unit;
 wire [11:0] psk_address={8'd0,symbol_index} << (12-cfg[1][2:0]);
 reg signed [17:0] mapped_i,mapped_q;
 reg signed [17:0] ask_unit;
 always @* begin
  case(cfg[1][2:0])
   1:ask_unit=23170;2:ask_unit=8758;3:ask_unit=3917;default:ask_unit=1861;
  endcase
  mapped_i=0;mapped_q=0;
  case(cfg[1])
   4:begin qam_i=$signed({1'b0,gray_decode({2'd0,random_word[0][1:0]}),1'b0})-3;
           qam_q=$signed({1'b0,gray_decode({2'd0,random_word[0][3:2]}),1'b0})-3;qam_unit=5181;end
   6:begin qam_i=$signed({1'b0,gray_decode({1'd0,random_word[0][2:0]}),1'b0})-7;
           qam_q=$signed({1'b0,gray_decode({1'd0,random_word[0][5:3]}),1'b0})-7;qam_unit=2528;end
   default:begin qam_i=$signed({1'b0,gray_decode(random_word[0][3:0]),1'b0})-15;
           qam_q=$signed({1'b0,gray_decode(random_word[0][7:4]),1'b0})-15;qam_unit=1257;end
  endcase
  if(cfg[0]==2) mapped_i=$signed({1'b0,symbol_index})*ask_unit;
  else if(cfg[0]==5)begin mapped_i=qam_i*qam_unit;mapped_q=qam_q*qam_unit;end
  else begin
   mapped_i=$signed(sine[(psk_address+12'd1024)&12'hfff])>>>1;
   mapped_q=$signed(sine[psk_address])>>>1;
  end
 end
 wire data_valid,noise_valid1,noise_valid2;
 wire signed [21:0] shaped_i,shaped_q,noise1_i,noise1_q,noise2_i,noise2_q;
 rrc_resampler data_filter(clk,rst,sample_strobe,cfg[2],mapped_i,mapped_q,data_valid,shaped_i,shaped_q);
 rrc_resampler #(.ROM_FILE("rrc_noise.mem")) n1_filter(
  clk,rst,sample_strobe,cfg[7],$signed({gauss[0],2'b0}),$signed({gauss[1],2'b0}),
  noise_valid1,noise1_i,noise1_q);
 rrc_resampler #(.ROM_FILE("rrc_noise.mem")) n2_filter(
  clk,rst,sample_strobe,cfg[8],$signed({gauss[2],2'b0}),$signed({gauss[3],2'b0}),
  noise_valid2,noise2_i,noise2_q);

 reg [31:0] message_phase,carrier_phase,symbol_phase,offset1,offset2,offset_n;
 reg signed [31:0] fsk_step;
 // Firmware 21: cfg[6] is the centre of the TX1 occupied band for every modulation.
 // SSB: the carrier is a band edge, cfg[4] = signed carrier-to-centre step (+BW/2 USB,
 // -BW/2 LSB). The clean SSB signal (tone at +/-BW/2 from its carrier) rotates by
 // cfg[6]-cfg[4]; TX1 noise rotates by cfg[6], i.e. it is centred on the sideband.
 // Other modes keep offset1==offset_n, so clean+noise rotate together exactly as before.
 wire ssb_mode=cfg[0]==7||cfg[0]==8;
 wire [32:0] symbol_next={1'b0,symbol_phase}+{1'b0,cfg[2]};
 wire signed [15:0] message_sample=sine[message_phase[31:20]];
 wire signed [48:0] fm_delta=$signed({1'b0,cfg[4]})*message_sample;
 wire signed [32:0] fsk_new=$signed(cfg[15])+$signed({1'b0,cfg[5]})*$signed({1'b0,symbol_index});
 wire signed [48:0] am_product=message_sample*$signed({1'b0,cfg[14]});
 reg signed [21:0] analog_i[0:7],analog_q[0:7];
 reg [31:0] mixphase1[0:7],mixphase2[0:7],mixphasen[0:7];
 integer j;
 always @(posedge clk)begin
  if(rst)begin
   message_phase<=0;carrier_phase<=0;symbol_phase<=0;offset1<=0;offset2<=0;offset_n<=0;fsk_step<=cfg[15];
   for(j=0;j<8;j=j+1)begin analog_i[j]<=0;analog_q[j]<=0;mixphase1[j]<=0;mixphase2[j]<=0;mixphasen[j]<=0;end
  end else begin
   if(sample_strobe)begin
    message_phase<=message_phase+cfg[3];symbol_phase<=symbol_next[31:0];
    // Firmware 23: cfg[6] is the carrier for every modulation; SSB TX1 noise sits on the sideband (cfg[6]+cfg[4]).
    offset1<=offset1+cfg[6];offset2<=offset2+cfg[9];
    offset_n<=offset_n+cfg[6]+(ssb_mode?cfg[4]:32'd0);
    if(symbol_next[32])fsk_step<=fsk_new[31:0];
    carrier_phase<=carrier_phase+(cfg[0]==1 ? (fm_delta>>>15) : fsk_step);
    if(cfg[0]==0)begin analog_i[0]<=22'sd16384+(am_product>>>16);analog_q[0]<=0;end
    else if(cfg[0]==6)begin analog_i[0]<=message_sample>>>1;analog_q[0]<=0;end
    else if(cfg[0]==7||cfg[0]==8)begin
     analog_i[0]<=(sine[(message_phase[31:20]+12'd1024)&12'hfff]>>>1)+$signed(cfg[14]);
     analog_q[0]<=cfg[15][0]?-(message_sample>>>1):(message_sample>>>1);
    end
    else begin
     analog_i[0]<=$signed(sine[(carrier_phase[31:20]+12'd1024)&12'hfff])>>>1;
     analog_q[0]<=$signed(sine[carrier_phase[31:20]])>>>1;
    end
    mixphase1[0]<=offset1;mixphase2[0]<=offset2;mixphasen[0]<=offset_n;
   end
   for(j=1;j<8;j=j+1)begin
    analog_i[j]<=analog_i[j-1];analog_q[j]<=analog_q[j-1];
    mixphase1[j]<=mixphase1[j-1];mixphase2[j]<=mixphase2[j-1];mixphasen[j]<=mixphasen[j-1];
   end
  end
 end
 wire signed [21:0] clean_i=(cfg[0]==2||cfg[0]==4||cfg[0]==5)?shaped_i:analog_i[7];
 wire signed [21:0] clean_q=(cfg[0]==2||cfg[0]==4||cfg[0]==5)?shaped_q:analog_q[7];
 reg signed [53:0] clean_scaled_i,clean_scaled_q,noise_scaled_i,noise_scaled_q,n2_scaled_i,n2_scaled_q;
 reg signed [15:0] cos1,sin1,cos2,sin2,cosn,sinn;
 reg signed [31:0] clean_codes_i,clean_codes_q,noise_codes_i,noise_codes_q;
 reg signed [32:0] sum2_i,sum2_q;
 reg signed [15:0] cos1_d,sin1_d,cos2_d,sin2_d,cosn_d,sinn_d;
 reg signed [49:0] rotated1_i,rotated1_q,rotated2_i,rotated2_q;
 reg [3:0] vpipe;
 reg [1:0] gate_pipe[0:3];
 function automatic signed [11:0] sat12(input signed [49:0] x);
  begin if(x>2047)sat12=2047;else if(x< -2048)sat12=-2048;else sat12=x[11:0];end
 endfunction
 wire signed [49:0] out1i=rotated1_i>>>15,out1q=rotated1_q>>>15;
 wire signed [49:0] out2i=rotated2_i>>>15,out2q=rotated2_q>>>15;
 assign sample_valid=vpipe[3];
 assign debug_clean_i=clean_codes_i;assign debug_clean_q=clean_codes_q;
 assign debug_noise_i=noise_codes_i;assign debug_noise_q=noise_codes_q;
 always @(posedge clk)begin
  if(rst)begin
   vpipe<=0;tx1_i<=0;tx1_q<=0;tx2_i<=0;tx2_q<=0;clip_count1<=0;clip_count2<=0;
   for(j=0;j<4;j=j+1)gate_pipe[j]<=0;
  end else begin
   vpipe<={vpipe[2:0],data_valid};
   gate_pipe[0]<={tx2_enable,tx1_enable};
   for(j=1;j<4;j=j+1)gate_pipe[j]<=gate_pipe[j-1];
   // E0: scale components. E1: DAC units. E2: rotate clean and TX1 noise separately, add. E3: saturate.
   if(data_valid)begin
    clean_scaled_i<=clean_i*$signed({1'b0,cfg[10]});clean_scaled_q<=clean_q*$signed({1'b0,cfg[10]});
    noise_scaled_i<=noise1_i*$signed({1'b0,cfg[11]});noise_scaled_q<=noise1_q*$signed({1'b0,cfg[11]});
    n2_scaled_i<=noise2_i*$signed({1'b0,cfg[12]});n2_scaled_q<=noise2_q*$signed({1'b0,cfg[12]});
    cos1<=sine[(mixphase1[7][31:20]+12'd1024)&12'hfff];sin1<=sine[mixphase1[7][31:20]];
    cos2<=sine[(mixphase2[7][31:20]+12'd1024)&12'hfff];sin2<=sine[mixphase2[7][31:20]];
    cosn<=sine[(mixphasen[7][31:20]+12'd1024)&12'hfff];sinn<=sine[mixphasen[7][31:20]];
   end
   if(vpipe[0])begin
    clean_codes_i<=clean_scaled_i>>>30;clean_codes_q<=clean_scaled_q>>>30;
    noise_codes_i<=noise_scaled_i>>>30;noise_codes_q<=noise_scaled_q>>>30;
    sum2_i<=n2_scaled_i>>>30;sum2_q<=n2_scaled_q>>>30;
    cos1_d<=cos1;sin1_d<=sin1;cos2_d<=cos2;sin2_d<=sin2;cosn_d<=cosn;sinn_d<=sinn;
   end
   if(vpipe[1])begin
    rotated1_i<=clean_codes_i*cos1_d-clean_codes_q*sin1_d+noise_codes_i*cosn_d-noise_codes_q*sinn_d;
    rotated1_q<=clean_codes_i*sin1_d+clean_codes_q*cos1_d+noise_codes_i*sinn_d+noise_codes_q*cosn_d;
    rotated2_i<=sum2_i*cos2_d-sum2_q*sin2_d;rotated2_q<=sum2_i*sin2_d+sum2_q*cos2_d;
   end
   if(vpipe[2])begin
    tx1_i<=gate_pipe[2][0]?sat12(out1i):0;tx1_q<=gate_pipe[2][0]?sat12(out1q):0;
    tx2_i<=gate_pipe[2][1]?sat12(out2i):0;tx2_q<=gate_pipe[2][1]?sat12(out2q):0;
    if(gate_pipe[2][0]&&(out1i>2047||out1i< -2048||out1q>2047||out1q< -2048))clip_count1<=clip_count1+1;
    if(gate_pipe[2][1]&&(out2i>2047||out2i< -2048||out2q>2047||out2q< -2048))clip_count2<=clip_count2+1;
   end
  end
 end
endmodule
