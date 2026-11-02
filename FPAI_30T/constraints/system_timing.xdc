# Board timing baseline. Post-link vendor clock exceptions are in
# system_vendor_cdc.xdc (implementation only, LATE).

set_property LOC PLLE2_ADV_X1Y3 [get_cells U0_ps_ai_peripheral/ZGolo/u_AI_Mate_top/clkrst_wrapper_u0/AI_CORE_CLK/inst/plle2_adv_inst]

set_false_path -from [get_ports sys_rst]
set_false_path -to [get_ports {led[0]}]
set_false_path -to [get_ports {led[1]}]
# Static PHY reset level; release timing is defined by the 20 ms reset sequencer.
set_false_path -to [get_ports PS_PHY_RESET_N]
# Sampled video-reset mode: only the first D pin is the intentional CDC entry.
# Bound its physical datapath to one 74.25 MHz pixel period; stages 0->1->2
# and the reset consumers retain ordinary setup/hold checks. This does not
# exempt synchronous R pins or downstream reset distribution.
set video_reset_entry [get_pins -quiet -hier -regexp {video_reset/sampled_reset.entry_ff/D}]
set video_reset_sources [get_cells -quiet -hier -regexp {.*rst_d2_gp_clk_reg}]
set_max_delay -datapath_only 13.468 -from $video_reset_sources -to $video_reset_entry
# GP/HP share clk_wiz_0. Keep them timed; product mailbox constraints set
# explicit datapath bounds instead of hiding all traffic between these clocks.
