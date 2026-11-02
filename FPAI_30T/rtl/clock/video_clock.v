`timescale 1ns/1ps
// Board reference: 200 MHz differential. VCO = 200 / 10 * 37.125 = 742.5 MHz.
// Pixel = 74.25 MHz; serializer clock = 371.25 MHz, DDR bit rate = 742.5 Mb/s.
module video_clock(input wire sys_clk_p, sys_clk_n, reset,
                   output wire pixel_clk, serial_clk, locked);
  wire ref_clk;
  IBUFDS ref_input(.I(sys_clk_p),.IB(sys_clk_n),.O(ref_clk));
  video_clock_core core(ref_clk,reset,pixel_clk,serial_clk,locked);
endmodule

module video_clock_core #(parameter INPUT_PERIOD=5.0, INPUT_DIV=10)(
 input wire ref_clk,reset,output wire pixel_clk,serial_clk,locked);
  wire fb_raw,fb,pix_raw,ser_raw;
  MMCME2_BASE #(.BANDWIDTH("OPTIMIZED"), .CLKIN1_PERIOD(INPUT_PERIOD),
    .DIVCLK_DIVIDE(INPUT_DIV), .CLKFBOUT_MULT_F(37.125),
    .CLKOUT0_DIVIDE_F(10.0), .CLKOUT1_DIVIDE(2), .STARTUP_WAIT("FALSE")) mmcm (
    .CLKIN1(ref_clk),.RST(reset),.PWRDWN(1'b0),.CLKFBIN(fb),.CLKFBOUT(fb_raw),
    .CLKOUT0(pix_raw),.CLKOUT1(ser_raw),.LOCKED(locked),
    .CLKFBOUTB(),.CLKOUT0B(),.CLKOUT1B(),.CLKOUT2(),.CLKOUT2B(),
    .CLKOUT3(),.CLKOUT3B(),.CLKOUT4(),.CLKOUT5(),.CLKOUT6());
  BUFG fb_buf(.I(fb_raw),.O(fb));
  BUFG pixel_buf(.I(pix_raw),.O(pixel_clk));
  BUFG serial_buf(.I(ser_raw),.O(serial_clk));
endmodule
