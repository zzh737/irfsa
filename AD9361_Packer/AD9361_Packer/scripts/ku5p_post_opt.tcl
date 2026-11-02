# Adjacent CMTs use the device's dedicated clock backbone. Apply after opt_design
# has inserted the input BUFGCEs; do not permit fabric clock routing.
foreach name {sys_clock_BUFGCE rgmii_rxc_IBUF_BUFGCE} {
 set net [get_nets -quiet $name]
 if {[llength $net] == 1} {
  set_property CLOCK_DEDICATED_ROUTE BACKBONE $net
 } else {
  # The direct multi-rate RGMII path may be optimized into a different
  # BUFGCE net name.  Do not fail the build on a stale hierarchy name.
  puts "INFO: optional clock backbone net not present: $name"
 }
}
# Keep the matched Ethernet data/forward-clock trees in the I/O-side column.
# The automatic X1Y1 root adds avoidable differential clock insertion delay.
# This is physical placement only; no external timing budget or phase changes.
set_property USER_CLOCK_ROOT X0Y1 [get_nets -of_objects [get_pins {tx_buf/O tx90_buf/O}]]
# RGMII RX clock: the automatic root (X1Y0) put ~1.3..2.7 ns of uncompensated
# insertion delay on the IDDR clock, more spread than the 2 ns RGMII window.
# Rooting it in the RX I/O region (X0Y1) shortens and tightens that delay; the
# fixed data IDELAY in us_ssio.sv is sized for this placement.
set rx_clk_buf [get_cells -quiet network/mac/eth_mac_1g_rgmii_inst/rgmii_phy_if_inst/rx_ssio_ddr_inst/input_buf]
if {[llength $rx_clk_buf] == 1} {
 set_property USER_CLOCK_ROOT X0Y1 [get_nets -of_objects [get_pins -of_objects $rx_clk_buf -filter {REF_PIN_NAME == O}]]
} else {
 error "RGMII RX BUFG not found; USER_CLOCK_ROOT not applied"
}
