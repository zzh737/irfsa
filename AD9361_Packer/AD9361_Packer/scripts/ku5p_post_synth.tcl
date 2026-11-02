# Point-to-point CDC exceptions; do not group whole clocks.
set root [file normalize [file join [file dirname [info script]] ..]]
set_param general.maxThreads 8
# Keep the TX clock source in the Ethernet I/O clock region. The RX clock
# compensator uses the adjacent CMT; both connections must pass clock DRC.
set tx_mmcm [get_cells -quiet mmcm]
if {[llength $tx_mmcm]} {set_property LOC MMCM_X0Y1 $tx_mmcm}
# The RGMII RX path is source-synchronous and now supports 10/100/1000 Mbps
# directly.  Older builds had a fixed 125-MHz RX MMCM here; there is no such
# cell in the multi-rate implementation.
set rx_mmcm [get_cells -quiet network/mac/eth_mac_1g_rgmii_inst/rgmii_phy_if_inst/rx_ssio_ddr_inst/rx_mmcm]
if {[llength $rx_mmcm]} {set_property LOC MMCM_X0Y2 $rx_mmcm}
# The two TX dividers share the same MMCM 250 MHz output.
if {[llength $tx_mmcm]} {set_property PHASESHIFT_MODE WAVEFORM $tx_mmcm}
set_property CLOCK_DELAY_GROUP rgmii_tx_pair [get_nets -of_objects [get_pins {tx_buf/O tx90_buf/O}]]
# Legacy only (no rx_mmcm in the BUFG build).
if {[llength $rx_mmcm]} {set_property PHASESHIFT_MODE LATENCY $rx_mmcm}
# AD9361 uses an actual quarter-cycle sampling edge. Its next input transition
# is a hold edge, not the same launch edge with 2.5 ns of extra clock latency.
set_property PHASESHIFT_MODE WAVEFORM [get_cells lvds/rx_mmcm]
source $root/scripts/ku5p_io_config.tcl
# The PHY advertises 10/100/1000 and LINK accepts speed 01 or 10.  STA times
# the gigabit mode only: there the forwarded DDR clock is exactly D1=1,D2=0,
# and the case analysis stops STA treating a falling-clock D2 event as an
# output rise.  In 100M mode (rgmii_phy_if.v) TXD is identical on both DDR
# halves, changes only when gmii_clk_en pulses (every 5 x 8 ns), and the
# 25 MHz TXC rises two clk cycles later, so data has ~16 ns setup / ~24 ns
# hold at the PHY: the gigabit 4 ns window bounds it.  This argument was
# reviewed by hand (2026-10-27), not by a separate 100M STA run.
set phy_if network/mac/eth_mac_1g_rgmii_inst/rgmii_phy_if_inst
set_case_analysis 1 [get_pins $phy_if/rgmii_tx_clk_1_reg/Q]
set_case_analysis 0 [get_pins $phy_if/rgmii_tx_clk_2_reg/Q]
foreach f {
 vendor/verilog-ethernet/lib/axis/syn/vivado/axis_async_fifo.tcl
 vendor/verilog-ethernet/lib/axis/syn/vivado/sync_reset.tcl
 vendor/verilog-ethernet/syn/vivado/eth_mac_fifo.tcl
 vendor/verilog-ethernet/syn/vivado/eth_mac_1g_rgmii.tcl
} {source [file join $root $f]}
set_property ASYNC_REG TRUE [get_cells -hier -regexp {.*(rx_rst_reg_reg|tx_rst_reg_reg)\[.*\]}]
foreach pattern {
 {.*(req_sync|ready_sync|mask0_sync|mask1_sync|ack_sync|lvds_lock_sync|lvds_reset_sync|lvds_unlock_sync)_reg\[0\]/D}
 {.*(scl_sync|sda_sync|mdio_sync)_reg\[0\]/D}
} {
 set dst [get_pins -quiet -hier -regexp $pattern]
 if {[llength $dst]} {set_false_path -to $dst}
}
foreach pair {{overflow_gray_reg overflow_count_sync1_reg}
 {clip_gray1_reg clip1_sync1_reg} {clip_gray2_reg clip2_sync1_reg}
 {rx_samples_gray_reg rx_samples_sync1_reg} {rx_errors_gray_reg rx_errors_sync1_reg}
 {tx1_nonzero_gray_reg tx1_nonzero_sync1_reg} {tx2_nonzero_gray_reg tx2_nonzero_sync1_reg}
 {frame_gray_reg frame_sync1_reg}} {
 lassign $pair a b
 set src [get_cells -quiet -hier -regexp [format {.*%s\[.*\]} $a]]
 set dst [get_cells -quiet -hier -regexp [format {.*%s\[.*\]} $b]]
 if {[llength $src] && [llength $dst]} {
  set_max_delay -datapath_only 8.000 -from $src -to $dst
  set_bus_skew 8.000 -from $src -to $dst
 }
}
# Observer trace is held until acknowledgment; both bus stages precede its request.
foreach pair {{change_gray_reg change_sync1_reg} {snapshot_hold_reg snapshot_sync1_reg}} {
 lassign $pair a b
 set src [get_cells -quiet -hier -regexp [format {rx_observer/%s\[.*\]} $a]]
 set dst [get_cells -quiet -hier -regexp [format {rx_observer/%s\[.*\]} $b]]
 if {[llength $src] && [llength $dst]} {
  set_max_delay -datapath_only 8.000 -from $src -to $dst
  set_bus_skew 8.000 -from $src -to $dst
 }
}
set_false_path -to [get_pins -quiet -hier -regexp {rx_observer/(request_sync|acknowledge_sync)_reg\[0\]/D}]
# Producer holds configuration until ack; cap physical mailbox propagation.
set cfg_src [get_cells -quiet -hier -regexp {control/dsp_config_reg\[.*\]}]
set cfg_dst [get_cells -quiet -hier -regexp {held_config_reg\[.*\]}]
if {[llength $cfg_src] && [llength $cfg_dst]} {set_max_delay -datapath_only 8 -from $cfg_src -to $cfg_dst}
# Each clock domain releases its asynchronous resets synchronously.
set_false_path -to [get_pins -quiet -hier -filter {(REF_PIN_NAME == CLR || REF_PIN_NAME == PRE) && NAME != tx_buf/CLR && NAME != tx90_buf/CLR}]
