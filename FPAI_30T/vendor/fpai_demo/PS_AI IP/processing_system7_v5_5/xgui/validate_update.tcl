source_ipfile "xgui/userparamlist.tcl"
source_ipfile "xgui/guiparamlist.tcl"
source_ipfile "xgui/webtalk.tcl"

global global_list 
global guiparamlist
global global_list_board 
global xci_value_list 
global xci_range_list 
set preset_applied false
set board_preset_apply false
set print_warn true
set error_msg_workaround true
set error_param_list {}
set debug_on false
set device_context {}
set i 1
proc debug_message {severity message} {
	variable i
	variable debug_on
	incr i
	if {$debug_on == true} {
		send_msg_id PS7-$i INFO $message -verbose
	}
}

proc web_talk { IpView } {
    
	set paramValue	""
	set count 0
	#We will add  the automatic version stuff later
	#set vlnv [ get_property VLNV ]
	#set vlnvSplit [split $vlnv : ]
	#set verVal [ lindex $vlnvSplit end ]
	set verVal "5.5"
	foreach key [getwebtalkuserparam] {
		set value [ get_property PARAM_VALUE.${key} ]
		
		if { $value == "<Select>"  || $value == "NA" } {
				continue ;
		}
		
		if { $count > "0" } {
			append paramValue ", "
		}
		append paramValue $key "=" $value
		
		incr count

    if { [expr $count % 50] == 0 } {
      append paramValue "\\\n"
    }

	}
      	
	set retString "(* CORE_GENERATION_INFO = \"processing_system7_v5.5 ,processing_system7_v5.5_user_configuration,{ $paramValue }\" *)"
	
	#send_msg_id PS7-$count INFO $retString -verbose	
	# Return the string buffer of Power Generation properties
    return $retString 
}

proc hwhand_off { IpView } {
    
	set paramValue	""
	set count 0
	set InstName [get_property PARAM_VALUE.Component_Name]     	
	set retString "(* HW_HANDOFF = \"${InstName}.hwdef\" *) "
	
	#send_msg_id PS7-$count INFO $retString -verbose	
	# Return the string buffer of Power Generation properties
    return $retString 
}
proc zynq_getDeviceString { } {
    set retVal {}
    variable device_context
    set c_family  [string tolower [get_project_property FAMILY]]
    set c_arch    [string tolower [get_project_property ARCHITECTURE]]
    set c_package [string tolower [get_project_property PACKAGE]]
    set c_device  [string tolower [get_project_property DEVICE]]
    set c_speed_t [string tolower [get_project_property SPEEDGRADE] ]
    set c_speed   -[string index $c_speed_t "1"] 
    set c_part    [string tolower [get_project_property PART] ]
    set c_target  [string tolower [get_project_property PREFHDL] ]
    set c_datapath [ ipgui::get_coredir]
    set c_silicon_version "3"
    set c_pcore_name "processing_system7"
    set c_pcore_ver "5.4"
    set c_instance_name [current_instname]

    tcl::lappend retVal "family"
    tcl::lappend retVal $c_family
    tcl::lappend retVal "device"
    tcl::lappend retVal $c_device
    tcl::lappend retVal "package"
    tcl::lappend retVal $c_package
    tcl::lappend retVal "speedgrade"
    tcl::lappend retVal $c_speed
    
    tcl::lappend retVal "part"
    
    tcl::lappend retVal $c_part
    tcl::lappend retVal "language"
    tcl::lappend retVal $c_target
    tcl::lappend retVal "datapath"
    tcl::lappend retVal $c_datapath
    tcl::lappend retVal "silicon_version"
    tcl::lappend retVal $c_silicon_version
    tcl::lappend retVal "instance_name"
    tcl::lappend retVal $c_instance_name
    tcl::lappend retVal "ps_core_name"
    tcl::lappend retVal $c_pcore_name
    tcl::lappend retVal "ps_core_ver"
    tcl::lappend retVal $c_pcore_ver
    set device_context  $retVal

    #dbg $retVal
    return  $retVal
}

proc Check_for_unbonded_pins {IPINST board} {
  set package_name [ get_property value [ipgui::get_paramspec -name PCW_PACKAGE_NAME -of $IPINST] ]
  if {$package_name == "clg225"} {
	  send_msg_id PS7-6 WARNING "Not all the settings were applied as per the $board preset. Some peripherals get routed out to EMIO as the relevant pins are not bonded in clg225 package." -verbose
  }
}

proc Initialize { IpView } {
  global global_list
  global global_list_board
	#set val [ Ip_zynq_ps7_v1_4_zynq_init -context [ zynq_getDeviceString ] ]
  #  if { $val != "" } {
  #    setvalue $IpView $val 
  #  }
    set global_list_board(PCW_IMPORT_BOARD_PRESET)  "\"None\""
    set global_list_board(PCW_UIPARAM_GENERATE_SUMMARY)  "\"None\""
    set global_list(PCW_PERIPHERAL_BOARD_PRESET) "\"None\"" 

    set c_package [string tolower [get_project_property PACKAGE]]

    # set the package name while initializing
    set_property value $c_package [ipgui::get_paramspec -name PCW_PACKAGE_NAME -of $IpView]
}   

proc uninit { IpView } {
     debug_message 2 "Calling 		     zynq_uninit"                                                                                                                                                                  
     variable device_context
     set ret [ Ip_zynq_ps7_v1_4_zynq_uninit -context  $device_context ]
     #set retval [ Ip_zynq_ps7_v1_4_zynq_init -context $device_context ]
}

proc xdc_generate { IpView val } {
	  # Needed to add FCLK enables information of the design for the create_clock constriants generationn
    # We may need to add FCLK[0..3]_ENABLE params in userparamlist
	
    set constr [ Ip_zynq_ps7_v1_4_xdc_generate -context [ zynq_getDeviceString ] -params [ gettclvalue $IpView ] ]
    set ret [ Ip_zynq_ps7_v1_4_zynq_uninit -context [ zynq_getDeviceString ] ]
    set retVal [ Ip_zynq_ps7_v1_4_generateSDKSpecificFiles -context [ zynq_getDeviceString ] -path  $val -params [ gettclvalue $IpView ] ] 
	if {$constr == ""} {
	  	debug_message 2 "XDC Generation Failed"
	}
	
	set mio_bank1_voltage  [ get_property PARAM_VALUE.PCW_PRESET_BANK1_VOLTAGE ]
	set enet0_io  [ get_property PARAM_VALUE.PCW_ENET0_ENET0_IO ]
	set enet1_io  [ get_property PARAM_VALUE.PCW_ENET1_ENET1_IO ]
	#set mio_bank1_voltage [get_property value [ipgui::get_paramspec -name "PCW_PRESET_BANK1_VOLTAGE" -of $val] ]
	#set enet0_io [get_property value [ipgui::get_paramspec -name "PCW_ENET0_ENET0_IO" -of $val] ]
	#set enet1_io [get_property value [ipgui::get_paramspec -name "PCW_ENET1_ENET1_IO" -of $val] ]
	if { ( $enet0_io ==  "MIO 16 .. 27" ) && ( $mio_bank1_voltage == "LVCMOS 3.3V" ) } { 
		  ipxit::send_msg "CRITICAL WARNING"  1 "Critical Warning:- LVCMOS33 (3.3V) is not supported for RGMII interface in Ethernet0. Recommendation is to use 1.8/2.5V IO."
	}
	if { ( $enet1_io ==  "MIO 28 .. 39" ) && ( $mio_bank1_voltage == "LVCMOS 3.3V" ) } { 
	  ipxit::send_msg "CRITICAL WARNING"  1 "Critical Warning:- LVCMOS33 (3.3V) is not supported for RGMII interface in Ethernet1. Recommendation is to use 1.8/2.5V IO." 
	 }
    # Return the string buffer of XDC properties
	set ret [ Ip_zynq_ps7_v1_4_zynq_uninit -context [ zynq_getDeviceString ] ]
    return $constr
}   

proc power_generate { IpView val } {
    set constr [ Ip_zynq_ps7_v1_4_power_generate -context [ zynq_getDeviceString ] -params [ gettclvalue $IpView ] -path  $val ]
    if {$constr == ""} {
      debug_message 2 "Power Generation Failed"
    }
    # Return the string buffer of Power Generation properties
    return $constr
}



proc updateGlobalList { listgl } {
	global global_list 
	foreach {p v} $listgl {
		set paramValue [string trim [ lindex $v 0 ] {{} }]
    if { $paramValue != ""} {
    #append global_list $p " " "\"$paramValue\" "
    set global_list($p)  "\"$paramValue\""
    }

  }
}

proc setvalue { IpView val } {
  global global_list
	foreach {p v} $val {
    if { $p == "Errors" } {
      continue
    }  
		
		#debug_message 2 "Changeset ParamName: $p"

		# Get new value of the parameter 
		set paramValue [string trim [ lindex $v 0 ] {{} }]
		#debug_message 2 "Changeset ParamValue: $paramValue"

		# Get range of parameters
		set paramRange [lindex $v 1]
		set rangeValues ""
		set idx 0
		set len [tcl::llength $paramRange]
        foreach i $paramRange {
			set newi [ string trim $i {{} } ]
			append rangeValues $newi
			set idx [expr ($idx+1) ]
			if { $idx != $len } {
				append rangeValues ","
			}
		}  
		set rangeValues [ string trim $rangeValues {{} } ]
		#debug_message 2 "Changeset ParamRange: $rangeValues"

		# Get state of the parameter 
		set paramState [ lindex $v 2 ]
		#debug_message 2 "Changeset ParamState: $paramState"

		# Get widget type of the parameter 
		set paramWidget [ lindex $v 3 ]
		#debug_message 2 "Changeset ParamWidget: $paramWidget"

		# Get error status of the parameter 
		set errStatus [ lindex $v 4 ]
		#debug_message 2 "Changeset ParamErrState: $errStatus"

		# set parameter's new value, range and state
    set select_range {}
		if {$rangeValues != 0} {
		  #	set_property range $rangeValues [ipgui::get_paramspec -name $p -of $IpView]
      set select_range "<Select>,$rangeValues"
		}
		
		#debug_message 2 "RangeValue $paramValue : $rangeValues : $paramWidget" 
		if {$rangeValues != "" && $paramValue != ""} {
			set global_list($p)  "\"$paramValue\""
      set v [get_property value [ipgui::get_paramspec -name $p -of $IpView] ]
			set_property range_value $paramValue,$rangeValues [ipgui::get_paramspec -name $p -of $IpView]

		} elseif {$paramWidget == "COMBO"} {
			set_property range_value "<Select>,$select_range" [ipgui::get_paramspec -name $p -of $IpView]
			set global_list($p)  "\"<Select>\""
    } elseif {$paramWidget == "CHECKBOX"} {
			set global_list($p)  "\"0\""
			set_property range_value "0,0,1" [ipgui::get_paramspec -name $p -of $IpView]
    } elseif {$paramWidget == "EDIT"} {
			set_property value $paramValue [ipgui::get_paramspec -name $p -of $IpView]
			set global_list($p)  "\"$paramValue\""
		  #debug_message 2 "MIOTree $p --> $paramValue"
    }

		if { $paramState == "DISABLE"} {
			set_property enabled false [ipgui::get_paramspec -name $p -of $IpView]
		} else {
  		set_property enabled true [ipgui::get_paramspec -name $p -of $IpView]
		}

	}
}

proc dbg { args } {
    ## Make this Zero for prodcution
    set debug 0

    if $debug {
        global  tcl_platform
        if { [ string equal $tcl_platform(platform) windows ] } {
            set f [ ::open con: w ]
        } else {
            set f [ ::open /dev/tty w ]
        }
        foreach x $args {
            ::puts $f "DBG: [ clock format [ clock seconds ] -format %T ] : $x"
        }
        ::close $f
    }
}

proc gettclvalue { ipview } {
        set retVal {}
        set userparamlist [getlistofuserparam]
            foreach value $userparamlist {
                   set paramval  [ get_property PARAM_VALUE.${value} ]
                       tcl::lappend retVal $value
                       tcl::lappend retVal $paramval
            }
        return $retVal
}

proc getlistofSignals {} {
	set signalparamlist [list \
    "PCW_QSPI_GRP_FBCLK_ENABLE" \
    "PCW_FCLK_CLK0_BUF" \
    "PCW_FCLK_CLK1_BUF" \
    "PCW_FCLK_CLK2_BUF" \
    "PCW_FCLK_CLK3_BUF" \
    "PCW_QSPI_GRP_SINGLE_SS_ENABLE" \
    "PCW_UIPARAM_DDR_ROW_ADDR_COUNT" \
    "PCW_UIPARAM_DDR_CWL" \
	"PCW_UIPARAM_DDR_DEVICE_CAPACITY"\
	]
	return $signalparamlist
}

set validate_update_userparams false 
set dependent_value_list {}

proc AffectedBoardList { IpView dependent_list } {
  global global_list
  set new_dependent_list {}
	foreach {p v} $dependent_list {
     if { $p == "Errors" } {
       continue
     }  
     set xciParamList {}
	   set paramValue [string trim [ lindex $v 0 ] {{} }]
     set value [ get_property value [ ipgui::get_paramspec -name $p -of $IpView] ]
     if { $paramValue != $value } {
      tcl::lappend new_dependent_list $p
      tcl::lappend xciParamList $paramValue
      tcl::lappend xciParamList [lindex $v 1]
	    tcl::lappend xciParamList [lindex $v 2]
	    tcl::lappend xciParamList [lindex $v 3]
	    tcl::lappend xciParamList [lindex $v 4]
	    tcl::lappend xciParamList [lindex $v 4]
      tcl::lappend new_dependent_list $xciParamList
     }
	}	
	#debug_message 2 "BOARD LIST $new_dependent_list"
  return $new_dependent_list
}

proc replaceXCIValues { IpView dependent_list xci_list } {
  global global_list
  set new_dependent_list {}
	foreach {p v} $dependent_list {
     if { $p == "Errors" } {
       continue
     }  

     tcl::lappend new_dependent_list $p
     # Update the values of XCI parameters
     set xciParamList {}
	   set paramValue [string trim [ lindex $v 0 ] {{} }]
	   foreach {xciP xciV} $xci_list {
         if { $xciP == $p && $paramValue != "" } {
           set paramValue $xciV
         }
     }      
     tcl::lappend xciParamList $paramValue
     tcl::lappend xciParamList [lindex $v 1]
	   tcl::lappend xciParamList [lindex $v 2]
	   tcl::lappend xciParamList [lindex $v 3]
	   tcl::lappend xciParamList [lindex $v 4]
	   tcl::lappend xciParamList [lindex $v 4]
     tcl::lappend new_dependent_list $xciParamList
     set_property errmsg "" [ ipgui::get_paramspec -name $p -of $IpView]
	}	
	#debug_message 2 "REPLACED LIST $new_dependent_list"
  return $new_dependent_list
}

proc init_params {IPINST} {

	#set ip_rev [get_property CORE_REVISION $IPINST ]
	#if { $ip_rev == "0"} {
	#	return
	#}
  global global_list 
  global global_list_board
	variable validate_update_userparams
	variable dependent_value_list
	variable board_preset_apply 
	global  xci_value_list ;
	global  xci_range_list ;
  variable print_warn
  array set xci_value_list {}
  array set xci_range_list {}
  _init_guiparamlist 

  # Get the XCI list of values
	foreach key [getlistofuserparam] {
			set value [get_property value [ipgui::get_paramspec -name $key -of $IPINST] ]
      set xci_value_list($key)  "\"$value\""
			set range [get_property range [ipgui::get_paramspec -name $key -of $IPINST] ]
      set xci_range_list($key)  "\"$range\""
      #debug_message 2 "$key -- $range" 
	}

  debug_message 2 "init_params" 
	set val [ Ip_zynq_ps7_v1_4_zynq_init -context [ zynq_getDeviceString ] ]
    if { $val != "" } {
      setvalue $IPINST $val 
    }

  Initialize $IPINST

  # Apply Board Preset during initialization
  set c_board_vlnv  [string tolower [get_property board_part [current_project] ] ]
  set c_board [ lindex [split $c_board_vlnv :] 2 ]
	set board_value [get_property value [ipgui::get_paramspec -name "PCW_PERIPHERAL_BOARD_PRESET" -of $IPINST] ]
  if { $c_board != $board_value && $c_board != ""} {
    set board_preset_apply true
	  set_property value $c_board [ipgui::get_paramspec -name "PCW_PERIPHERAL_BOARD_PRESET" -of $IPINST]
    #PCW_PERIPHERAL_BOARD_PRESET_updated_nonpcw $IPINST
  }

   set print_warn false 
   update_XCI_list $IPINST
   set print_warn true  
   #XCi delta parame need to be applied tow times to revert xci param changes done by pcw.
   update_XCI_list $IPINST
  # Set the preset parameter ranges 
  set value [get_property value [ipgui::get_paramspec -name "PCW_IMPORT_BOARD_PRESET" -of $IPINST] ]
  set global_list_board(PCW_IMPORT_BOARD_PRESET)  "\"$value\""
  set_property value $value [ipgui::get_paramspec -name "PCW_IMPORT_BOARD_PRESET" -of $IPINST]

  # Get the nonpcw paramlist 
	foreach key [getlistofnonpcwparam] {
      ${key}_updated_nonpcw $IPINST
  }
}


proc update_XCI_list { IPINST } {

	global xci_value_list ;
	global xci_range_list ;
	global global_list ;
  
  set XCI_value_list {}

  # Get the XCI list of values
	foreach key [getlistofuserparam] {
		if {[info exists global_list($key)]} {
			set value [string trim [ lindex $xci_value_list($key) 0 ] {{} }]
			set paramValue [string trim [ lindex $global_list($key) 0 ] {{} }]
			if { $paramValue != $value && $value != "NA" &&  $value != -1 } {
        tcl::lappend XCI_value_list $key 
        tcl::lappend XCI_value_list $value
        debug_message 2 "Diff: $key  $value --> $paramValue"
			}
    }
    # Clear error messages and apply property value on them
    set_property errmsg "" [ ipgui::get_paramspec -name $key -of $IPINST]
  }

  # Initialize the PCW backend with XCI deltas
  set is_pcw_error false
	if { [ catch { Ip_zynq_ps7_v1_4_get_range -params $XCI_value_list -context [ zynq_getDeviceString ]} dependent_value_list ] } {
		#set_property errmsg $dependent_value_list [ ipgui::get_paramspec -name $key -of $IPINST]
    set_error_msg $IPINST $dependent_value_list 
    set is_pcw_error true
	  debug_message 2 "Error from PCW $dependent_value_list "
		#return false
	} 

  # Set the property values of updated dependency list params
  variable error_msg_workaround
  if {$dependent_value_list != ""} {
	  set global_list($key)  "\"$value\""
    if { $error_msg_workaround == true } {
      setvalue $IPINST [ replaceXCIValues $IPINST $dependent_value_list $XCI_value_list ] 
    } else {
      setvalue $IPINST $dependent_value_list  
    }  
  }

  # Update the values of XCI parameters
	foreach {p v} $XCI_value_list {
	      set global_list($p)  "\"$v\""
			  set range [string trim [ lindex $xci_range_list($p) 0 ] {{} }]
	      #debug_message 2 "XCI Value $p:$v:$range"
		    #set_property value $v [ipgui::get_paramspec -name $p -of $IPINST]
        if { $range == "" } {
		      set_property value $v [ipgui::get_paramspec -name $p -of $IPINST]
        } else {  
			    set_property range_value $v,$range [ipgui::get_paramspec -name $p -of $IPINST]
        }
        if { $is_pcw_error == false } {
	      #debug_message 2 "Clear error $p"
          set_property errmsg "" [ ipgui::get_paramspec -name $p -of $IPINST]
        }
    }      


  # Set the flag true for GUI parameter changes
	set validate_update_userparams true
  set dependent_value_list {}
}

proc set_error_msg { IpView deps} {
  variable error_param_list
  variable print_warn
  #Clear previous error messages
	foreach key $error_param_list {
     debug_message 2 "Clearing Errors :$key"
     set_property errmsg "" [ ipgui::get_paramspec -name $key -of $IpView]
  }
  set error_param_list {}
	foreach {p v} $deps {
    if { $p == "Errors" } {
	set i 0
        set critwarn "Critical_warning:"
        set warn "Warning:"
       foreach {par val} $v {
	   incr i	 
           debug_message 2 "Setting Errors :$par $val"

           if { [string match "$warn*" $val] && $print_warn == true} {
		   set val "[string trim $val $warn ] "
			   send_msg_id PSU-$i WARNING "$val" -verbose
	   } elseif { [string match "$critwarn*" $val ] && $print_warn == true} {
		   set val "[string trim $val $critwarn ] "
			   send_msg_id PSU-$i {CRITICAL WARNING} "$val" -verbose
	   } else {
           	set_property errmsg $val [ ipgui::get_paramspec -name $par -of $IpView]
	   }
           tcl::lappend error_param_list $par 
       }                       
      return
    }
  }  
}

proc _validate_range_guiparam { IPINST param value } {
      global guiparamlist
			if {[info exists guiparamlist($param)]} {
         set enable [get_property enabled [ipgui::get_paramspec -name $param -of $IPINST] ]
         if { $enable == "false" } {
             return ""
         }
				set widgetBox [string trim [ lindex $guiparamlist($param) 0 ] {{} }]
        set range [get_property range [ipgui::get_paramspec -name $param -of $IPINST] ]

        if { $range == "" || $value == "<Select>" || $value == "NA" } {
          return
        }

        set range_list [split $range ,]
        #debug_message 2 "range validation : $param $value $widgetBox $range_list"
        if { $widgetBox == "comboBox" || $widgetBox == "checkBox"} {
            if {[tcl::lsearch $range_list $value ] < 0} {
	       	
              set_property errmsg "PARAM $param is out of range { $range }" [ ipgui::get_paramspec -name $param -of $IPINST]
	      set err_msg_param {}
	      tcl::lappend err_msg_param $param
	      tcl::lappend err_msg_param  "PARAM $param :: $value is out of range { $range }" 
	      return $err_msg_param
            }
        } elseif { $widgetBox == "textBox" && [llength $range_list] > 1} {
		      set minVal [ lindex $range_list 0 ]
		      set maxVal [ lindex $range_list 1 ]
          if { $value < $minVal || $value > $maxVal } {
              set_property errmsg "PARAM $param is out of range { $range }" [ ipgui::get_paramspec -name $param -of $IPINST]
	      set err_msg_param {}
	      tcl::lappend err_msg_param $param
	      tcl::lappend err_msg_param  "PARAM $param :: $value is out of range { $range }" 
	      return $err_msg_param
          }
        }
       } 
       DDRRangeValidation $IPINST $param ;
       return ""
}

proc update_all { IPINST t1 } {
  variable validate_update_userparams
  debug_message 2 "update_all proc $t1"
  set update_value_list {}
  set update_nonpcw_list {}
  set bank_voltage_list {}
  set clock_override_param {}  
  set err_msg_value {} 
  set userparamlist [getlistofuserparam] 
  foreach item [dict keys $t1] {
    set userparam $item
    set updateValue [dict get $t1 $item]
    if { $userparam == "Component_Name" } {
      continue
    }
   if { $userparam == "PCW_PRESET_BANK0_VOLTAGE" || $userparam == "PCW_PRESET_BANK1_VOLTAGE" } {
      tcl::lappend bank_voltage_list $userparam 
      tcl::lappend bank_voltage_list $updateValue 
    } elseif { $userparam == "PCW_OVERRIDE_BASIC_CLOCK" } { 
      tcl::lappend clock_override_param $userparam 
      tcl::lappend clock_override_param $updateValue 
   } elseif {[tcl::lsearch $userparamlist $userparam] >= 0} {
      tcl::lappend update_value_list $userparam 
      tcl::lappend update_value_list $updateValue 
	} else {
      tcl::lappend update_nonpcw_list $userparam 
      tcl::lappend update_nonpcw_list $updateValue 
    }
  }
  
  foreach {p v} $update_nonpcw_list {
          # Call non pcw procedures
          set userparam $p
          set updateValue $v
          debug_message 2 "Calling non pcw user proc ${userparam}_updated_nonpcw"
			    set_property value $updateValue [ipgui::get_paramspec -name $userparam -of $IPINST]
			    if {[info commands ${userparam}_updated_nonpcw] != ""} {
            ${userparam}_updated_nonpcw $IPINST
          } else {
            debug_message 2 "param proc does not exist"
          }
      }

 debug_message 2 "update_all $update_value_list :::: $update_nonpcw_list"
 if { $bank_voltage_list != ""} {
   update_param_list  $IPINST $bank_voltage_list $userparam
 }
 update_param_list  $IPINST $update_value_list $userparam
 
 if { $clock_override_param != ""} {
   update_param_list  $IPINST $clock_override_param $userparam
 }

 set reterr [_validate_range_guiparam $IPINST $userparam $updateValue]
    #set reterr ""
    if { $reterr != ""} {
     tcl::lappend err_msg_value $reterr
    }

	foreach {p} $err_msg_value {
		set param [lindex $p 0]
		set value [lindex $p 1]
              set_property errmsg $value [ ipgui::get_paramspec -name $param -of $IPINST]
}
  set mio_bank1_voltage [get_property value [ipgui::get_paramspec -name "PCW_PRESET_BANK1_VOLTAGE" -of $IPINST] ]
  set enet0_io [get_property value [ipgui::get_paramspec -name "PCW_ENET0_ENET0_IO" -of $IPINST] ]
  set enet1_io [get_property value [ipgui::get_paramspec -name "PCW_ENET1_ENET1_IO" -of $IPINST] ]
  if { ( $enet0_io ==  "MIO 16 .. 27" ) && ( $mio_bank1_voltage == "LVCMOS 3.3V" ) } { 
	  send_msg_id PS7-6 "CRITICAL WARNING" " LVCMOS33 (3.3V) is not supported for RGMII interface in Ethernet0. Recommendation is to use 1.8/2.5V IO."
  }
  if { ( $enet1_io ==  "MIO 28 .. 39" ) && ( $mio_bank1_voltage == "LVCMOS 3.3V" ) } { 
	  send_msg_id PS7-6  "CRITICAL WARNING" "LVCMOS33 (3.3V) is not supported for RGMII interface in Ethernet1. Recommendation is to use 1.8/2.5V IO."
  }

  PCW_EN_CLK0_PORT_updated_nonpcw $IPINST
  PCW_EN_CLK1_PORT_updated_nonpcw $IPINST
  PCW_EN_CLK2_PORT_updated_nonpcw $IPINST
  PCW_EN_CLK3_PORT_updated_nonpcw $IPINST
  return true;
}

proc update_param_list { IPINST update_value_list  userparam} {

 variable dependent_value_list
 set dependent_value_list {}
 global global_list 
  #debug_message 2 "update_all $t1"
  if { $update_value_list != "" } {
  				set value [get_property value [ipgui::get_paramspec -name $userparam -of $IPINST] ]
				  set_property errmsg "" [ ipgui::get_paramspec -name $userparam -of $IPINST]
					set global_list($userparam)  "\"$value\""
					debug_message 2 "Set $update_value_list"
           if { [ catch { [Ip_zynq_ps7_v1_4_is_zynq_instance -context [ zynq_getDeviceString ] ] } ] } {
                  if { [ catch { Ip_zynq_ps7_v1_4_get_ranges -context [ zynq_getDeviceString ] -userparams [ gettclvalue $IPINST ] -params $update_value_list } dependent_value_list ] } {
                          #set_error_msg $IPINST $dependent_value_list 
                          #return false
                  }
          } else {

                  if { [ catch { Ip_zynq_ps7_v1_4_is_default_zynq_instance -context [ zynq_getDeviceString ] } set_defaut_value] } {
                    if { [ catch { Ip_zynq_ps7_v1_4_get_range -params $update_value_list -context [ zynq_getDeviceString ]} dependent_value_list ] } {
                    }
                  } else {
                    if { [ catch { Ip_zynq_ps7_v1_4_get_range -params [gettclvalue $IPINST] -context [ zynq_getDeviceString ]} dependent_value_list ] } {
                    }
                    set dependent_value_list {}
                    if { [ catch { Ip_zynq_ps7_v1_4_get_range -params $update_value_list -context [ zynq_getDeviceString ]} dependent_value_list ] } {
                    }
                  }
          }        
        debug_message 2 "Validate_all $userparam <--> $dependent_value_list"

	      foreach {p v} $update_value_list {
			    set_property value $v [ipgui::get_paramspec -name $p -of $IPINST]
        }  

        # Call setvalue to set list of param and values
        setvalue $IPINST $dependent_value_list
        #setvalue $IPINST [ replaceXCIValues $IPINST $dependent_value_list $update_value_list] 
		set_error_msg $IPINST $dependent_value_list 

       } 
 
    return true
}

proc PCW_IMPORT_BOARD_PRESET_updated_nonpcw { IpView } {
	variable validate_update_userparams
	variable dependent_value_list
	set dependent_value_list {}
	variable preset_applied
  global global_list_board 
			if {[info exists global_list_board(PCW_IMPORT_BOARD_PRESET)]} {
        set key "PCW_IMPORT_BOARD_PRESET"
				set value [ get_property value [ipgui::get_paramspec -name $key -of $IpView] ]
				set paramValue [string trim [ lindex $global_list_board($key) 0 ] {{} }]
				debug_message 2 "paramValue :: $key-->$paramValue-> $value"

				if { $paramValue != $value } {
					set global_list_board($key)  "\"$value\""
					#debug_message 2 "Before $key --> $value"
          
          # Do nothing
          if { $value == "None" } {
            return true
          }

          if { $value == "ZC702" || $value == "ZC706" || $value == "ZedBoard" ||
               $value == "ZC702*" || $value == "ZC706*" || $value == "ZedBoard*" } {
               # apply preset for both actual and starred values
               if { $value == "ZC702*"} {
                  set value "ZC702"
               } elseif { $value == "ZC706*"} {
                  set value "ZC706"
               } elseif { $value == "ZedBoard*" } {
                  set value "ZedBoard"
               }
		          send_msg_id PS7-1 INFO "Applying Board Preset $value..." -verbose
          } elseif { [file exists $value] == 1 } {
            if { [file extension $value] == ".xml" } {
		          send_msg_id PS7-1 INFO "Applying Custom Preset $value..." -verbose
              set key "Custom"
            } else {
		          send_msg_id PS7-1 ERROR "Undefined Preset or invalid XML project file" -verbose
              return true
            }
          }  

          set preset_applied false
				  set_property errmsg "" [ ipgui::get_paramspec -name "PCW_IMPORT_BOARD_PRESET" -of $IpView]
					if { [ catch { Ip_zynq_ps7_v1_4_import_preset -context [ zynq_getDeviceString ] -params [list $key $value] } dependent_value_list ] } {
            			set_error_msg $IpView $dependent_value_list 
						return false
					}
          #debug_message 2 "Preset $key --> $dependent_value_list"
		      set_error_msg $IpView $dependent_value_list 
              if { $dependent_value_list != "" } {
                  setvalue $IpView $dependent_value_list
                      set preset_applied true 
                      return true
              }
		      return true
				}
      }
	return true
}

proc PCW_UIPARAM_GENERATE_SUMMARY_updated_nonpcw {IpView} {
	variable validate_update_userparams
	variable dependent_value_list
	set dependent_value_list {}
	variable preset_applied
  global global_list_board 
			if {[info exists global_list_board(PCW_UIPARAM_GENERATE_SUMMARY)]} {
        set key "PCW_UIPARAM_GENERATE_SUMMARY"
				set value [ get_property value [ipgui::get_paramspec -name $key -of $IpView] ]
				set paramValue [string trim [ lindex $global_list_board($key) 0 ] {{} }]
				debug_message 2 "paramValue :: $key-->$paramValue-> $value"

				if { $paramValue != $value } {
					set global_list_board($key)  "\"$value\""
					#debug_message 2 "Before $key --> $value"
          
          # Do nothing
          if { $value == "None" } {
            return true
          }

          set preset_applied false
				  set_property errmsg "" [ ipgui::get_paramspec -name "PCW_UIPARAM_GENERATE_SUMMARY" -of $IpView]
         if { [ catch { Ip_zynq_ps7_v1_4_is_zynq_instance -context [ zynq_getDeviceString ] } ] }  {
                  if { [ catch { Ip_zynq_ps7_v1_4_get_ranges -context [ zynq_getDeviceString ] -userparams [ gettclvalue $IpView] -params [list "PCW_UIPARAM_GENERATE_SUMMARY" $value] } dependent_value_list ] } {
                          #set_error_msg $IPINST $dependent_value_list 
                          #return false
                  }
          } else {

                  if { [ catch { Ip_zynq_ps7_v1_4_is_default_zynq_instance -context [ zynq_getDeviceString ]} set_defaut_value] } {
                    if { [ catch { Ip_zynq_ps7_v1_4_get_range -params [list "PCW_UIPARAM_GENERATE_SUMMARY" $value] -context [ zynq_getDeviceString ]} dependent_value_list ] } {
                    }
                  } else {
                    if { [ catch { Ip_zynq_ps7_v1_4_get_range -params [gettclvalue $IpView] -context [ zynq_getDeviceString ]} dependent_value_list ] } {
                    }
                    set dependent_value_list {}
                    if { [ catch { Ip_zynq_ps7_v1_4_get_range -params [list "PCW_UIPARAM_GENERATE_SUMMARY" $value] -context [ zynq_getDeviceString ]} dependent_value_list ] } {
                    }
                  }
          }        
          #debug_message 2 "Preset $key --> $dependent_value_list"
		      set_error_msg $IpView $dependent_value_list 
              if { $dependent_value_list != "" } {
                  setvalue $IpView $dependent_value_list
                      return true
              }
		      return true
				}
      }
	return true
}

proc PCW_PERIPHERAL_BOARD_PRESET_updated_nonpcw {IpView} {
	variable validate_update_userparams
	variable board_preset_apply 
	variable dependent_value_list
  global global_list 
  if { $board_preset_apply == true} {
	      set value [get_property value [ipgui::get_paramspec -name "PCW_PERIPHERAL_BOARD_PRESET" -of $IpView ] ]
				set paramValue [string trim [ lindex $global_list(PCW_PERIPHERAL_BOARD_PRESET) 0 ] {{} }]
        if { $value != $paramValue } {
          set global_list(PCW_PERIPHERAL_BOARD_PRESET) $value
		      send_msg_id PS7-6 INFO "Configuring Board Preset $value. Please wait ......" -verbose
		      if { [ catch { Ip_zynq_ps7_v1_4_apply_board -params [list "PCW_PERIPHERAL_BOARD_PRESET" $value] -context [ zynq_getDeviceString ]} dependent_value_list ] } {
      	  		set_error_msg $IpView $dependent_value_list 
		    	    return false
      		  }
              if { $dependent_value_list != "" } {
                  set affected_value [ AffectedBoardList $IpView $dependent_value_list]
                      if { $affected_value != "" } {
                          debug_message 2 "Applying preset...$dependent_value_list"
                          set board_preset_apply false
                          setvalue $IpView $dependent_value_list
                          return true
                      }
              }
          }
       }
	return true
}


proc PCW_M_AXI_GP0_ENABLE_STATIC_REMAP_updated_nonpcw {IPINST} {
	set enable_static_remap [ get_property value [ipgui::get_paramspec -name PCW_M_AXI_GP0_ENABLE_STATIC_REMAP -of $IPINST] ]
	if {$enable_static_remap == 1} {
		set_property value 6 [ipgui::get_paramspec -name PCW_M_AXI_GP0_THREAD_ID_WIDTH -of $IPINST]
	} else {
		set_property value 12 [ipgui::get_paramspec -name PCW_M_AXI_GP0_THREAD_ID_WIDTH -of $IPINST]
	}
	return true
}
proc PCW_M_AXI_GP1_ENABLE_STATIC_REMAP_updated_nonpcw {IPINST} {
	set enable_static_remap [ get_property value [ipgui::get_paramspec -name PCW_M_AXI_GP1_ENABLE_STATIC_REMAP -of $IPINST] ]
	if {$enable_static_remap == 1} {
		set_property value 6 [ipgui::get_paramspec -name PCW_M_AXI_GP1_THREAD_ID_WIDTH -of $IPINST]
	} else {
		set_property value 12 [ipgui::get_paramspec -name PCW_M_AXI_GP1_THREAD_ID_WIDTH -of $IPINST]
	}
	return true
}
proc PCW_EN_CLK0_PORT_updated_nonpcw {IPINST} {
	set fclk_enable [ get_property value [ipgui::get_paramspec -name PCW_EN_CLK0_PORT -of $IPINST] ]
	if {$fclk_enable == 1} {
		#set_property value true [ipgui::get_paramspec -name PCW_FCLK_CLK0_BUF -of $IPINST]
		set_property value 1 [ipgui::get_paramspec -name PCW_FPGA_FCLK0_ENABLE -of $IPINST]
	} else {
		#set_property value false [ipgui::get_paramspec -name PCW_FCLK_CLK0_BUF -of $IPINST]
		set_property value 0 [ipgui::get_paramspec -name PCW_FPGA_FCLK0_ENABLE -of $IPINST]
	}
	return true
}
proc PCW_EN_CLK1_PORT_updated_nonpcw {IPINST} {
	set fclk_enable [ get_property value [ipgui::get_paramspec -name PCW_EN_CLK1_PORT -of $IPINST] ]
	if {$fclk_enable == 1} {
		#set_property value true [ipgui::get_paramspec -name PCW_FCLK_CLK1_BUF -of $IPINST]
		set_property value 1 [ipgui::get_paramspec -name PCW_FPGA_FCLK1_ENABLE -of $IPINST]
	} else {
		#set_property value false [ipgui::get_paramspec -name PCW_FCLK_CLK1_BUF -of $IPINST]
		set_property value 0 [ipgui::get_paramspec -name PCW_FPGA_FCLK1_ENABLE -of $IPINST]
	}
	return true
}
proc PCW_EN_CLK2_PORT_updated_nonpcw {IPINST} {
	set fclk_enable [ get_property value [ipgui::get_paramspec -name PCW_EN_CLK2_PORT -of $IPINST] ]
	if {$fclk_enable == 1} {
		#set_property value true [ipgui::get_paramspec -name PCW_FCLK_CLK2_BUF -of $IPINST]
		set_property value 1 [ipgui::get_paramspec -name PCW_FPGA_FCLK2_ENABLE -of $IPINST]
	} else {
		#set_property value false [ipgui::get_paramspec -name PCW_FCLK_CLK2_BUF -of $IPINST]
		set_property value 0 [ipgui::get_paramspec -name PCW_FPGA_FCLK2_ENABLE -of $IPINST]
	}
	return true
}
proc PCW_EN_CLK3_PORT_updated_nonpcw {IPINST} {
	set fclk_enable [ get_property value [ipgui::get_paramspec -name PCW_EN_CLK3_PORT -of $IPINST] ]
	if {$fclk_enable == 1} {
		#set_property value true [ipgui::get_paramspec -name PCW_FCLK_CLK3_BUF -of $IPINST]
		set_property value 1 [ipgui::get_paramspec -name PCW_FPGA_FCLK3_ENABLE -of $IPINST]
	} else {
		#set_property value false [ipgui::get_paramspec -name PCW_FCLK_CLK3_BUF -of $IPINST]
		set_property value 0 [ipgui::get_paramspec -name PCW_FPGA_FCLK3_ENABLE -of $IPINST]
	}
	return true
}
proc PCW_PACKAGE_NAME_updated_nonpcw {IPINST} {
	set package_name [ get_property value [ipgui::get_paramspec -name PCW_PACKAGE_NAME -of $IPINST] ]
	if {$package_name == "clg225"} {
		set_property value 16 [ipgui::get_paramspec -name PCW_DQ_WIDTH -of $IPINST]
		set_property value 2 [ipgui::get_paramspec -name PCW_DQS_WIDTH -of $IPINST]
		set_property value 2 [ipgui::get_paramspec -name PCW_DM_WIDTH -of $IPINST]
		set_property value 32 [ipgui::get_paramspec -name PCW_MIO_PRIMITIVE -of $IPINST]
	} else {
		set_property value 32 [ipgui::get_paramspec -name PCW_DQ_WIDTH -of $IPINST]
		set_property value 4 [ipgui::get_paramspec -name PCW_DQS_WIDTH -of $IPINST]
		set_property value 4 [ipgui::get_paramspec -name PCW_DM_WIDTH -of $IPINST]
		set_property value 54 [ipgui::get_paramspec -name PCW_MIO_PRIMITIVE -of $IPINST]
	}
	return true
}

proc DDRRangeValidation {  IPINST param  } {
  if { ($param == "PCW_UIPARAM_DDR_FREQ_MHZ") ||  ($param == "PCW_UIPARAM_DDR_MEMORY_TYPE") } {
     set ddrType [get_property value [ipgui::get_paramspec -name "PCW_UIPARAM_DDR_MEMORY_TYPE" -of $IPINST] ]
     set ddrFreq [get_property value [ipgui::get_paramspec -name "PCW_UIPARAM_DDR_FREQ_MHZ" -of $IPINST] ]
	 if { [string match "DDR 3*" $ddrType] } { 
	 if {$ddrFreq >= 200 && $ddrFreq < 303 } {
	  ipxit::send_msg "CRITICAL WARNING"  1 "Critical Warning:- DDR3 Lower frequency values below 303MHz are supported for debug purposes. Ideal lowest frequency should be 303MHz." 
    }
	}
  }
}


