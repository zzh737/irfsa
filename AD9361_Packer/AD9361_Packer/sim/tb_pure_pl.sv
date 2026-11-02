`timescale 1ns/1ps
module tb_pure_pl;
 reg clk=0,rst=1;
 always #4 clk=~clk;
 wire cs,sck,mosi;
 reg miso=0;
 wire done,fault,resetb;
 wire [15:0] index;
 wire [7:0] last_read;
 ad9361_init_sequencer #(.ROM_FILE("seq_test.mem"),.WORDS(6),
  .HALF_PERIOD(2),.RESET_CYCLES(4)) dut(
  .clk(clk),.rst(rst),.spi_cs_n(cs),.spi_sclk(sck),.spi_mosi(mosi),
  .spi_miso(miso),.resetb(resetb),.done(done),.fault(fault),
  .script_index(index),.last_read(last_read));
 reg [7:0] regs[0:1023];
 integer bitpos=0,transactions=0;
 reg [23:0] command=0;
 reg [15:0] head=0;
 always @(negedge cs)begin bitpos=0;command=0;end
 always @(posedge sck)begin
  if(!cs)begin
   if(bitpos>=16 && !head[15])miso=regs[head[9:0]][23-bitpos];
   else miso=0;
  end
 end
 always @(negedge sck)begin
  if(!cs)begin
   command={command[22:0],mosi};
   if(bitpos==15)head=command[15:0];
   bitpos=bitpos+1;
  end
 end
 always @(posedge cs)begin
  if(!rst&&bitpos)begin
   if(bitpos!=24)$fatal(1,"SPI frame length %d",bitpos);
   if(command[22:18]!=0)$fatal(1,"SPI reserved/header bits");
   if(command[23])regs[command[17:8]]=command[7:0];
   transactions=transactions+1;
  end
 end
 wire bad_done,bad_fault;
 ad9361_init_sequencer #(.ROM_FILE("seq_timeout.mem"),.WORDS(2),
  .HALF_PERIOD(2),.RESET_CYCLES(4)) bad(
  .clk(clk),.rst(rst),.spi_cs_n(),.spi_sclk(),.spi_mosi(),.spi_miso(1'b0),
  .resetb(),.done(bad_done),.fault(bad_fault),.script_index(),.last_read());
 reg enable=0,strobe=0;
 wire signed [11:0] iv,qv;
 iq_test_tone tone(.clk(clk),.rst(rst),.enable(enable),.sample_strobe(strobe),
  .sample_i(iv),.sample_q(qv));
 integer i;
 reg signed [11:0] saved_i[0:31],saved_q[0:31];
 initial begin
  for(i=0;i<1024;i++)regs[i]=0;
  regs['h37]=8'h08;
  repeat(5)@(negedge clk);rst=0;
  wait(done||fault);
  if(fault||!done||regs['h123]!=8'hfa||transactions!=5)
   $fatal(1,"sequence/RMW failed value=%h transactions=%d index=%d",regs['h123],transactions,index);
  wait(bad_fault);
  if(bad_done)$fatal(1,"timeout incorrectly returned done");
  $display("PASS SPI write/read, masked read-modify-write, polls, delay, timeout");
  @(negedge clk);enable=1;strobe=1;
  for(i=0;i<64;i++)begin
   @(negedge clk);
   if(i<32)begin saved_i[i]=iv;saved_q[i]=qv;end
   else if(iv!==saved_i[i%32]||qv!==saved_q[i%32])$fatal(1,"tone period");
  end
  if(saved_i[0]!=1024||saved_q[0]!=0||saved_i[8]!=0||saved_q[8]!=1024)
   $fatal(1,"tone IQ orientation");
  strobe=0;
  repeat(4)begin @(negedge clk);if(iv!==saved_i[31]||qv!==saved_q[31])$fatal(1,"tone stalled");end
  enable=0;@(negedge clk);if(iv||qv)$fatal(1,"TX disable");
  $display("PASS tone periodicity, IQ orientation, strobe hold and disable");
  $display("ALL PURE PL UNIT TESTS PASSED");$finish;
 end
 initial begin #200000;$fatal(1,"simulation watchdog");end
endmodule
