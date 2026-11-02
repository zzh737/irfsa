# GUI project release gate, executed in the implemented design before write_bitstream.
set root [file normalize [file join [file dirname [info script]] ..]]
set report [file join $root reports system_build]
file mkdir $report
source $root/scripts/ku5p_io_config.tcl
write_checkpoint -force $report/routed.dcp
report_timing_summary -report_unconstrained -file $report/routed_timing.rpt
report_drc -file $report/drc.rpt
report_route_status -file $report/route_status.rpt
report_utilization -file $report/routed_utilization.rpt
report_cdc -details -file $report/routed_cdc.rpt
set fh [open $report/routed_cdc.rpt r]
set cdc_checks [read $fh]
close $fh
if {[regexp -line {^CDC-[0-9]+[ \t]+Critical[ \t]+[1-9][0-9]*} $cdc_checks]} {
 error "Critical CDC structure detected; no release bitstream"
}
report_bus_skew -file $report/bus_skew.rpt
set fh [open $report/bus_skew.rpt r]
set skew_checks [read $fh]
close $fh
if {[string first "VIOLATED" $skew_checks] >= 0} {error "Bus skew failed; no release bitstream"}
report_methodology -file $report/methodology.rpt
check_timing -verbose -file $report/check_timing.rpt
set fh [open $report/check_timing.rpt r]
set timing_checks [read $fh]
close $fh
if {[regexp {checking (no_clock|unconstrained_internal_endpoints) \([1-9][0-9]*\)} $timing_checks]} {
 error "Missing internal timing constraints; no release bitstream"
}
set bad_drc [get_drc_violations -quiet -filter {SEVERITY == "Error" || SEVERITY == "Critical Warning"}]
if {[llength $bad_drc]} {error "DRC failed; no release bitstream"}
set bad_setup [get_timing_paths -quiet -slack_lesser_than 0 -max_paths 1]
set bad_hold [get_timing_paths -quiet -hold -slack_lesser_than 0 -max_paths 1]
if {[llength $bad_setup] || [llength $bad_hold]} {error "Timing failed; no release bitstream"}
