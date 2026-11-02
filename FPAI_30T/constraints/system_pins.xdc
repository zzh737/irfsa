# Full Wujing board: PS / DDR / product HDMI / PJTAG.
#####################  hdmi ############################
set_property PACKAGE_PIN AC17 [get_ports HDMI_CLK_P]
set_property PACKAGE_PIN AC16 [get_ports HDMI_CLK_N]
set_property PACKAGE_PIN AA15 [get_ports {HDMI_TX_P[0]}]
set_property PACKAGE_PIN AA14 [get_ports {HDMI_TX_N[0]}]
set_property PACKAGE_PIN Y16 [get_ports {HDMI_TX_P[1]}]
set_property PACKAGE_PIN Y15 [get_ports {HDMI_TX_N[1]}]
set_property PACKAGE_PIN W16 [get_ports {HDMI_TX_P[2]}]
set_property PACKAGE_PIN W15 [get_ports {HDMI_TX_N[2]}]
set_property IOSTANDARD TMDS_33 [get_ports HDMI_CLK_P]
set_property IOSTANDARD TMDS_33 [get_ports HDMI_CLK_N]
set_property IOSTANDARD TMDS_33 [get_ports {HDMI_TX_P[*]}]
set_property IOSTANDARD TMDS_33 [get_ports {HDMI_TX_N[*]}]
#####################  hdmi ############################

set_property PACKAGE_PIN F8 [get_ports sys_rst]
set_property IOSTANDARD LVCMOS15 [get_ports sys_rst]

# Hardware manual section 4.8: PS Ethernet YT8521 active-low reset, bank 12.
set_property PACKAGE_PIN W14 [get_ports PS_PHY_RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports PS_PHY_RESET_N]
set_property DRIVE 8 [get_ports PS_PHY_RESET_N]
set_property SLEW SLOW [get_ports PS_PHY_RESET_N]

#LED1, BANK13
set_property IOSTANDARD LVCMOS15 [get_ports {led[0]}]
set_property PACKAGE_PIN J1 [get_ports {led[0]}]
#LED2, BANK13
set_property IOSTANDARD LVCMOS15 [get_ports {led[1]}]
set_property PACKAGE_PIN M6 [get_ports {led[1]}]

create_clock -period 5.000 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_n]
set_property PACKAGE_PIN C8 [get_ports sys_clk_p]
set_property PACKAGE_PIN C7 [get_ports sys_clk_n]


#pjtag:7030 Demo
set_property PACKAGE_PIN AD16 [get_ports PJTAG_TDO]
set_property PACKAGE_PIN AB14 [get_ports PJTAG_TMS]
set_property PACKAGE_PIN AB15 [get_ports PJTAG_TCK]
set_property PACKAGE_PIN AD15 [get_ports PJTAG_TDI]
set_property IOSTANDARD LVCMOS33 [get_ports PJTAG_TCK]
set_property IOSTANDARD LVCMOS33 [get_ports PJTAG_TMS]
set_property IOSTANDARD LVCMOS33 [get_ports PJTAG_TDI]
set_property IOSTANDARD LVCMOS33 [get_ports PJTAG_TDO]

set_property PULLUP true [get_ports PJTAG_TDO]
# PJTAG debug adapter must run at or below 10 MHz.
create_clock -period 100.000 -name PJTAG_TCK -waveform {0.000 50.000} [get_ports PJTAG_TCK]
set_input_delay -clock PJTAG_TCK -clock_fall -max 5.000 [get_ports {PJTAG_TMS PJTAG_TDI}]
set_input_delay -clock PJTAG_TCK -clock_fall -min 0.000 [get_ports {PJTAG_TMS PJTAG_TDI}]

########################
#set_property SEVERITY {Warning} [get_drc_checks {REQP-44}]
#set_property SEVERITY {Warning} [get_drc_checks {REQP-46}]
#set_property SEVERITY {Warning} [get_drc_checks {REQP-52}]
#set_property SEVERITY {Warning} [get_drc_checks {REQP-56}]

