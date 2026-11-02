`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/17 09:12:34
// Design Name: 
// Module Name: async_to_sync_reset
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module async_to_sync_reset(
    input async_reset,
    input  clk,
    output sync_reset
    );
reg reset_1d, reset_2d;
always @ (posedge clk or posedge async_reset) begin
if (async_reset) begin
	reset_1d <= 1'b1;
	reset_2d <= 1'b1;
end
else begin
	reset_1d <= async_reset;
	reset_2d <= reset_1d;
end
end

assign sync_reset = reset_2d;
endmodule
