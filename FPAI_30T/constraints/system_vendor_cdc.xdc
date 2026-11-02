# These generated clocks live inside OOC IP and are unavailable while the top
# is being synthesized with black boxes. Read only after implementation links
# the IP checkpoints and creates their clocks; never silently skip a match.
# Preserve supplier NPU bridge exceptions inside ZGolo only. clk_pll_i also
# drives product HP logic, whose timing and mailbox bounds remain enabled.
set vendor_gp_clock [get_clocks clk_out1_clk_wiz_0]
set vendor_ai_clock [get_clocks clk_pll_i]
set vendor_gp_regs [filter [all_registers -clock $vendor_gp_clock] {NAME =~ U0_ps_ai_peripheral/ZGolo/*}]
set vendor_ai_regs [filter [all_registers -clock $vendor_ai_clock] {NAME =~ U0_ps_ai_peripheral/ZGolo/*}]
set_false_path -from $vendor_gp_regs -to $vendor_ai_regs
set_false_path -from $vendor_ai_regs -to $vendor_gp_regs
# scripts/report_constraint_coverage.tcl asserts non-empty matches after linking.
# Keep this file within Vivado 2018.3's supported XDC command subset.
