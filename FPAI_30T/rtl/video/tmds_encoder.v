`timescale 1ns/1ps
// DVI-compatible TMDS video encoding. No audio, HDMI infoframes or HDCP.
module tmds_encoder(input wire clk,rst,de,c0,c1,input wire [7:0] din,
                    output reg [9:0] dout=10'b1101010100);
 reg [8:0] qm;
 integer i,ones_d,ones_q,balance;
 reg signed [5:0] disparity=0;
 always @* begin
   ones_d=0;
   for(i=0;i<8;i=i+1) ones_d=ones_d+din[i];
   qm[0]=din[0];
   for(i=1;i<8;i=i+1)
     if(ones_d>4 || (ones_d==4 && !din[0])) qm[i]=~(qm[i-1]^din[i]);
     else qm[i]=qm[i-1]^din[i];
   qm[8]=!(ones_d>4 || (ones_d==4 && !din[0]));
   ones_q=0;
   for(i=0;i<8;i=i+1) ones_q=ones_q+qm[i];
   balance=2*ones_q-8;
 end
 always @(posedge clk) begin
   if(rst) begin dout<=10'b1101010100; disparity<=0; end
   else if(!de) begin
     disparity<=0;
     case({c1,c0})
       2'b00:dout<=10'b1101010100;
       2'b01:dout<=10'b0010101011;
       2'b10:dout<=10'b0101010100;
       2'b11:dout<=10'b1010101011;
     endcase
   end else if(disparity==0 || balance==0) begin
     dout<={~qm[8],qm[8],qm[8]?qm[7:0]:~qm[7:0]};
     disparity<=disparity+(qm[8]?balance:-balance);
   end else if((disparity>0 && balance>0)||(disparity<0 && balance<0)) begin
     dout<={1'b1,qm[8],~qm[7:0]};
     disparity<=disparity+2*qm[8]-balance;
   end else begin
     dout<={1'b0,qm[8],qm[7:0]};
     disparity<=disparity-2*(!qm[8])+balance;
   end
 end
endmodule
