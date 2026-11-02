// SPDX-License-Identifier: MIT
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
wire [7:0] rx_axis_tdata;
wire  rx_axis_tvalid;
wire  rx_axis_tready;
wire  rx_axis_tlast;
wire  rx_axis_tuser;
wire [7:0] tx_axis_tdata;
wire  tx_axis_tvalid;
wire  tx_axis_tready;
wire  tx_axis_tlast;
wire  tx_axis_tuser;
wire  rx_eth_hdr_valid;
wire  rx_eth_hdr_ready;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [7:0] rx_eth_payload_axis_tdata;
wire  rx_eth_payload_axis_tvalid;
wire  rx_eth_payload_axis_tready;
wire  rx_eth_payload_axis_tlast;
wire  rx_eth_payload_axis_tuser;
wire  tx_eth_hdr_valid;
wire  tx_eth_hdr_ready;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [7:0] tx_eth_payload_axis_tdata;
wire  tx_eth_payload_axis_tvalid;
wire  tx_eth_payload_axis_tready;
wire  tx_eth_payload_axis_tlast;
wire  tx_eth_payload_axis_tuser;
eth_mac_1g_rgmii_fifo #(.TARGET("XILINX"),.IODDR_STYLE("IODDR"),.CLOCK_INPUT_STYLE("BUFG"),.USE_CLK90("TRUE"),.TX_FIFO_DEPTH(32768),.RX_FIFO_DEPTH(16384)) mac( // HW22: was 16384/8192
 .gtx_clk(tx_clk),
 .gtx_clk90(tx_clk90),
 .gtx_rst(rst),
 .logic_clk(clk),
 .logic_rst(rst),
 .tx_axis_tdata(tx_axis_tdata),
 .tx_axis_tkeep(1'b1),
 .tx_axis_tvalid(tx_axis_tvalid),
 .tx_axis_tready(tx_axis_tready),
 .tx_axis_tlast(tx_axis_tlast),
 .tx_axis_tuser(tx_axis_tuser),
 .rx_axis_tdata(rx_axis_tdata),
 .rx_axis_tkeep(),
 .rx_axis_tvalid(rx_axis_tvalid),
 .rx_axis_tready(rx_axis_tready),
 .rx_axis_tlast(rx_axis_tlast),
 .rx_axis_tuser(rx_axis_tuser),
 .rgmii_rx_clk(rgmii_rxc),
 .rgmii_rxd(rgmii_rxd),
 .rgmii_rx_ctl(rgmii_rx_ctl),
 .rgmii_tx_clk(rgmii_txc),
 .rgmii_txd(rgmii_txd),
 .rgmii_tx_ctl(rgmii_tx_ctl),
 .tx_error_underflow(tx_underflow),
 .tx_fifo_overflow(),
 .tx_fifo_bad_frame(),
 .tx_fifo_good_frame(),
 .rx_error_bad_frame(),
 .rx_error_bad_fcs(),
 .rx_fifo_overflow(rx_overflow),
 .rx_fifo_bad_frame(),
 .rx_fifo_good_frame(),
 .speed(link_speed),
 .cfg_ifg(8'd12),
 .cfg_tx_enable(1'b1),
 .cfg_rx_enable(1'b1)
);
eth_axis_rx  eth_rx(
 .clk(clk),
 .rst(rst),
 .s_axis_tdata(rx_axis_tdata),
 .s_axis_tkeep(1'b1),
 .s_axis_tvalid(rx_axis_tvalid),
 .s_axis_tready(rx_axis_tready),
 .s_axis_tlast(rx_axis_tlast),
 .s_axis_tuser(rx_axis_tuser),
 .m_eth_hdr_valid(rx_eth_hdr_valid),
 .m_eth_hdr_ready(rx_eth_hdr_ready),
 .m_eth_dest_mac(rx_eth_dest_mac),
 .m_eth_src_mac(rx_eth_src_mac),
 .m_eth_type(rx_eth_type),
 .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
 .m_eth_payload_axis_tkeep(),
 .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
 .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
 .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
 .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
 .busy(),
 .error_header_early_termination()
);
eth_axis_tx  eth_tx(
 .clk(clk),
 .rst(rst),
 .s_eth_hdr_valid(tx_eth_hdr_valid),
 .s_eth_hdr_ready(tx_eth_hdr_ready),
 .s_eth_dest_mac(tx_eth_dest_mac),
 .s_eth_src_mac(tx_eth_src_mac),
 .s_eth_type(tx_eth_type),
 .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
 .s_eth_payload_axis_tkeep(1'b1),
 .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
 .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
 .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
 .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
 .m_axis_tdata(tx_axis_tdata),
 .m_axis_tkeep(),
 .m_axis_tvalid(tx_axis_tvalid),
 .m_axis_tready(tx_axis_tready),
 .m_axis_tlast(tx_axis_tlast),
 .m_axis_tuser(tx_axis_tuser),
 .busy()
);
wire  rx_udp_hdr_valid;
wire  rx_udp_hdr_ready;
wire [47:0] rx_udp_eth_dest_mac;
wire [47:0] rx_udp_eth_src_mac;
wire [15:0] rx_udp_eth_type;
wire [3:0] rx_udp_ip_version;
wire [3:0] rx_udp_ip_ihl;
wire [5:0] rx_udp_ip_dscp;
wire [1:0] rx_udp_ip_ecn;
wire [15:0] rx_udp_ip_length;
wire [15:0] rx_udp_ip_identification;
wire [2:0] rx_udp_ip_flags;
wire [12:0] rx_udp_ip_fragment_offset;
wire [7:0] rx_udp_ip_ttl;
wire [7:0] rx_udp_ip_protocol;
wire [15:0] rx_udp_ip_header_checksum;
wire [31:0] rx_udp_ip_source_ip;
wire [31:0] rx_udp_ip_dest_ip;
wire [15:0] rx_udp_source_port;
wire [15:0] rx_udp_dest_port;
wire [15:0] rx_udp_length;
wire [15:0] rx_udp_checksum;
wire [7:0] rx_udp_payload_axis_tdata;
wire  rx_udp_payload_axis_tvalid;
wire  rx_udp_payload_axis_tready;
wire  rx_udp_payload_axis_tlast;
wire  rx_udp_payload_axis_tuser;
wire  tx_udp_hdr_valid;
wire  tx_udp_hdr_ready;
wire [5:0] tx_udp_ip_dscp;
wire [1:0] tx_udp_ip_ecn;
wire [7:0] tx_udp_ip_ttl;
wire [31:0] tx_udp_ip_source_ip;
wire [31:0] tx_udp_ip_dest_ip;
wire [15:0] tx_udp_source_port;
wire [15:0] tx_udp_dest_port;
wire [15:0] tx_udp_length;
wire [15:0] tx_udp_checksum;
wire [7:0] tx_udp_payload_axis_tdata;
wire  tx_udp_payload_axis_tvalid;
wire  tx_udp_payload_axis_tready;
wire  tx_udp_payload_axis_tlast;
wire  tx_udp_payload_axis_tuser;
udp_complete #(.ARP_CACHE_ADDR_WIDTH(4),.UDP_CHECKSUM_GEN_ENABLE(1),.UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH(32768)) stack( // HW22: was 16384
 .clk(clk),
 .rst(rst),
 .s_eth_hdr_valid(rx_eth_hdr_valid),
 .s_eth_hdr_ready(rx_eth_hdr_ready),
 .s_eth_dest_mac(rx_eth_dest_mac),
 .s_eth_src_mac(rx_eth_src_mac),
 .s_eth_type(rx_eth_type),
 .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
 .s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
 .s_eth_payload_axis_tready(rx_eth_payload_axis_tready),
 .s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
 .s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
 .m_eth_hdr_valid(tx_eth_hdr_valid),
 .m_eth_hdr_ready(tx_eth_hdr_ready),
 .m_eth_dest_mac(tx_eth_dest_mac),
 .m_eth_src_mac(tx_eth_src_mac),
 .m_eth_type(tx_eth_type),
 .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
 .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
 .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
 .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
 .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
 .s_ip_hdr_valid(0),
 .s_ip_hdr_ready(),
 .s_ip_dscp(0),
 .s_ip_ecn(0),
 .s_ip_length(0),
 .s_ip_ttl(0),
 .s_ip_protocol(0),
 .s_ip_source_ip(0),
 .s_ip_dest_ip(0),
 .s_ip_payload_axis_tdata(0),
 .s_ip_payload_axis_tvalid(0),
 .s_ip_payload_axis_tready(),
 .s_ip_payload_axis_tlast(0),
 .s_ip_payload_axis_tuser(0),
 .m_ip_hdr_valid(),
 .m_ip_hdr_ready(1'b1),
 .m_ip_eth_dest_mac(),
 .m_ip_eth_src_mac(),
 .m_ip_eth_type(),
 .m_ip_version(),
 .m_ip_ihl(),
 .m_ip_dscp(),
 .m_ip_ecn(),
 .m_ip_length(),
 .m_ip_identification(),
 .m_ip_flags(),
 .m_ip_fragment_offset(),
 .m_ip_ttl(),
 .m_ip_protocol(),
 .m_ip_header_checksum(),
 .m_ip_source_ip(),
 .m_ip_dest_ip(),
 .m_ip_payload_axis_tdata(),
 .m_ip_payload_axis_tvalid(),
 .m_ip_payload_axis_tready(1'b1),
 .m_ip_payload_axis_tlast(),
 .m_ip_payload_axis_tuser(),
 .s_udp_hdr_valid(tx_udp_hdr_valid),
 .s_udp_hdr_ready(tx_udp_hdr_ready),
 .s_udp_ip_dscp(tx_udp_ip_dscp),
 .s_udp_ip_ecn(tx_udp_ip_ecn),
 .s_udp_ip_ttl(tx_udp_ip_ttl),
 .s_udp_ip_source_ip(tx_udp_ip_source_ip),
 .s_udp_ip_dest_ip(tx_udp_ip_dest_ip),
 .s_udp_source_port(tx_udp_source_port),
 .s_udp_dest_port(tx_udp_dest_port),
 .s_udp_length(tx_udp_length),
 .s_udp_checksum(tx_udp_checksum),
 .s_udp_payload_axis_tdata(tx_udp_payload_axis_tdata),
 .s_udp_payload_axis_tvalid(tx_udp_payload_axis_tvalid),
 .s_udp_payload_axis_tready(tx_udp_payload_axis_tready),
 .s_udp_payload_axis_tlast(tx_udp_payload_axis_tlast),
 .s_udp_payload_axis_tuser(tx_udp_payload_axis_tuser),
 .m_udp_hdr_valid(rx_udp_hdr_valid),
 .m_udp_hdr_ready(rx_udp_hdr_ready),
 .m_udp_eth_dest_mac(rx_udp_eth_dest_mac),
 .m_udp_eth_src_mac(rx_udp_eth_src_mac),
 .m_udp_eth_type(rx_udp_eth_type),
 .m_udp_ip_version(rx_udp_ip_version),
 .m_udp_ip_ihl(rx_udp_ip_ihl),
 .m_udp_ip_dscp(rx_udp_ip_dscp),
 .m_udp_ip_ecn(rx_udp_ip_ecn),
 .m_udp_ip_length(rx_udp_ip_length),
 .m_udp_ip_identification(rx_udp_ip_identification),
 .m_udp_ip_flags(rx_udp_ip_flags),
 .m_udp_ip_fragment_offset(rx_udp_ip_fragment_offset),
 .m_udp_ip_ttl(rx_udp_ip_ttl),
 .m_udp_ip_protocol(rx_udp_ip_protocol),
 .m_udp_ip_header_checksum(rx_udp_ip_header_checksum),
 .m_udp_ip_source_ip(rx_udp_ip_source_ip),
 .m_udp_ip_dest_ip(rx_udp_ip_dest_ip),
 .m_udp_source_port(rx_udp_source_port),
 .m_udp_dest_port(rx_udp_dest_port),
 .m_udp_length(rx_udp_length),
 .m_udp_checksum(rx_udp_checksum),
 .m_udp_payload_axis_tdata(rx_udp_payload_axis_tdata),
 .m_udp_payload_axis_tvalid(rx_udp_payload_axis_tvalid),
 .m_udp_payload_axis_tready(rx_udp_payload_axis_tready),
 .m_udp_payload_axis_tlast(rx_udp_payload_axis_tlast),
 .m_udp_payload_axis_tuser(rx_udp_payload_axis_tuser),
 .ip_rx_busy(),
 .ip_tx_busy(),
 .udp_rx_busy(),
 .udp_tx_busy(),
 .ip_rx_error_header_early_termination(),
 .ip_rx_error_payload_early_termination(),
 .ip_rx_error_invalid_header(),
 .ip_rx_error_invalid_checksum(),
 .ip_tx_error_payload_early_termination(),
 .ip_tx_error_arp_failed(arp_failed),
 .udp_rx_error_header_early_termination(),
 .udp_rx_error_payload_early_termination(),
 .udp_tx_error_payload_early_termination(),
 .local_mac(48'h020000000002),
 .local_ip(32'hc0a80a02),
 .gateway_ip(32'hc0a80a01),
 .subnet_mask(32'hffffff00),
 .clear_arp_cache(0)
);
udp_command_rx commands(
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
