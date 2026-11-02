// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Fractional symbol-rate pulse synthesis: 33 symbols, 128 RRC phases.
// Strobes may be irregular, but consecutive symbols can never exceed one/sample.
module rrc_resampler #(parameter ROM_FILE="rrc_data.mem")(
 input wire clk,rst,sample_strobe,input wire [31:0] symbol_step,
 input wire signed [17:0] symbol_i,symbol_q,
 output wire valid,output wire signed [21:0] data_i,data_q
);
 reg [31:0] phase;
 wire [32:0] next_phase={1'b0,phase}+{1'b0,symbol_step};
 reg signed [17:0] history_i[0:32],history_q[0:32];
 reg signed [15:0] coeff[0:4223];
 initial $readmemh(ROM_FILE,coeff);
 reg signed [15:0] coeff_reg[0:32];
 reg signed [17:0] input_i[0:32],input_q[0:32];
 reg signed [39:0] tree_i[0:6][0:63],tree_q[0:6][0:63];
 reg [8:0] valid_pipe;
 integer k;
 always @(posedge clk)begin
  if(rst)begin
   phase<=0;valid_pipe<=0;
   for(k=0;k<33;k=k+1)begin history_i[k]<=0;history_q[k]<=0;end
  end else begin
   valid_pipe<={valid_pipe[7:0],sample_strobe};
   if(sample_strobe)begin
    phase<=next_phase[31:0];
    if(next_phase[32])begin
     history_i[0]<=symbol_i;history_q[0]<=symbol_q;
     for(k=1;k<33;k=k+1)begin history_i[k]<=history_i[k-1];history_q[k]<=history_q[k-1];end
    end
    for(k=0;k<33;k=k+1)begin
     coeff_reg[k]<=coeff[k*128+phase[31:25]];
     input_i[k]<=history_i[k];input_q[k]<=history_q[k];
    end
   end
  end
 end
 genvar t,level;
 generate for(t=0;t<64;t=t+1)begin:mults
  if(t<33)always @(posedge clk)begin
   tree_i[0][t]<=input_i[t]*coeff_reg[t];tree_q[0][t]<=input_q[t]*coeff_reg[t];
  end
  else always @(posedge clk)begin tree_i[0][t]<=0;tree_q[0][t]<=0;end
 end
 for(level=1;level<7;level=level+1)begin:adders
  for(t=0;t<(64>>level);t=t+1)begin:g
   always @(posedge clk)begin
    tree_i[level][t]<=tree_i[level-1][2*t]+tree_i[level-1][2*t+1];
    tree_q[level][t]<=tree_q[level-1][2*t]+tree_q[level-1][2*t+1];
   end
  end
 end endgenerate
 assign valid=valid_pipe[7];
 assign data_i=tree_i[6][0]>>>14;
 assign data_q=tree_q[6][0]>>>14;
endmodule
