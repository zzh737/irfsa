namespace eval processing_system7_v5_5_utils {

proc warning_for_upgrade_from_processing_system7_v5_4 {} {      
 
	return [ warning_string ] 

}
proc warning_for_upgrade_from_processing_system7_v5_3 {} {      
 
	return [ warning_string ] 

}
proc warning_for_upgrade_from_processing_system7_v5_2 {} {      
 
	return [ warning_string ] 

}
proc warning_string {} {
	set warningString "1. The custom time stamp unit(PTP) signals will be exposed to the Programmable Logic(PL),  \n \
         even when the Ethernet is routed through the MIO. For more details \n, \
		 please refer Zynq Technical Reference Manual (UG 585) CH No. 16.4 IEEE 1588 Time Stamping. \n\
		 This change enables additional optional functionality for designs with Ethernet on MIO. \n\
		 No changes are required for existing designs. \n \
		 2. Updated the JTAG interface from master to slave mode. Based on Zynq Technical Reference Manual, \n \
		 PS boot mode supports 4 master boot mode and 2 Slave JTAG Boot mode. Prior versions of Zynq PS7 \n \
		 IP had PL JTAG in master mode incorrectly. The JTAG port TDO will have a buffer (OBUFT) \n \ 
		 instantiated as part of the Processing System7 IP. This change only affects designs which use PL JTAG \n \
		 through EMIO interface. For More details, refer chapter no.6 of Zynq Technical Reference Manual \n \
		 (UG 585) - Boot and Configuration. \n"
		 
	return $warningString
}

proc upgrade_param_processing_system7_v5_5 {xciValues} { 
		upvar 2 $xciValues valueArray
        set board_delay0 [getParameter PCW_UIPARAM_DDR_BOARD_DELAY0 valueArray]
       if { $board_delay0 <= 0.0 } {
            setParameter PCW_UIPARAM_DDR_BOARD_DELAY0 0.25 valueArray
        }
        set board_delay1 [getParameter PCW_UIPARAM_DDR_BOARD_DELAY1 valueArray]
        if { $board_delay1 <= 0.0 } {
            setParameter PCW_UIPARAM_DDR_BOARD_DELAY1 0.25 valueArray
        }
        set board_delay2 [getParameter PCW_UIPARAM_DDR_BOARD_DELAY2 valueArray]
        if { $board_delay2 <= 0.0 } {
            setParameter PCW_UIPARAM_DDR_BOARD_DELAY2 0.25 valueArray
        }
        set board_delay3 [getParameter PCW_UIPARAM_DDR_BOARD_DELAY3 valueArray]
        if { $board_delay3 <= 0.0 } {
            setParameter PCW_UIPARAM_DDR_BOARD_DELAY3 0.25 valueArray
        }
}

proc add_param_for_processing_system7_v5_5 {xciValues} { 
		upvar 2 $xciValues valueArray
	 
	 #####CR #789801 : Trace Data Width######
	 addParameter PCW_TRACE_INTERNAL_WIDTH 32 valueArray
	 addParameter PCW_USE_AXI_NONSECURE 0 valueArray
	 addParameter PCW_EN_PTP_ENET0 1 valueArray
	 addParameter PCW_EN_PTP_ENET0 1 valueArray
    ####Number of thread
        addParameter PCW_GP0_NUM_WRITE_THREADS 4 valueArray
        addParameter PCW_GP0_NUM_READ_THREADS 4 valueArray
        addParameter PCW_GP1_NUM_WRITE_THREADS 4 valueArray
        addParameter PCW_GP1_NUM_READ_THREADS 4 valueArray
        addParameter PCW_GP0_EN_MODIFIABLE_TXN 0 valueArray
        addParameter PCW_GP1_EN_MODIFIABLE_TXN 0 valueArray
    }

	proc upgrade_from_processing_system7_v5_5 {xciValues} { 
		namespace import ::xcoUpgradeLib::*
		upvar $xciValues valueArray
		
		 add_param_for_processing_system7_v5_5 $xciValues
		 upgrade_param_processing_system7_v5_5 $xciValues

 		namespace forget ::xcoUpgradeLib::*
	} 
	
	proc upgrade_from_processing_system7_v5_4 {xciValues} { 
		namespace import ::xcoUpgradeLib::*
		upvar $xciValues valueArray
		
		 add_param_for_processing_system7_v5_5 $xciValues
		 upgrade_param_processing_system7_v5_5 $xciValues

 		namespace forget ::xcoUpgradeLib::*
	} 
	proc upgrade_from_processing_system7_v5_3 {xciValues} { 
		namespace import ::xcoUpgradeLib::*
		upvar $xciValues valueArray
		
		#### add 5.3 parameter upgrades here ####
              
     add_param_for_processing_system7_v5_5 $xciValues
		 upgrade_param_processing_system7_v5_5 $xciValues

                #########################################


 		namespace forget ::xcoUpgradeLib::*
	}

  proc upgrade_from_processing_system7_v5_2 {xciValues} { 
		namespace import ::xcoUpgradeLib::*
		upvar $xciValues valueArray
        addParameter preset None valueArray
    add_param_for_processing_system7_v5_5 $xciValues
    upgrade_param_processing_system7_v5_5 $xciValues
		
		#### add 5.2 parameter upgrades here ####
              
                #########################################


 		namespace forget ::xcoUpgradeLib::*
	}
proc upgrade_from_processing_system7_v5_01 {xciValues} { 
		namespace import ::xcoUpgradeLib::*
		upvar $xciValues valueArray
		setParameter PCW_IMPORT_BOARD_PRESET None valueArray
        addParameter preset None valueArray

		set old_param [getParameter PCW_MIO_TREE_PERIPHERALS valueArray]
		set new_param [string map {$ \#} $old_param]
		setParameter PCW_MIO_TREE_PERIPHERALS $new_param valueArray

		set old_param2 [getParameter PCW_MIO_TREE_SIGNALS valueArray]
		set new_param2 [string map {$ \#} $old_param2]
		setParameter PCW_MIO_TREE_SIGNALS $new_param2 valueArray

		addParameter PCW_M_AXI_GP0_FREQMHZ 10 valueArray
		addParameter PCW_M_AXI_GP1_FREQMHZ 10 valueArray
		addParameter PCW_S_AXI_GP0_FREQMHZ 10 valueArray
		addParameter PCW_S_AXI_GP1_FREQMHZ 10 valueArray
		addParameter PCW_S_AXI_HP0_FREQMHZ 10 valueArray
		addParameter PCW_S_AXI_HP1_FREQMHZ 10 valueArray
		addParameter PCW_S_AXI_HP2_FREQMHZ 10 valueArray
		addParameter PCW_S_AXI_HP3_FREQMHZ 10 valueArray
		addParameter PCW_S_AXI_ACP_FREQMHZ 10 valueArray
		addParameter PCW_QSPI_INTERNAL_HIGHADDRESS 0xFCFFFFFF valueArray
		addParameter PCW_USE_DAP_ROM 0 valueArray
		addParameter PCW_USE_EXPANDED_PS_SLCR_REGISTERS 0 valueArray
		addParameter PCW_USE_PS_SLCR_REGISTERS 0 valueArray

		set baud_rate [getParameter PCW_UART_BAUD_RATE valueArray]
		addParameter PCW_UART0_BAUD_RATE $baud_rate valueArray
		addParameter PCW_UART1_BAUD_RATE $baud_rate valueArray
		

		if {[getParameter PCW_QSPI_GRP_IO1_ENABLE valueArray] == 1} {
			setParameter PCW_QSPI_GRP_SS1_ENABLE 0 valueArray
		}

		addParameter PCW_QSPI_GRP_SINGLE_SS_ENABLE NA valueArray
		addParameter PCW_QSPI_GRP_SINGLE_SS_IO NA valueArray

    add_param_for_processing_system7_v5_5 $xciValues
    upgrade_param_processing_system7_v5_5 $xciValues

		removeParameter PCW_UART_BAUD_RATE valueArray
		
 		namespace forget ::xcoUpgradeLib::*
	}
} 
