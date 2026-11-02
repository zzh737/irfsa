// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
// Probe strapped addresses and configure RTL8211F for 10/100/1000 Mbps.
module rtl8211f_init #(parameter START_CYCLES=25000000,RETRY_CYCLES=125000000)(
 input wire clk,rst,output wire mdc,inout wire mdio,
 output reg configured,fault,link_up,output wire [255:0] diagnostics,
 output wire [31:0] wire_diagnostics
);
 localparam WAIT_START=0,PREPARE=1,ISSUE=2,TRANSFER=3,WAIT_POLL=4,RETRY=15;
 reg [3:0] state;
 reg [4:0] index,reg_addr,phy_addr;
 reg [15:0] value,mask,last_read,id1,id2,control,advertisement,gigabit,phy_status;
 reg [1:0] op;
 reg [7:0] error_code;
 reg [31:0] timer,reset_timer;
 reg command_valid,seen_busy;
 wire command_ready,busy,read_valid,read_ack;wire [15:0] read_data;
 wire mdio_o,mdio_t;
 (* ASYNC_REG="TRUE" *) reg [1:0] mdio_sync;
 always @(posedge clk)if(rst)mdio_sync<=3;else mdio_sync<={mdio_sync[0],mdio};
 // The schematic has pull-ups on both sides of a bidirectional MOSFET.
 // Release a one instead of driving against a PHY response.
 assign mdio=(mdio_t||mdio_o)?1'bz:1'b0;
 // 250 kHz, with 1 us high/low data margin around each MDC edge.
 ku5p_clause22 master(.clk(clk),.rst(rst),.cmd_phy_addr(phy_addr),.cmd_reg_addr(reg_addr),
  .cmd_data(value),.cmd_opcode(op),.cmd_valid(command_valid),.cmd_ready(command_ready),
  .data_out(read_data),.data_out_valid(read_valid),.data_out_ready(1'b1),
  .mdc_o(mdc),.mdio_i(mdio_sync[1]),.mdio_o(mdio_o),.mdio_t(mdio_t),.busy(busy),.read_ack(read_ack),
  .diagnostics(wire_diagnostics));
 assign diagnostics={32'd1,{15'd0,configured,fault,link_up,phy_addr,index,state},
  {id1,id2},{11'd0,reg_addr,last_read},{control,advertisement},
  {gigabit,phy_status},{24'd0,error_code},timer};
 task automatic fail(input [7:0] reason);
  begin fault<=1;configured<=0;link_up<=0;error_code<=reason;
   command_valid<=0;timer<=RETRY_CYCLES;state<=RETRY;end
 endtask
 task automatic next_address;
  begin
   index<=21;
   if(phy_addr==31)fail(1);
   else begin phy_addr<=phy_addr+1;state<=PREPARE;end
  end
 endtask
 always @(posedge clk)begin
  if(rst)begin
   state<=WAIT_START;index<=21;timer<=START_CYCLES;reset_timer<=0;command_valid<=0;
   configured<=0;fault<=0;link_up<=0;phy_addr<=0;reg_addr<=0;value<=0;mask<=0;
   op<=0;seen_busy<=0;last_read<=0;id1<=0;id2<=0;control<=0;
   advertisement<=0;gigabit<=0;phy_status<=0;error_code<=0;
  end else begin
   if(command_valid&&command_ready)command_valid<=0;
   if(reset_timer!=0)reset_timer<=reset_timer-1;
   case(state)
    WAIT_START:if(timer!=0)timer<=timer-1;else state<=PREPARE;
    PREPARE:begin
     op<=2;mask<=16'hffff;value<=0;state<=ISSUE;
     case(index)
      0:reg_addr<=2;
      1:reg_addr<=3;
      2:begin reg_addr<=0;value<=16'h8000;op<=1;reset_timer<=125000000;end
      3:reg_addr<=0;
      4:begin reg_addr<=31;value<=0;op<=1;end
      5:begin reg_addr<=31;value<=16'h0d08;op<=1;end
      6:reg_addr<=17;
      7:begin reg_addr<=17;value<=last_read&16'hfeff;op<=1;end
      8:begin reg_addr<=17;mask<=16'h0100;end
      9:reg_addr<=21;
      10:begin reg_addr<=21;value<=last_read|16'h0008;op<=1;end
      11:begin reg_addr<=21;value<=8;mask<=8;end
      12:begin reg_addr<=31;value<=0;op<=1;end
        // Advertise 10/100 full/half duplex as well as gigabit.  The
        // original image advertised gigabit only (0x0001 in the masked
        // write), which prevents a 100-Mbps-only peer such as 悟净 from
        // completing autonegotiation.
        13:begin reg_addr<=4;value<=16'h01e1;op<=1;end
      14:begin reg_addr<=9;value<=16'h0200;op<=1;end
      15:begin reg_addr<=0;value<=16'h1200;op<=1;end
       16:begin reg_addr<=4;value<=16'h01e1;mask<=16'h01e1;end
      17:begin reg_addr<=9;value<=16'h0200;mask<=16'h0300;end
      18,19:reg_addr<=1;
      // RTL8211F PHYSR is page 0xa43 reg 26 (link bit 2, speed bits 5:4).
      // Page 0 reg 17 is the RTL8211E layout and reads 0 on this PHY.
      22:begin reg_addr<=31;value<=16'h0a43;op<=1;end
      23:reg_addr<=26;
      24:begin reg_addr<=31;value<=0;op<=1;end
      // PHY power is not cycled by FPGA reconfiguration. ID registers on an
      // inherited vendor page may read FFFF, so recover page zero BEFORE ID.
      21:begin reg_addr<=31;value<=0;op<=1;end
      default:fail(5);
     endcase
    end
    ISSUE:begin command_valid<=1;seen_busy<=0;timer<=1000000;state<=TRANSFER;end
    TRANSFER:begin
     if(busy)seen_busy<=1;
     if(timer!=0)timer<=timer-1;
     if(read_valid)begin
      last_read<=read_data;
      case(index)
       0:if(!read_ack||read_data!=16'h001c)next_address();
         else begin id1<=read_data;index<=1;state<=PREPARE;end
       1:if((read_data&16'hfff0)!=16'hc910)next_address();
         else begin id2<=read_data;fault<=0;error_code<=0;index<=2;state<=PREPARE;end
       3:begin
        control<=read_data;
        if(!read_data[15])begin index<=4;state<=PREPARE;end
        else if(reset_timer==0)fail(3);else state<=PREPARE;
       end
       8,11,16,17:begin
        if(index==16)advertisement<=read_data;
        if(index==17)gigabit<=read_data;
        if((read_data&mask)!=(value&mask))fail(4);
        else begin index<=index+1;state<=PREPARE;end
       end
       19:begin index<=22;control<=read_data;state<=PREPARE;end
       23:begin
        phy_status<=read_data;configured<=1;fault<=0;
        // PHYSR speed encoding: 01=100 Mbps, 10=1000 Mbps.
        // Both are valid for the MAC; 00 (10 Mbps) and 11 are rejected.
        link_up<=control[2]&&read_data[2]&&(read_data[5:4]==2'b01||read_data[5:4]==2'b10);
        index<=24;state<=PREPARE;
       end
       default:begin index<=index+1;state<=PREPARE;end
      endcase
     end else if(op==1&&seen_busy&&!busy)begin
      if(index==24)begin timer<=12500000;state<=WAIT_POLL;end
      else begin index<=index==21 ? 0 : index+1;state<=PREPARE;end
     end
     else if(timer==0)fail(2);
    end
    WAIT_POLL:if(timer!=0)timer<=timer-1;else begin index<=18;state<=PREPARE;end
    RETRY:if(timer!=0)timer<=timer-1;else begin phy_addr<=0;index<=21;state<=PREPARE;end
    default:fail(5);
   endcase
  end
 end
endmodule

// Clause 22 with four distinct phases. Unlike simultaneous MDC/data changes,
// this gives the board's independent MOSFET level shifters a full quarter bit
// of hold/setup margin. The PHY updates MDIO 0..300 ns AFTER each MDC rising
// edge, so read data/TA are sampled just before MDC rises (as the board UDP
// example's mdio_dri does). Sampling during MDC high would capture the
// following bit: TA reads D15, data reads D14..D0 plus the released '1'.
module ku5p_clause22(
 input wire clk,rst,input wire [4:0] cmd_phy_addr,cmd_reg_addr,
 input wire [15:0] cmd_data,input wire [1:0] cmd_opcode,
 input wire cmd_valid,output wire cmd_ready,
 output reg [15:0] data_out,output reg data_out_valid,input wire data_out_ready,
 output reg mdc_o,input wire mdio_i,output reg mdio_o,mdio_t,
 output reg busy,read_ack,output wire [31:0] diagnostics
);
 reg [63:0] frame;reg [6:0] bit_index;reg [1:0] phase;
 reg [6:0] divider;reg read_operation;
 reg [5:0] idle_bits;
 reg drove_low,read_low,echo_fault;reg [11:0] ack_count;reg [15:0] frame_count;
 // Like the board UDP example, MDC keeps running during idle. Accept at a
 // falling edge after 32 released idle bits, then transmit a full preamble.
 assign cmd_ready=!busy&&!data_out_valid&&idle_bits==0&&phase==3&&divider==0;
 assign diagnostics={mdio_i,drove_low,read_low,echo_fault,ack_count,frame_count};
 always @(posedge clk)begin
  if(rst)begin
   frame<=0;bit_index<=0;phase<=0;divider<=0;read_operation<=0;
   data_out<=0;data_out_valid<=0;mdc_o<=0;mdio_o<=1;mdio_t<=1;busy<=0;read_ack<=0;
   idle_bits<=32;drove_low<=0;read_low<=0;echo_fault<=0;ack_count<=0;frame_count<=0;
  end else begin
   if(data_out_valid&&data_out_ready)data_out_valid<=0;
   if(divider!=0)divider<=divider-1;
   else begin
    divider<=124;phase<=phase+1;
    if(phase==1)mdc_o<=1;
    if(phase==3)mdc_o<=0;
    if(!busy)begin
     mdio_o<=1;mdio_t<=1;
     if(phase==3&&idle_bits!=0)idle_bits<=idle_bits-1;
     if(cmd_valid&&cmd_ready)begin
     frame<={32'hffffffff,2'b01,cmd_opcode,cmd_phy_addr,cmd_reg_addr,2'b10,cmd_data};
      read_operation<=cmd_opcode==2;bit_index<=0;
      busy<=1;data_out<=0;read_ack<=0;
      if(frame_count!=65535)frame_count<=frame_count+1;
     end
    end else case(phase)
     0:begin mdio_o<=frame[63-bit_index];mdio_t<=read_operation&&bit_index>=46;end
     1:begin
      // mdio_i still reflects MDC low: the value the PHY set after the
      // previous rising edge, i.e. this bit.
      mdc_o<=1;
      if(read_operation&&bit_index>=47&&!mdio_i)read_low<=1;
      if(read_operation&&bit_index==47)begin
       read_ack<=!mdio_i;
       if(!mdio_i&&ack_count!=4095)ack_count<=ack_count+1;
      end
      if(read_operation&&bit_index>=48)data_out<={data_out[14:0],mdio_i};
     end
     2:if(!mdio_t&&!mdio_o)begin
      if(!mdio_i)drove_low<=1;else echo_fault<=1;
     end
     3:begin
      if(bit_index==63)begin busy<=0;mdio_t<=1;idle_bits<=32;if(read_operation)data_out_valid<=1;end
      else bit_index<=bit_index+1;
     end
    endcase
   end
  end
 end
endmodule
