// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// AD9361 4-wire SPI, CPOL=0 / CPHA=1. No processor or software required.
// start is a pulse, accepted only when busy=0. done is a one-clock pulse.
module ad9361_spi #(parameter HALF_PERIOD=32) (
 input wire clk, rst, start, write,
 input wire [9:0] address,
 input wire [7:0] write_data,
 output reg [7:0] read_data,
 output reg busy, done,
 output reg cs_n, sclk, mosi,
 input wire miso
);
 localparam CW=$clog2(HALF_PERIOD+1);
 reg [CW-1:0] divider;
 reg [23:0] shift;
 reg [7:0] received;
 reg [4:0] bit_count;
 reg finish;
 always @(posedge clk) begin
  done<=0;
  if(rst) begin
   divider<=0;shift<=0;received<=0;bit_count<=0;finish<=0;
   read_data<=0;busy<=0;done<=0;cs_n<=1;sclk<=0;mosi<=0;
  end else if(!busy) begin
   if(start) begin
    shift<={write,5'b0,address,write_data};received<=0;bit_count<=0;
    divider<=HALF_PERIOD-1;busy<=1;cs_n<=0;sclk<=0;finish<=0;
   end
  end else if(divider!=0) divider<=divider-1;
  else begin
   divider<=HALF_PERIOD-1;
   if(finish) begin
    cs_n<=1;busy<=0;done<=1;read_data<=received;mosi<=0;
   end else if(!sclk) begin
    sclk<=1;mosi<=shift[23];shift<={shift[22:0],1'b0};
   end else begin
    sclk<=0;received<={received[6:0],miso};
    if(bit_count==23) finish<=1;
    else bit_count<=bit_count+1;
   end
  end
 end
endmodule
