# Physical implementation settings, also reapplied before the release gate.
# The multi-rate RGMII input now uses the source-synchronous RX clock
# directly, so there is no fixed-rate RX MMCM to phase-shift.  Keep this
# conditional for old checkpoints that still contain the compensator.
set rx [get_cells -quiet network/mac/eth_mac_1g_rgmii_inst/rgmii_phy_if_inst/rx_ssio_ddr_inst/rx_mmcm]
if {[llength $rx] == 1} {set_property CLKOUT0_PHASE -54.0 $rx}
# Balance actual device output delays; keep the PHY setup/hold and PCB budgets.
set_property DRIVE 4 [get_ports {rgmii_txc rgmii_txd[1]}]
