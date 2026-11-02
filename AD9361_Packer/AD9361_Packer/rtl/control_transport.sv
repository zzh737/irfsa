// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Fair request arbitration and per-response routing, including deferred replies.
module control_transport #(parameter CLOCK_HZ=125000000,BAUD=115200)(
 input wire clk,rst,uart_rx,output wire uart_tx,
 input wire net_command_valid,output wire net_command_ready,
 input wire [1023:0] net_command_bytes,input wire [15:0] net_command_length,
 output wire command_valid,input wire command_ready,output wire command_uart,
 output wire [1023:0] command_bytes,output wire [15:0] command_length,
 input wire reply_uart,hdr_valid,output wire hdr_ready,input wire [15:0] reply_length,
 input wire [7:0] data,input wire valid,output wire ready,input wire last,
 output wire net_hdr_valid,input wire net_hdr_ready,output wire [15:0] net_length,
 output wire [7:0] net_data,output wire net_valid,input wire net_ready,output wire net_last
);
 wire [7:0] rx_data;wire rx_valid,rx_error,serial_ready;
 wire uart_command_valid,uart_command_ready;
 wire [1023:0] uart_command_bytes;wire [15:0] uart_command_length;
 wire [31:0] bad_frames;
 uart_phy #(.CLOCK_HZ(CLOCK_HZ),.BAUD(BAUD)) phy(
  .clk(clk),.rst(rst),.rx(uart_rx),.tx(uart_tx),.rx_data(rx_data),.rx_valid(rx_valid),.rx_error(rx_error),
  .tx_data(data),.tx_valid(valid&&reply_uart),.tx_ready(serial_ready));
 uart_command_rx #(.CLOCK_HZ(CLOCK_HZ)) receiver(
  .clk(clk),.rst(rst),.data(rx_data),.valid(rx_valid),.framing_error(rx_error),
  .command_valid(uart_command_valid),.command_ready(uart_command_ready),
  .command_bytes(uart_command_bytes),.command_length(uart_command_length),.bad_frames(bad_frames));
 reg prefer_uart;
 wire select_uart=uart_command_valid&&(!net_command_valid||prefer_uart);
 assign command_uart=select_uart;
 assign command_valid=select_uart?uart_command_valid:net_command_valid;
 assign command_bytes=select_uart?uart_command_bytes:net_command_bytes;
 assign command_length=select_uart?uart_command_length:net_command_length;
 assign uart_command_ready=command_ready&&select_uart;
 assign net_command_ready=command_ready&&!select_uart;
 always @(posedge clk)if(rst)prefer_uart<=1;
  else if(command_valid&&command_ready)prefer_uart<=!select_uart;
 assign net_hdr_valid=hdr_valid&&!reply_uart;
 assign hdr_ready=reply_uart?1'b1:net_hdr_ready;
 assign net_length=reply_length;
 assign net_data=data;assign net_last=last;assign net_valid=valid&&!reply_uart;
 assign ready=reply_uart?serial_ready:net_ready;
endmodule
