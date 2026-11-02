

proc getPresetInfo  {} {
	return [dict create  name Default  display_name  {Default}   description  {Default preset}  vlnv  xilinx.com:ip:processing_system7:5.5]
} 


proc validate_preset {IPINST} {
    return true;
}

proc apply_preset {IPINST} {
  return [dict create]
}


