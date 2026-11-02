# Candidate external timing budgets: bench confirmation of PHY and FMC eye needed.
create_clock -name sys200 -period 5.000 [get_ports sys_clk_p]
create_clock -name ad_data100 -period 10.000 [get_ports ad_data_clk_p]
# RGMII timing is budgeted against the 125 MHz source-synchronous clock.
# The same direct-clock path also operates at the slower 25 MHz 100BASE-TX
# rate; the 125 MHz constraint is retained as the conservative implementation
# budget without creating a second CDC clock domain for the mutually exclusive
# PHY rate.
create_clock -name eth_rx125 -period 8.000 [get_ports rgmii_rxc]
set_input_jitter [get_clocks sys200] 0.050
set_clock_uncertainty 0.150 [get_clocks {ad_data100 eth_rx125}]
# RTL8211F RX internal skew ON (strap RXDLY=1, register 0xd08/21 bit3 set by
# rtl8211f_init): RGMII v2.0 delayed-clock receiver budget, TsetupR=TholdR=
# 1.0 ns around each RXC edge, i.e. the next DDR transition lies 1.0..3.0 ns
# after the launching edge.  These are the specification values -- do NOT
# raise min to pass hold (an earlier 2.8 ns hid a -1.6 ns hold violation).
# There is no RX MMCM: RXC -> GC pin -> BUFG (root pinned to X0Y1 in
# ku5p_post_opt.tcl) -> IDDRE1, and every data input passes a fixed IDELAYE3
# (us_ssio.sv DATA_DELAY_PS) that centres the 2 ns window on the late clock.
# 100BASE-TX (25 MHz RXC) is bounded by this 125 MHz check.
set_input_delay -clock eth_rx125 -max 3.000 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
set_input_delay -clock eth_rx125 -min 1.000 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
set_input_delay -clock eth_rx125 -clock_fall -add_delay -max 3.000 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
set_input_delay -clock eth_rx125 -clock_fall -add_delay -min 1.000 [get_ports {rgmii_rxd[*] rgmii_rx_ctl}]
# FPGA supplies the 90-degree TX clock. RTL8211F TX internal skew OFF.
# Receiver setup/hold 1 ns plus 0.2 ns candidate PCB skew allowance.
# MMCM phase error/jitter and all FPGA insertion delays are separately timed;
# no PHY-internal 2 ns delay or its PVT tolerance is assumed in this mode.
create_generated_clock -name eth_tx125 -source [get_pins tx90_buf/O] -divide_by 1 [get_ports rgmii_txc]
set_output_delay -clock eth_tx125 -max 1.200 [get_ports {rgmii_txd[*] rgmii_tx_ctl}]
set_output_delay -clock eth_tx125 -min -1.200 [get_ports {rgmii_txd[*] rgmii_tx_ctl}]
set_output_delay -clock eth_tx125 -clock_fall -add_delay -max 1.200 [get_ports {rgmii_txd[*] rgmii_tx_ctl}]
set_output_delay -clock eth_tx125 -clock_fall -add_delay -min -1.200 [get_ports {rgmii_txd[*] rgmii_tx_ctl}]
# RX budget: datasheet LVDS tDDRx/tDDDV 0.25..1.25 ns (UG-570 p.110) after
# each DATA_CLK edge. Fixed register 0x006=0x04 adds an undocumented Rx data
# delay on top; the HW14 board capture at the old +90 degree phase showed the
# data transition right at the sampling edge, so the MMCM phase (ad9361_lvds.sv,
# 166.5 degrees) is set from that measurement, not from this budget alone.
# The TX/FB clock retains its zero-degree phase.
set_input_delay -clock ad_data100 -max 1.250 [get_ports {ad_rx_data_p[*] ad_rx_frame_p}]
set_input_delay -clock ad_data100 -min 0.250 [get_ports {ad_rx_data_p[*] ad_rx_frame_p}]
set_input_delay -clock ad_data100 -clock_fall -add_delay -max 1.250 [get_ports {ad_rx_data_p[*] ad_rx_frame_p}]
set_input_delay -clock ad_data100 -clock_fall -add_delay -min 0.250 [get_ports {ad_rx_data_p[*] ad_rx_frame_p}]
# Receiver aperture 2.5 ns after source edges models the AD9361 internal delay.
# This is an assumed budget, not a measurement of the board-selected 0x007 tap.
create_generated_clock -name ad_tx_aperture -source [get_pins lvds/tx_clock_buf/O] -edges {1 2 3} -edge_shift {2.500 2.500 2.500} [get_ports ad_fb_clk_p]
set_output_delay -clock ad_tx_aperture -max 1.000 [get_ports {ad_tx_data_p[*] ad_tx_data_n[*] ad_tx_frame_p ad_tx_frame_n}]
set_output_delay -clock ad_tx_aperture -min 0.500 [get_ports {ad_tx_data_p[*] ad_tx_data_n[*] ad_tx_frame_p ad_tx_frame_n}]
set_output_delay -clock ad_tx_aperture -clock_fall -add_delay -max 1.000 [get_ports {ad_tx_data_p[*] ad_tx_data_n[*] ad_tx_frame_p ad_tx_frame_n}]
set_output_delay -clock ad_tx_aperture -clock_fall -add_delay -min 0.500 [get_ports {ad_tx_data_p[*] ad_tx_data_n[*] ad_tx_frame_p ad_tx_frame_n}]
# Slow management register paths; state machines provide >100 ns sampling margin.
set_max_delay 20 -datapath_only -from [get_clocks -include_generated_clocks sys200] -to [get_ports {ad_spi_cs_n ad_spi_clk ad_spi_mosi ad_resetb phy_mdc phy_mdio eeprom_scl eeprom_sda}]
set_max_delay 20 -datapath_only -from [get_ports ad_spi_miso] -to [get_clocks -include_generated_clocks sys200]
set_false_path -from [get_ports reset_n]
# Asynchronous UART input: only the first synchronizer stage is excluded.
set_false_path -from [get_ports uart_rx] -to [get_pins -hier -regexp {transports/phy/rx_sync_reg\[0\]/D}]
set_max_delay 20 -datapath_only -from [get_clocks -include_generated_clocks sys200] -to [get_ports uart_tx]
set_false_path -to [get_ports {led[*]}]
set_false_path -from [get_ports {phy_mdio eeprom_scl eeprom_sda}]
set_false_path -to [get_ports {ad_enable ad_txnrx ad_en_agc ad_sync_in}]
