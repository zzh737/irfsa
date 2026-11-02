# Puzhi KU5P revised PCB / FMC AD9361 pin assignments.
#
# Authoritative FMC cross-check: FMC_KUP5.xlsx (Sheet4, supplied 2026-10-26)
# plus AD-FMCOMMS3-EBZ FMC connector net names from AD9361_SCH.pdf.
# The supplied new-board workbook maps the FMC nets below to the same KU5P package pins
# used here; the assignments are written explicitly so Vivado does not fall
# back to an older board preset. UART, PHY and sys_clk are carrier-board pins
# and are not covered by FMC_KUP5.xlsx; they remain in the carrier schematic
# section below.
set_property -dict {PACKAGE_PIN K22 IOSTANDARD DIFF_SSTL12} [get_ports {sys_clk_p}]
set_property -dict {PACKAGE_PIN K23 IOSTANDARD DIFF_SSTL12} [get_ports {sys_clk_n}]
set_property -dict {PACKAGE_PIN AD14 IOSTANDARD LVCMOS33} [get_ports {reset_n}]
# CP2102 TXD -> FPGA AC13; FPGA AC14 -> CP2102 RXD (J4 USB-to-UART).
set_property -dict {PACKAGE_PIN AC13 IOSTANDARD LVCMOS33} [get_ports {uart_rx}]
set_property -dict {PACKAGE_PIN AC14 IOSTANDARD LVCMOS33} [get_ports {uart_tx}]
set_property PULLTYPE PULLUP [get_ports uart_rx]
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN AB14 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN V23 IOSTANDARD LVCMOS18} [get_ports {rgmii_rxc}]
set_property -dict {PACKAGE_PIN W23 IOSTANDARD LVCMOS18} [get_ports {rgmii_rx_ctl}]
set_property -dict {PACKAGE_PIN R25 IOSTANDARD LVCMOS18} [get_ports {rgmii_rxd[0]}]
set_property -dict {PACKAGE_PIN R26 IOSTANDARD LVCMOS18} [get_ports {rgmii_rxd[1]}]
set_property -dict {PACKAGE_PIN N24 IOSTANDARD LVCMOS18} [get_ports {rgmii_rxd[2]}]
set_property -dict {PACKAGE_PIN P24 IOSTANDARD LVCMOS18} [get_ports {rgmii_rxd[3]}]
set_property -dict {PACKAGE_PIN N21 IOSTANDARD LVCMOS18} [get_ports {rgmii_txc}]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS18} [get_ports {rgmii_tx_ctl}]
set_property -dict {PACKAGE_PIN R20 IOSTANDARD LVCMOS18} [get_ports {rgmii_txd[0]}]
set_property -dict {PACKAGE_PIN R21 IOSTANDARD LVCMOS18} [get_ports {rgmii_txd[1]}]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS18} [get_ports {rgmii_txd[2]}]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD LVCMOS18} [get_ports {rgmii_txd[3]}]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports {phy_mdc}]
set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVCMOS33} [get_ports {phy_mdio}]
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS33} [get_ports {eeprom_scl}]
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports {eeprom_sda}]
# FMC-FH G6/G7: DATA_CLK_P/N
set_property -dict {PACKAGE_PIN AC19 IOSTANDARD LVDS} [get_ports {ad_data_clk_p}]
set_property -dict {PACKAGE_PIN AD19 IOSTANDARD LVDS} [get_ports {ad_data_clk_n}]
# FMC-FH D8/D9: RX_FRAME_P/N
set_property -dict {PACKAGE_PIN AD21 IOSTANDARD LVDS} [get_ports {ad_rx_frame_p}]
set_property -dict {PACKAGE_PIN AE21 IOSTANDARD LVDS} [get_ports {ad_rx_frame_n}]
# FMC-FH H7/H8, G9/G10, H9/H10, D11/D12, C10/C11, H12/H13: RX_D0..RX_D5
set_property -dict {PACKAGE_PIN AE17 IOSTANDARD LVDS} [get_ports {ad_rx_data_p[0]}]
set_property -dict {PACKAGE_PIN AF17 IOSTANDARD LVDS} [get_ports {ad_rx_data_n[0]}]
set_property -dict {PACKAGE_PIN AD16 IOSTANDARD LVDS} [get_ports {ad_rx_data_p[1]}]
set_property -dict {PACKAGE_PIN AE16 IOSTANDARD LVDS} [get_ports {ad_rx_data_n[1]}]
set_property -dict {PACKAGE_PIN AF18 IOSTANDARD LVDS} [get_ports {ad_rx_data_p[2]}]
set_property -dict {PACKAGE_PIN AF19 IOSTANDARD LVDS} [get_ports {ad_rx_data_n[2]}]
set_property -dict {PACKAGE_PIN AE25 IOSTANDARD LVDS} [get_ports {ad_rx_data_p[3]}]
set_property -dict {PACKAGE_PIN AE26 IOSTANDARD LVDS} [get_ports {ad_rx_data_n[3]}]
set_property -dict {PACKAGE_PIN AF24 IOSTANDARD LVDS} [get_ports {ad_rx_data_p[4]}]
set_property -dict {PACKAGE_PIN AF25 IOSTANDARD LVDS} [get_ports {ad_rx_data_n[4]}]
set_property -dict {PACKAGE_PIN AC18 IOSTANDARD LVDS} [get_ports {ad_rx_data_p[5]}]
set_property -dict {PACKAGE_PIN AD18 IOSTANDARD LVDS} [get_ports {ad_rx_data_n[5]}]
# FMC-FH G12/G13: FB_CLK_P/N
set_property -dict {PACKAGE_PIN AE22 IOSTANDARD LVDS} [get_ports {ad_fb_clk_p}]
set_property -dict {PACKAGE_PIN AF22 IOSTANDARD LVDS} [get_ports {ad_fb_clk_n}]
# FMC-FH D14/D15: TX_FRAME_P/N
set_property -dict {PACKAGE_PIN AB25 IOSTANDARD LVDS} [get_ports {ad_tx_frame_p}]
set_property -dict {PACKAGE_PIN AB26 IOSTANDARD LVDS} [get_ports {ad_tx_frame_n}]
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVDS} [get_ports {ad_tx_data_p[0]}]
set_property -dict {PACKAGE_PIN AC17 IOSTANDARD LVDS} [get_ports {ad_tx_data_n[0]}]
set_property -dict {PACKAGE_PIN AD23 IOSTANDARD LVDS} [get_ports {ad_tx_data_p[1]}]
set_property -dict {PACKAGE_PIN AE23 IOSTANDARD LVDS} [get_ports {ad_tx_data_n[1]}]
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVDS} [get_ports {ad_tx_data_p[2]}]
set_property -dict {PACKAGE_PIN AA18 IOSTANDARD LVDS} [get_ports {ad_tx_data_n[2]}]
set_property -dict {PACKAGE_PIN AB24 IOSTANDARD LVDS} [get_ports {ad_tx_data_p[3]}]
set_property -dict {PACKAGE_PIN AC24 IOSTANDARD LVDS} [get_ports {ad_tx_data_n[3]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVDS} [get_ports {ad_tx_data_p[4]}]
set_property -dict {PACKAGE_PIN AA17 IOSTANDARD LVDS} [get_ports {ad_tx_data_n[4]}]
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVDS} [get_ports {ad_tx_data_p[5]}]
set_property -dict {PACKAGE_PIN AB19 IOSTANDARD LVDS} [get_ports {ad_tx_data_n[5]}]
# FMC-FH G18/G19: ENABLE/TXNRX; H21/H23: EN_AGC/SYNC_IN; D26/D27: SPI_ENB/SPI_CLK;
# C26/C27: SPI_DI/SPI_DO; H31: RESETB.
set_property -dict {PACKAGE_PIN AD24 IOSTANDARD LVCMOS18} [get_ports {ad_enable}]
set_property -dict {PACKAGE_PIN AD25 IOSTANDARD LVCMOS18} [get_ports {ad_txnrx}]
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS18} [get_ports {ad_en_agc}]
set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS18} [get_ports {ad_sync_in}]
set_property -dict {PACKAGE_PIN W25 IOSTANDARD LVCMOS18} [get_ports {ad_spi_cs_n}]
set_property -dict {PACKAGE_PIN W26 IOSTANDARD LVCMOS18} [get_ports {ad_spi_clk}]
set_property -dict {PACKAGE_PIN U26 IOSTANDARD LVCMOS18} [get_ports {ad_spi_mosi}]
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS18} [get_ports {ad_spi_miso}]
set_property -dict {PACKAGE_PIN AA24 IOSTANDARD LVCMOS18} [get_ports {ad_resetb}]
set_property PULLTYPE PULLUP [get_ports {phy_mdio eeprom_scl eeprom_sda}]
set_property PULLTYPE PULLUP [get_ports ad_spi_cs_n]
set_property SLEW FAST [get_ports {rgmii_txc rgmii_tx_ctl rgmii_txd[*]}]



set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 51.0 [current_design] 
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] 
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]
