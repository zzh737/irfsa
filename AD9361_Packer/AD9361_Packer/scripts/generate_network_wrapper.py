"""Explicit vendor port wiring; generated RTL is checked in and compiled."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
parts=['''// SPDX-License-Identifier: MIT
`timescale 1ns/1ps
module network_core(
 input wire clk,tx_clk,tx_clk90,rst,
 input wire rgmii_rxc,rgmii_rx_ctl,input wire [3:0] rgmii_rxd,
 output wire rgmii_txc,rgmii_tx_ctl,output wire [3:0] rgmii_txd,
 output wire [1:0] link_speed,
 output wire command_valid,input wire command_ready,output wire [1023:0] command_bytes,
 output wire [15:0] command_length,output wire [31:0] bad_commands,
 input wire ctl_hdr_valid,output wire ctl_hdr_ready,input wire [15:0] ctl_length,
 input wire [7:0] ctl_data,input wire ctl_valid,output wire ctl_ready,input wire ctl_last,
 input wire iq_hdr_valid,output wire iq_hdr_ready,input wire [7:0] iq_data,
 input wire iq_valid,output wire iq_ready,input wire iq_last,
 output wire rx_overflow,tx_underflow,arp_failed
);
''']
def ports(module):
 s=(R/f'vendor/verilog-ethernet/rtl/{module}.v').read_text()
 # all ports are one declaration per line in this vendor version
 return re.findall(r'^\s*(input|output)\s+wire\s*(\[[^\]]+\])?\s*(\w+)\s*[,\n]',s,re.M)
def instance(module,name,mapping,params=''):
 actual={p for _,_,p in ports(module)}
 assert not(set(mapping)-actual),(module,set(mapping)-actual)
 entries=[]
 for direction,width,p in ports(module):
  entries.append(f' .{p}({mapping.get(p,"" if direction=="output" else "0")})')
 parts.append(f'{module} {params} {name}(\n'+',\n'.join(entries)+'\n);\n')
def wire(name,width=''):
 parts.append(f'wire {width} {name};\n');return name
def bus(prefix,fields):
 return {n:wire(prefix+n,w) for n,w in fields}
axis=[('tdata','[7:0]'),('tvalid',''),('tready',''),('tlast',''),('tuser','')]
rxaxis=bus('rx_axis_',axis);txaxis=bus('tx_axis_',axis)
eth=[('hdr_valid',''),('hdr_ready',''),('dest_mac','[47:0]'),('src_mac','[47:0]'),('type','[15:0]')]+[
 ('payload_axis_'+a,w) for a,w in axis]
rxeth=bus('rx_eth_',eth);txeth=bus('tx_eth_',eth)
instance('eth_mac_1g_rgmii_fifo','mac',{'gtx_clk':'tx_clk','gtx_clk90':'tx_clk90','gtx_rst':'rst','logic_clk':'clk','logic_rst':'rst',
 'tx_axis_tkeep':"1'b1",**{'tx_axis_'+a:txaxis[a] for a,_ in axis},**{'rx_axis_'+a:rxaxis[a] for a,_ in axis},
 'rgmii_rx_clk':'rgmii_rxc','rgmii_rxd':'rgmii_rxd','rgmii_rx_ctl':'rgmii_rx_ctl',
 'rgmii_tx_clk':'rgmii_txc','rgmii_txd':'rgmii_txd','rgmii_tx_ctl':'rgmii_tx_ctl','speed':'link_speed',
 'tx_error_underflow':'tx_underflow','rx_fifo_overflow':'rx_overflow','cfg_ifg':"8'd12",'cfg_tx_enable':"1'b1",'cfg_rx_enable':"1'b1"},
 '#(.TARGET("XILINX"),.IODDR_STYLE("IODDR"),.CLOCK_INPUT_STYLE("BUFG"),.USE_CLK90("TRUE"),.TX_FIFO_DEPTH(16384),.RX_FIFO_DEPTH(8192))')
instance('eth_axis_rx','eth_rx',{'clk':'clk','rst':'rst','s_axis_tkeep':"1'b1",
 **{'s_axis_'+a:rxaxis[a] for a,_ in axis},**{'m_eth_'+a:rxeth[a] for a,_ in eth}})
instance('eth_axis_tx','eth_tx',{'clk':'clk','rst':'rst','s_eth_payload_axis_tkeep':"1'b1",
 **{'m_axis_'+a:txaxis[a] for a,_ in axis},**{'s_eth_'+a:txeth[a] for a,_ in eth}})
rxudp={}
for direction,width,p in ports('udp_complete'):
 if p.startswith('m_udp_'):
  rxudp[p[6:]]=wire('rx_udp_'+p[6:],width)
txudp={}
for direction,width,p in ports('udp_complete'):
 if p.startswith('s_udp_'):
  txudp[p[6:]]=wire('tx_udp_'+p[6:],width)
mapping={'clk':'clk','rst':'rst',**{'s_eth_'+a:rxeth[a] for a,_ in eth},**{'m_eth_'+a:txeth[a] for a,_ in eth},
 **{'m_udp_'+a:w for a,w in rxudp.items()},**{'s_udp_'+a:w for a,w in txudp.items()},
 'm_ip_hdr_ready':"1'b1",'m_ip_payload_axis_tready':"1'b1",'local_mac':"48'h020000000002",'local_ip':"32'hc0a80a02",
 'gateway_ip':"32'hc0a80a01",'subnet_mask':"32'hffffff00",'ip_tx_error_arp_failed':'arp_failed'}
instance('udp_complete','stack',mapping,'#(.ARP_CACHE_ADDR_WIDTH(4),.UDP_CHECKSUM_GEN_ENABLE(1),.UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH(16384))')
parts.append('''udp_command_rx commands(
 .clk(clk),.rst(rst),.hdr_valid(rx_udp_hdr_valid),.hdr_ready(rx_udp_hdr_ready),
 .dest_mac(rx_udp_eth_dest_mac),.version(rx_udp_ip_version),.ihl(rx_udp_ip_ihl),
 .ip_length(rx_udp_ip_length),.ip_flags(rx_udp_ip_flags),.fragment_offset(rx_udp_ip_fragment_offset),
 .source_ip(rx_udp_ip_source_ip),.dest_ip(rx_udp_ip_dest_ip),.source_port(rx_udp_source_port),
 .dest_port(rx_udp_dest_port),.udp_length(rx_udp_length),.udp_checksum(rx_udp_checksum),
 .data(rx_udp_payload_axis_tdata),.valid(rx_udp_payload_axis_tvalid),.ready(rx_udp_payload_axis_tready),
 .last(rx_udp_payload_axis_tlast),.user(rx_udp_payload_axis_tuser),
 .command_valid(command_valid),.command_ready(command_ready),.command_bytes(command_bytes),
 .command_length(command_length),.bad_packets(bad_commands));
reg [1:0] state;reg select_iq;
always @(posedge clk)begin
 if(rst)begin state<=0;select_iq<=0;end
 else case(state)
  0:if(ctl_hdr_valid||iq_hdr_valid)begin select_iq<=!ctl_hdr_valid;state<=1;end
  1:if(tx_udp_hdr_ready)state<=2;
  2:if(tx_udp_payload_axis_tvalid&&tx_udp_payload_axis_tready&&tx_udp_payload_axis_tlast)state<=0;
 endcase
end
assign tx_udp_hdr_valid=state==1;
assign ctl_hdr_ready=state==1&&!select_iq&&tx_udp_hdr_ready;
assign iq_hdr_ready=state==1&&select_iq&&tx_udp_hdr_ready;
assign tx_udp_ip_dscp=0;assign tx_udp_ip_ecn=0;assign tx_udp_ip_ttl=64;
assign tx_udp_ip_source_ip=32'hc0a80a02;assign tx_udp_ip_dest_ip=32'hc0a80a01;
assign tx_udp_source_port=select_iq?16'd40000:16'd40001;
assign tx_udp_dest_port=tx_udp_source_port;
assign tx_udp_length=(select_iq?16'd1088:ctl_length)+16'd8;
assign tx_udp_checksum=0;
assign tx_udp_payload_axis_tdata=select_iq?iq_data:ctl_data;
assign tx_udp_payload_axis_tvalid=state==2&&(select_iq?iq_valid:ctl_valid);
assign tx_udp_payload_axis_tlast=select_iq?iq_last:ctl_last;
assign tx_udp_payload_axis_tuser=0;
assign ctl_ready=state==2&&!select_iq&&tx_udp_payload_axis_tready;
assign iq_ready=state==2&&select_iq&&tx_udp_payload_axis_tready;
endmodule
''')
(R/'rtl/network_core.sv').write_text(''.join(parts),encoding='ascii')
print('Generated explicit network wrapper')
