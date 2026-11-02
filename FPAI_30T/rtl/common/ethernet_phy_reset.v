`timescale 1ns/1ps
// Hold YT8521 reset low for 20 ms after the 100 MHz GP clock becomes stable.
// Reset assertion is asynchronous; deassertion is synchronized before counting.
module ethernet_phy_reset #(
  parameter integer HOLD_CYCLES = 2000000
)(
  input wire clk,
  input wire arst,
  output reg reset_n = 1'b0
);
  wire rst;
  reset_sync u_reset_sync(.clk(clk), .arst(arst), .rst(rst));
  localparam integer WIDTH = (HOLD_CYCLES < 2) ? 1 : $clog2(HOLD_CYCLES);
  reg [WIDTH-1:0] count = 0;
  always @(posedge clk or posedge arst) begin
    if (arst) begin count <= 0; reset_n <= 1'b0; end
    else if (rst) begin count <= 0; reset_n <= 1'b0; end
    else if (!reset_n) begin
      if (count == HOLD_CYCLES-1) reset_n <= 1'b1;
      else count <= count + 1'b1;
    end
  end
endmodule
