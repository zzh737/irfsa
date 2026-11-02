# Register clocks: vendor gp=100 MHz, hp=200 MHz. Check report_clocks after build.
# Mailboxes stay stable until completion; request/ack each have two sync stages.
set req0 [get_cells -quiet -hier -regexp {.*U_rf_custom_op/req_sync_reg\[0\]}]
set ack0 [get_cells -quiet -hier -regexp {.*U_rf_custom_op/ack_sync_reg\[0\]}]
set_false_path -to $req0
set_false_path -to $ack0
set commands [get_cells -quiet -hier -filter {IS_SEQUENTIAL == 1} -regexp {.*U_rf_custom_op/cmd_.*_reg.*}]
set hp_sinks [get_cells -quiet -hier -filter {IS_SEQUENTIAL == 1} -regexp {.*U_rf_custom_op/(src|dst|state|hp_error|ack_toggle|is_fft|fft_window|fft_start|bad_mode|bad_frame|overlap)_reg.*}]
set_max_delay -datapath_only 5.000 -from $commands -to $hp_sinks
set results [get_cells -quiet -hier -filter {IS_SEQUENTIAL == 1} -regexp {.*U_rf_custom_op/hp_error_reg.*}]
set gp_sinks [get_cells -quiet -hier -filter {IS_SEQUENTIAL == 1} -regexp {.*U_rf_custom_op/error(_code)?_reg.*}]
set_max_delay -datapath_only 10.000 -from $results -to $gp_sinks
# A post-synthesis report_cdc / timing review is still mandatory for board release.
