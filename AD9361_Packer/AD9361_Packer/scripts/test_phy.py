from sim_utils import *
from source_manifest import design_sources
import json
tb=r'''~timescale 1ns/1ps
module tb_phy;
reg clk=0;always #4 clk=~clk;reg rst=1;wire mdc,configured,fault,link;
tri1 mdio;reg drive_low=0;assign mdio=drive_low?1'b0:1'bz;wire [31:0] wire_diag;
rtl8211f_init #(.START_CYCLES(8),.RETRY_CYCLES(1000)) dut(
 .clk(clk),.rst(rst),.mdc(mdc),.mdio(mdio),.configured(configured),.fault(fault),.link_up(link),.diagnostics(),.wire_diagnostics(wire_diag));
reg [15:0] bank0[0:31],bankd[0:31],banka[0:31],page=16'hd08,header,value;
reg bad_id=0,watch_link=0;reg [4:0] model_addr=2;integer j,n,reads=0,writes=0;
localparam PHY_TCO=`PHY_TCO_NS;
always @(posedge clk)if(watch_link&&!link)$fatal(1,"periodic PHY polling interrupted a good link");
initial begin
 for(j=0;j<32;j=j+1)begin bank0[j]=0;bankd[j]=0;banka[j]=0;end
 // Hardware (2026-10-28 diag): page 0 reg 17 reads 0 on RTL8211F; PHYSR is page 0xa43 reg 26.
 bank0[2]=16'h001c;bank0[3]=16'hc916;bank0[1]=16'h0024;
 banka[26]=16'h002c;
 bankd[17]=16'h0100;
 bankd[2]=16'hffff;bankd[3]=16'hffff;
 forever begin
  do @(posedge mdc);while(mdio!==0);
  header=0;
  for(n=12;n>=0;n=n-1)begin @(posedge mdc);header[n]=mdio;end
  if(header[13:12]!=1)$fatal(1,"MDIO header=%h",header);
  if(header[11:10]==2)begin
   reads=reads+1;
   value=header[4:0]==31 ? page : (page==16'hd08 ? bankd[header[4:0]] : page==16'ha43 ? banka[header[4:0]] : bank0[header[4:0]]);
   if(header[4:0]==0)begin bank0[0][15]=0;value=bank0[0];end
   if((bad_id&&header[4:0]==2)||header[9:5]!=model_addr)value=16'hffff;
   // IEEE 802.3 22.3.4 / RTL8211F: the PHY sources MDIO 0..300 ns AFTER the
   // MDC rising edge and the STA samples at the following rising edge.
   // Rising edge of TA1 -> drive TA0; next 16 rising edges -> D15..D0; release.
   @(posedge mdc);#(PHY_TCO);drive_low=header[9:5]==model_addr;
   for(n=15;n>=0;n=n-1)begin @(posedge mdc);#(PHY_TCO);drive_low=!value[n];end
   @(posedge mdc);#(PHY_TCO);drive_low=0;
  end else begin
   if(header[11:10]!=1)$fatal(1,"MDIO opcode");
   repeat(2)@(posedge mdc);
   for(n=15;n>=0;n=n-1)begin @(posedge mdc);value[n]=mdio;end
   writes=writes+1;
   if(header[9:5]==model_addr)begin
    if(header[4:0]==31)page=value;
    else if(page==16'hd08)bankd[header[4:0]]=value;
    else if(page==16'ha43)banka[header[4:0]]=value;
    else bank0[header[4:0]]=value;
   end
  end
 end
end
task release_reset;
 begin
 repeat(5)@(negedge clk);rst=0;
 end
endtask
initial begin
 release_reset();wait(link||fault);#1;
 if(fault||!configured||!link||bankd[17][8]||!bankd[21][3])$fatal(1,"PHY delay configuration/readback index=%d read=%h model=%h header=%h reads=%d writes=%d",dut.index,dut.read_data,value,header,reads,writes);
 if(bank0[4]!=16'h01e1||bank0[9]!=16'h0200||bank0[0]!=16'h1200)$fatal(1,"PHY must advertise 10/100 and 1 GbE");
 if(!wire_diag[30]||!wire_diag[29]||wire_diag[28]||wire_diag[27:16]==0)
  $fatal(1,"MDIO pin readback diagnostics %h",wire_diag);
 watch_link=1;
 force dut.timer=0;wait(dut.state==1);@(negedge clk);release dut.timer;
 wait(dut.state==4);repeat(3)@(negedge clk);watch_link=0;
 if(page!=0)$fatal(1,"PHY page not restored to 0 after PHYSR poll: %h",page);
 @(negedge clk);rst=1;bad_id=1;release_reset();wait(fault);
 if(configured||link)$fatal(1,"wrong PHY identity did not fail closed");
 bad_id=0;wait(link);#1;if(fault||!configured)$fatal(1,"PHY did not recover automatically");
 @(negedge clk);rst=1;model_addr=17;release_reset();wait(link);#1;
 if(dut.phy_addr!=17)$fatal(1,"PHY strapped-address scan failed");
 @(negedge clk);rst=1;banka[26]=16'h000c;release_reset();wait(configured);#1;
 if(link)$fatal(1,"10 Mbps PHYSR must not report link");
 @(negedge clk);rst=1;banka[26]=16'h0028;release_reset();wait(configured);#1;
 if(link)$fatal(1,"PHYSR link bit clear must not report link");
 @(negedge clk);rst=1;banka[26]=16'h001c;release_reset();wait(configured);#1;
 if(!link)$fatal(1,"100 Mbps PHY must be accepted by the MAC");
 $display("PHY CHECKS PASSED");$finish;
end
initial begin #300000000;$fatal(1,"PHY timeout state=%d index=%d",dut.state,dut.index);end
endmodule'''
# Bracket the RTL8211F MDC->MDIO output delay (datasheet 0..300 ns).
for tco in (0,300):
    out=run_sim('phy',tb.replace('`PHY_TCO_NS',str(tco)),design_sources(['rtl8211f_init']))
(out/'result.json').write_text(json.dumps(dict(passed=True,Clause22_wire_model=True,inherited_vendor_page_recovery=True,PHY_identity=True,delay_readback=True,multi_rate_advertisement=True,wrong_ID_fault=True,address_scan=True,automatic_recovery=True,accept_100mbps=True,polling_preserves_link=True,physr_page_a43_reg26=True,reject_10mbps=True,hardware_verified=False),indent=2))
