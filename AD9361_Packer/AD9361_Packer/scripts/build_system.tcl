set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build ku5p_system]
set report [file join $root reports system_build]
set_param general.maxThreads 8
create_project -force ku5p_system $out -part xcku5p-ffvb676-2-i
source [file join $root scripts system_sources.tcl]
add_files -norecurse $ku5p_sources
add_files -norecurse [glob $root/rtl/rom/*.mem]
add_files -fileset constrs_1 [list $root/constraints/ku5p_pins.xdc $root/constraints/ku5p_timing.xdc]
set_property top ku5p_top [get_filesets sources_1]
set_property verilog_define {} [get_filesets sources_1]
update_compile_order -fileset sources_1
file mkdir $out/work
foreach f [glob $root/rtl/rom/*.mem] {file copy -force $f $out/work/}
cd $out/work
synth_design -top ku5p_top -part xcku5p-ffvb676-2-i
write_checkpoint -force $report/raw_synth.dcp
source $root/scripts/ku5p_post_synth.tcl
write_checkpoint -force $report/synth.dcp
report_utilization -file $report/synth_utilization.rpt
report_timing_summary -file $report/synth_timing.rpt
report_cdc -details -file $report/synth_cdc.rpt
opt_design
source $root/scripts/ku5p_post_opt.tcl
place_design
phys_opt_design
route_design
source $root/scripts/ku5p_pre_bitstream.tcl
write_bitstream -force $report/ku5p_system_candidate.bit
puts "KU5P_CANDIDATE_BUILD_COMPLETE"
exit
