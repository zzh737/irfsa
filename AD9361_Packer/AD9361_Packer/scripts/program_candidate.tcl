# Run only with a powered board and JTAG attached.
set root [file normalize [file join [file dirname [info script]] ..]]
set bitfile $root/reports/system_build/ku5p_system_candidate.bit
if {![file exists $bitfile]} {error "No timing-qualified candidate bitstream"}
set python_cmd [auto_execok python]
if {[llength $argv]} {set python_cmd [list [lindex $argv 0]]}
if {![llength $python_cmd]} {error "Use python scripts/program_candidate.py to verify the release before programming"}
puts [exec {*}$python_cmd [file join $root scripts verify_candidate.py]]
open_hw_manager
connect_hw_server
open_hw_target
set devices [get_hw_devices -filter {PART =~ "xcku5p*"}]
if {[llength $devices]!=1} {error "Expected exactly one KU5P device; select hardware manually"}
set dev [lindex $devices 0]
current_hw_device $dev
set_property PROGRAM.FILE $bitfile $dev
program_hw_devices $dev
refresh_hw_device $dev
