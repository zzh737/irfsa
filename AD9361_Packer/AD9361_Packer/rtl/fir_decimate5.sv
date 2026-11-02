// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Parallel-bank MAC FIR, one complex sample/5 input samples, Q17 taps.
// Input spacing must leave TAPS/LANES+5 clocks between output computations.
module fir_decimate5 #(parameter LOG_TAPS=7,LANES=8,ROM_FILE="decim1.mem")(
 input wire clk,rst,valid,input wire signed [15:0] i,q,
 output reg out_valid,output reg signed [15:0] out_i,out_q,output reg fault,
 input wire clipped,output reg out_clipped
);
 localparam TAPS=1<<LOG_TAPS,GROUPS=TAPS/LANES;
 (* ram_style="distributed" *) reg signed [15:0] hist_i[0:TAPS-1],hist_q[0:TAPS-1];
 reg signed [17:0] coef[0:TAPS-1];initial $readmemh(ROM_FILE,coef);
 reg [LOG_TAPS-1:0] wr_ptr,newest;reg [LOG_TAPS:0] filled;
 reg [2:0] phase;reg busy,emit;reg [LOG_TAPS-1:0] group_index;
 reg p0,p1,first0,first1,last0,last1;
 reg signed [15:0] r_i[0:LANES-1],r_q[0:LANES-1];
 reg signed [17:0] r_c[0:LANES-1];
 reg signed [33:0] prod_i[0:LANES-1],prod_q[0:LANES-1];
 reg signed [47:0] acc_i[0:LANES-1],acc_q[0:LANES-1];
 reg signed [47:0] sum_i,sum_q;
 reg [TAPS-1:0] clip_history;
 reg pending_clip;
 always @*begin
  sum_i=48'sd65536;sum_q=48'sd65536;
  for(integer k=0;k<LANES;k=k+1)begin sum_i=sum_i+acc_i[k];sum_q=sum_q+acc_q[k];end
 end
 function automatic signed [15:0] round_sat(input signed [47:0] x);
  reg signed [47:0] y;begin y=x>>>17;
   round_sat=y>32767?16'sh7fff:(y< -32768?16'sh8000:y[15:0]);
  end
 endfunction
 always @(posedge clk)begin
  out_valid<=0;p0<=0;p1<=p0;first1<=first0;last1<=last0;emit<=0;
  for(integer k=0;k<LANES;k=k+1)begin
   if(busy)begin
    // Read oldest history first, before following input samples overwrite it.
    r_i[k]<=hist_i[(newest-(TAPS-1-group_index*LANES-k))&(TAPS-1)];
    r_q[k]<=hist_q[(newest-(TAPS-1-group_index*LANES-k))&(TAPS-1)];
    r_c[k]<=coef[TAPS-1-group_index*LANES-k];
   end
   if(p0)begin prod_i[k]<=r_i[k]*r_c[k];prod_q[k]<=r_q[k]*r_c[k];end
   if(p1)begin acc_i[k]<=first1?prod_i[k]:acc_i[k]+prod_i[k];acc_q[k]<=first1?prod_q[k]:acc_q[k]+prod_q[k];end
  end
  if(busy)begin
   p0<=1;first0<=group_index==0;last0<=group_index==GROUPS-1;
   if(group_index==GROUPS-1)busy<=0;else group_index<=group_index+1;
  end
  if(p1&&last1)emit<=1;
  if(emit)begin
   out_i<=round_sat(sum_i);out_q<=round_sat(sum_q);out_valid<=1;
   out_clipped<=pending_clip||(sum_i>>>17)>32767||(sum_i>>>17)< -32768||
                            (sum_q>>>17)>32767||(sum_q>>>17)< -32768;
  end
  if(valid)begin
   clip_history<={clip_history[TAPS-2:0],clipped};
   hist_i[wr_ptr]<=i;hist_q[wr_ptr]<=q;wr_ptr<=wr_ptr+1;
   if(filled<TAPS)filled<=filled+1;
   if(phase==4)begin
    phase<=0;
    if(filled>=TAPS-1)begin
     if(busy||p0||p1||emit)fault<=1;
     else begin
      newest<=wr_ptr;group_index<=0;busy<=1;
      pending_clip<=(|clip_history[TAPS-2:0])||clipped;
     end
    end
   end else phase<=phase+1;
  end
  if(rst)begin
   out_valid<=0;out_i<=0;out_q<=0;fault<=0;wr_ptr<=0;newest<=0;filled<=0;phase<=0;
   clip_history<=0;pending_clip<=0;out_clipped<=0;
   busy<=0;emit<=0;group_index<=0;p0<=0;p1<=0;first0<=0;first1<=0;last0<=0;last1<=0;
   for(integer k=0;k<LANES;k=k+1)begin acc_i[k]<=0;acc_q[k]<=0;end
  end
 end
endmodule
