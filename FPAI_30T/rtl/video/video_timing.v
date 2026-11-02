`timescale 1ns/1ps
// Active video starts at (0,0); positive H/V sync for CEA 720p60.
module video_timing #(
  parameter H_ACTIVE=1280, H_FP=110, H_SYNC=40, H_BP=220,
  parameter V_ACTIVE=720, V_FP=5, V_SYNC=5, V_BP=20
)(input wire clk, rst, output reg [11:0] x=0, y=0,
  output wire de, hsync, vsync);
  localparam H_TOTAL=H_ACTIVE+H_FP+H_SYNC+H_BP;
  localparam V_TOTAL=V_ACTIVE+V_FP+V_SYNC+V_BP;
  always @(posedge clk)
    if(rst) begin x<=0; y<=0; end
    else if(x==H_TOTAL-1) begin
      x<=0; if(y==V_TOTAL-1) y<=0; else y<=y+1'b1;
    end else x<=x+1'b1;
  assign de=(x<H_ACTIVE)&&(y<V_ACTIVE);
  assign hsync=(x>=H_ACTIVE+H_FP)&&(x<H_ACTIVE+H_FP+H_SYNC);
  assign vsync=(y>=V_ACTIVE+V_FP)&&(y<V_ACTIVE+V_FP+V_SYNC);
endmodule
