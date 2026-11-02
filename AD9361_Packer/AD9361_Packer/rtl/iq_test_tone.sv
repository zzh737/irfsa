// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// A 32-point complex sinusoid. At 4 MSPS its baseband frequency is +125 kHz.
// sample_strobe comes from the AD9361 transmit framing logic, not a guessed
// FPGA-clock divider, so the waveform always follows the real DAC sample rate.
module iq_test_tone (
 input wire clk,rst,enable,sample_strobe,
 output reg signed [11:0] sample_i,sample_q
);
 reg [4:0] phase;
 function automatic signed [11:0] sine(input [4:0] p);
  begin case(p)
   0:sine=0;1:sine=200;2:sine=392;3:sine=569;
   4:sine=724;5:sine=851;6:sine=946;7:sine=1004;
   8:sine=1024;9:sine=1004;10:sine=946;11:sine=851;
   12:sine=724;13:sine=569;14:sine=392;15:sine=200;
   16:sine=0;17:sine=-200;18:sine=-392;19:sine=-569;
   20:sine=-724;21:sine=-851;22:sine=-946;23:sine=-1004;
   24:sine=-1024;25:sine=-1004;26:sine=-946;27:sine=-851;
   28:sine=-724;29:sine=-569;30:sine=-392;31:sine=-200;
  endcase end
 endfunction
 always @(posedge clk)begin
  if(rst||!enable)begin phase<=0;sample_i<=0;sample_q<=0;end
  else if(sample_strobe)begin
   sample_i<=sine(phase+5'd8);sample_q<=sine(phase);phase<=phase+1;
  end
 end
endmodule
