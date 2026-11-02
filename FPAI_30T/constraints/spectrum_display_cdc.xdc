# Mailbox remains stable from GP COMMIT until pixel frame-boundary ACK.
# Pixel RAM reads the front bank; GP only writes the inactive bank.
set display_req0 [get_cells -quiet -hier -regexp {.*U_display/req_sync_reg\[0\]}]
set display_ack0 [get_cells -quiet -hier -regexp {.*U_display/ack_sync_reg\[0\]}]
set_false_path -to $display_req0
set_false_path -to $display_ack0
set display_source [get_cells -quiet -hier -filter {IS_SEQUENTIAL == 1} -regexp {.*U_display/(cap|seq|class_id|confidence|flags|write_bank)_reg.*}]
set display_target [get_cells -quiet -hier -filter {IS_SEQUENTIAL == 1} -regexp {.*U_display/active_(cap|seq|class|conf|flags|bank)_reg.*}]
set_max_delay -datapath_only 13.468 -from $display_source -to $display_target
# Verify actual pin paths, clock derivation and dual-clock RAM inference after
# vendor synthesis; these object matches are not a substitute for report_cdc.
