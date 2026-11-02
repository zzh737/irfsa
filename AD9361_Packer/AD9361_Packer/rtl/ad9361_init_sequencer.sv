// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Fixed hardware state machine, not an instruction-set processor.
// ROM is embedded into FPGA configuration: no SD card / ELF / CPU.
// Word: opcode[63:60], address[59:48], value[47:40], mask[39:32], cycles[31:0].
// 1 WRITE, 2 POLL_EQ (bounded), 3 DELAY, 4 READ_MASK_WRITE, F END.
// READ_MASK_WRITE preserves bits for which mask=0 and uses value for mask=1.
// done means only that the supplied script finished; RF readiness additionally
// requires a complete qualified profile and digital-interface checks.
module ad9361_init_sequencer #(
 parameter ROM_FILE="ad9361_probe.mem", WORDS=3, HALF_PERIOD=32,
 parameter RESET_CYCLES=1250000
) (
 input wire clk, rst,
 output wire spi_cs_n, spi_sclk, spi_mosi, input wire spi_miso,
 output wire resetb,
 output reg done, fault,
 output reg [15:0] script_index,
 output reg [7:0] last_read
);
 reg [63:0] rom[0:WORDS-1];
 initial $readmemh(ROM_FILE,rom);
 reg [3:0] state;
 localparam HOLD=0, RELEASE=1, FETCH=2, DECODE=3, LAUNCH=4,
            WAIT_SPI=5, CHECK=6, DELAY=7, FINISH=8, FAILED=9,
            RMW_LAUNCH=10,RMW_WAIT=11;
 reg [63:0] cmd;
 reg [31:0] timer, elapsed;
 reg start,write;
 reg [7:0] write_data;
 wire [7:0] read_data;
 wire busy, spi_done;
 assign resetb=state!=HOLD;
 ad9361_spi #(.HALF_PERIOD(HALF_PERIOD)) spi(
  .clk(clk),.rst(rst),.start(start),.write(write),.address(cmd[57:48]),
  .write_data(write_data),.read_data(read_data),.busy(busy),.done(spi_done),
  .cs_n(spi_cs_n),.sclk(spi_sclk),.mosi(spi_mosi),.miso(spi_miso));
 task automatic advance;
  begin
   if(script_index+1>=WORDS) begin fault<=1;state<=FAILED;end
   else begin script_index<=script_index+1;state<=FETCH;end
  end
 endtask
 always @(posedge clk) begin
  start<=0;
  if(rst) begin
   state<=HOLD;timer<=RESET_CYCLES;elapsed<=0;cmd<=0;
   script_index<=0;done<=0;fault<=0;last_read<=0;write<=0;write_data<=0;
  end else begin
   if(state==LAUNCH||state==WAIT_SPI||state==CHECK) begin
    if(elapsed!=32'hffffffff)elapsed<=elapsed+1;
   end
   case(state)
    HOLD: if(timer!=0)timer<=timer-1;else begin timer<=RESET_CYCLES;state<=RELEASE;end
    RELEASE: if(timer!=0)timer<=timer-1;else state<=FETCH;
    FETCH: begin cmd<=rom[script_index];state<=DECODE;elapsed<=0;end
    DECODE: begin
     if(cmd[59:58]!=0)begin fault<=1;state<=FAILED;end
     else case(cmd[63:60])
      1,2,4: begin write<=cmd[63:60]==1;write_data<=cmd[47:40];state<=LAUNCH;end
      3: begin timer<=cmd[31:0];state<=DELAY;end
      15: begin done<=1;state<=FINISH;end
      default:begin fault<=1;state<=FAILED;end
     endcase
    end
    LAUNCH: if(!busy)begin start<=1;state<=WAIT_SPI;end
    WAIT_SPI: if(spi_done)begin last_read<=read_data;state<=CHECK;end
    CHECK: begin
     if(cmd[63:60]==1)advance();
     else if(cmd[63:60]==4)begin
      write_data<=(last_read&~cmd[39:32])|(cmd[47:40]&cmd[39:32]);
      write<=1;state<=RMW_LAUNCH;
     end else if((last_read&cmd[39:32])==(cmd[47:40]&cmd[39:32]))advance();
     else if(elapsed>=cmd[31:0])begin fault<=1;state<=FAILED;end
     else state<=LAUNCH;
    end
    RMW_LAUNCH: if(!busy)begin start<=1;state<=RMW_WAIT;end
    RMW_WAIT: if(spi_done)advance();
    DELAY: if(timer!=0)timer<=timer-1;else advance();
    FINISH: state<=FINISH;
    FAILED: begin done<=0;state<=FAILED;end
    default:begin fault<=1;state<=FAILED;end
   endcase
  end
 end
endmodule
