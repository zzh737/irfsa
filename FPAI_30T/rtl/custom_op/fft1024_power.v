`timescale 1ns/1ps
// Sequential radix-2 DIT baseline; no vendor FFT IP. One frame at a time.
// s_iq={Q[15:0],I[15:0]}; m_power is natural-order uint32, FFT LSB squared.
// Round nearest/ties away, saturate16, scale32767, divide2 at every stage.
module fft1024_power(
 input wire clk,rst,start,window_hann,
 input wire [31:0] s_iq,input wire s_valid,output wire s_ready,
 output wire [31:0] m_power,output wire m_valid,input wire m_ready,
 output wire m_last,output reg busy,done);
 `include "fft_tables.vh"

 function [9:0] reverse10;
 input [9:0] value;
 integer n;
 begin for(n=0;n<10;n=n+1)reverse10[n]=value[9-n];end
 endfunction

 // Exact round(x/32767), avoiding a general divider. For all products here,
 // |x|<=2^31. Write rounded magnitude as high*32768+low; the quotient is
 // high+floor((high+low)/32767), whose correction is at most 3.
 function [33:0] round_magnitude;
 input signed [33:0] value;
 reg [33:0] magnitude;
 begin
   magnitude=value[33] ? -value : value;
   round_magnitude=magnitude+34'd16383;
 end endfunction

 function signed [15:0] round_finish;
 input [18:0] high;
 input [19:0] folded;
 input negative;
 reg [19:0] quotient;
 begin
   if(folded>=20'd98301)quotient={1'b0,high}+20'd3;
   else if(folded>=20'd65534)quotient={1'b0,high}+20'd2;
   else if(folded>=20'd32767)quotient={1'b0,high}+20'd1;
   else quotient=high;
   if(negative)begin
     if(quotient>=20'd32768)round_finish=16'sh8000;
     else round_finish=-$signed(quotient[15:0]);
   end else begin
     if(quotient>20'd32767)round_finish=16'sh7fff;
     else round_finish=quotient[15:0];
   end
 end endfunction

 function signed [15:0] half_round;
 input signed [16:0] value;
 reg [16:0] magnitude,quotient;
 begin
   magnitude=value[16] ? -value : value;
   quotient=(magnitude+17'd1)>>1;
   if(value[16])begin
     if(quotient>=17'd32768)half_round=16'sh8000;
     else half_round=-$signed(quotient[15:0]);
   end else begin
     if(quotient>17'd32767)half_round=16'sh7fff;
     else half_round=quotient[15:0];
   end
 end endfunction

 localparam IDLE=0,LOAD=1,WINDOW_MUL=2,WINDOW_STORE=3,
   READ_A=4,READ_B=5,MULTIPLY=6,COMBINE=7,ROUND=8,
   WRITE_A=9,WRITE_B=10,POWER_READ=11,POWER_MUL=12,POWER_SUM=13,OUTPUT=14,WINDOW_ROUND=15,
   ROUND_FOLD=16,ROUND_STORE=17,READ_B_CAPTURE=18,POWER_CAPTURE=19;
 reg [4:0] state=IDLE;
 // Single synchronous read/write port, allowing block-memory inference.
 // RAM contents are overwritten by every complete frame; do not reset the RAM.
 reg [9:0] load_index,half_span,offset,power_index;
 reg [10:0] base;
 reg [3:0] twiddle_shift;
 wire [9:0] address_a=base[9:0]+offset;
 wire [9:0] address_b=address_a+half_span;
 wire [9:0] twiddle_index=offset<<twiddle_shift;
 reg hann;
 reg signed [15:0] raw_i,raw_q,coefficient,wr,wi,ar,ai,tr,ti;
 reg signed [31:0] window_i,window_q,p0,p1,p2,p3;
 reg [31:0] window_rounded;
 // Shared exact rounding pipeline: magnitude, fold, then correction/saturation.
 reg [33:0] rounded_re,rounded_im;
 reg [18:0] round_high_re,round_high_im;
 reg [19:0] round_fold_re,round_fold_im;
 reg round_negative_re,round_negative_im,round_window;
 reg signed [33:0] full_re,full_im;
 reg [31:0] power_r,power_i,power_value;
 wire [31:0] ram_q;
 reg signed [15:0] br,bi;
 wire signed [16:0] sum_re=$signed({ar[15],ar})+$signed({tr[15],tr});
 wire signed [16:0] sum_im=$signed({ai[15],ai})+$signed({ti[15],ti});
 wire signed [16:0] diff_re=$signed({ar[15],ar})-$signed({tr[15],tr});
 wire signed [16:0] diff_im=$signed({ai[15],ai})-$signed({ti[15],ti});
 assign s_ready=state==LOAD && !rst;
 assign m_valid=state==OUTPUT && !rst;
 assign m_power=power_value;
 assign m_last=power_index==1023;

 // One explicit physical read port and one write port. State-gated reads into
 // three separate output registers otherwise infer three read ports in 2018.3.
 wire ram_we=!rst && (state==WINDOW_STORE || state==WRITE_A || state==WRITE_B);
 wire [9:0] ram_waddr=state==WINDOW_STORE ? reverse10(load_index) :
                         state==WRITE_A ? address_a : address_b;
 wire [31:0] ram_wdata=state==WINDOW_STORE ? (hann ? window_rounded :
   {raw_q,raw_i}) : state==WRITE_A ?
   {half_round(sum_im),half_round(sum_re)} : {half_round(diff_im),half_round(diff_re)};
 wire ram_re=!rst && (state==READ_A || state==READ_B || state==POWER_READ);
 wire [9:0] ram_raddr=state==READ_A ? address_a : state==READ_B ? address_b : power_index;
 fft_sample_ram u_samples(clk,ram_we,ram_waddr,ram_wdata,ram_re,ram_raddr,ram_q);

 always @(posedge clk) begin
   if(rst)begin
     state<=IDLE;busy<=0;done<=0;load_index<=0;hann<=0;
     half_span<=1;offset<=0;base<=0;twiddle_shift<=9;power_index<=0;
     power_value<=0;
   end else begin
     done<=0;
     case(state)
       IDLE:if(start)begin
         busy<=1;hann<=window_hann;load_index<=0;state<=LOAD;
       end
       LOAD:if(s_valid)begin
         raw_i<=$signed(s_iq[15:0]);raw_q<=$signed(s_iq[31:16]);
         coefficient<=hann_coefficient(load_index);state<=WINDOW_MUL;
       end
       WINDOW_MUL:begin
         window_i<=raw_i*coefficient;window_q<=raw_q*coefficient;
         state<=WINDOW_ROUND;
       end
       WINDOW_ROUND:begin
         rounded_re<=round_magnitude({{2{window_i[31]}},window_i});
         rounded_im<=round_magnitude({{2{window_q[31]}},window_q});
         round_negative_re<=window_i[31];round_negative_im<=window_q[31];
         round_window<=1;state<=ROUND_FOLD;
       end
       WINDOW_STORE:begin
         if(load_index==1023)begin
           half_span<=1;base<=0;offset<=0;twiddle_shift<=9;state<=READ_A;
         end else begin load_index<=load_index+1'b1;state<=LOAD;end
       end
       READ_A:begin state<=READ_B;end
       READ_B:begin
         {ai,ar}<=ram_q;
         wr<=twiddle_re(twiddle_index);wi<=twiddle_im(twiddle_index);
         state<=READ_B_CAPTURE;
       end
       READ_B_CAPTURE:begin
         {bi,br}<=ram_q;state<=MULTIPLY;
       end
       MULTIPLY:begin
         p0<=br*wr;p1<=bi*wi;p2<=br*wi;p3<=bi*wr;state<=COMBINE;
       end
       COMBINE:begin
         full_re<=$signed({{2{p0[31]}},p0})-$signed({{2{p1[31]}},p1});
         full_im<=$signed({{2{p2[31]}},p2})+$signed({{2{p3[31]}},p3});
         state<=ROUND;
       end
       ROUND:begin
         rounded_re<=round_magnitude(full_re);rounded_im<=round_magnitude(full_im);
         round_negative_re<=full_re[33];round_negative_im<=full_im[33];
         round_window<=0;state<=ROUND_FOLD;
       end
       ROUND_FOLD:begin
         round_high_re<=rounded_re[33:15];round_high_im<=rounded_im[33:15];
         round_fold_re<={1'b0,rounded_re[33:15]}+{5'b0,rounded_re[14:0]};
         round_fold_im<={1'b0,rounded_im[33:15]}+{5'b0,rounded_im[14:0]};
         state<=ROUND_STORE;
       end
       ROUND_STORE:begin
         if(round_window)begin
           window_rounded<={round_finish(round_high_im,round_fold_im,round_negative_im),
                            round_finish(round_high_re,round_fold_re,round_negative_re)};
           state<=WINDOW_STORE;
         end else begin
           tr<=round_finish(round_high_re,round_fold_re,round_negative_re);
           ti<=round_finish(round_high_im,round_fold_im,round_negative_im);state<=WRITE_A;
         end
       end
       WRITE_A:begin
         state<=WRITE_B;
       end
       WRITE_B:begin
         if(offset+1<half_span)begin offset<=offset+1'b1;state<=READ_A;end
         else if(base+({1'b0,half_span}<<1)<1024)begin
           offset<=0;base<=base+({1'b0,half_span}<<1);state<=READ_A;
         end else if(half_span==512)begin power_index<=0;state<=POWER_READ;end
         else begin
           half_span<=half_span<<1;twiddle_shift<=twiddle_shift-1'b1;
           base<=0;offset<=0;state<=READ_A;
         end
       end
       POWER_READ:begin state<=POWER_CAPTURE;end
       POWER_CAPTURE:begin {bi,br}<=ram_q;state<=POWER_MUL;end
       POWER_MUL:begin
         power_r<=br*br;power_i<=bi*bi;
         state<=POWER_SUM;
       end
       POWER_SUM:begin power_value<=power_r+power_i;state<=OUTPUT;end
       OUTPUT:if(m_ready)begin
         if(power_index==1023)begin busy<=0;done<=1;state<=IDLE;end
         else begin power_index<=power_index+1'b1;state<=POWER_READ;end
       end
       default:begin state<=IDLE;busy<=0;end
     endcase
   end
 end
endmodule

// Preserve the RAM boundary so synthesis cannot move its read register into
// the downstream DSP multipliers before it recognizes the synchronous RAM.
(* keep_hierarchy="yes" *)
module fft_sample_ram(
 input wire clk,we,input wire [9:0] waddr,input wire [31:0] wdata,
 input wire re,input wire [9:0] raddr,output reg [31:0] q
);
 (* ram_style="block" *) reg [31:0] samples[0:1023];
 always @(posedge clk) begin
   if(we) samples[waddr]<=wdata;
   if(re) q<=samples[raddr];
 end
endmodule
