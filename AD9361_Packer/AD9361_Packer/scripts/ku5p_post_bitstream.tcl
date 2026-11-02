set root [file normalize [file join [file dirname [info script]] ..]]
set bitfile [file join [pwd] ku5p_top.bit]
if {![file exists $bitfile]} {error "GUI bitstream output missing"}
file copy -force $bitfile [file join $root reports system_build ku5p_system_candidate.bit]
puts "KU5P_CANDIDATE_BUILD_COMPLETE"
