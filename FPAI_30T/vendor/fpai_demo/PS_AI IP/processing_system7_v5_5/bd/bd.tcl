###############################################################################
##
## (c) Copyright 2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and 
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
###############################################################################
##
## processing_system7_v5_5/bd/bd.tcl
##
###############################################################################
set i 1

proc init { cellpath otherInfo } {
	set cell [get_bd_cells $cellpath]
	bd::mark_propagate_only $cell {PCW_NUM_F2P_INTR_INPUTS}
	bd::mark_propagate_only $cell {PCW_M_AXI_GP0_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_M_AXI_GP1_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_S_AXI_GP0_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_S_AXI_GP1_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_S_AXI_ACP_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_S_AXI_HP0_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_S_AXI_HP1_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_S_AXI_HP2_FREQMHZ}
	bd::mark_propagate_only $cell {PCW_S_AXI_HP3_FREQMHZ}
}

proc post_config_ip { cellpath otherInfo } {
	set cell [get_bd_cells $cellpath]

    #### Setting the num read/write threads value of interfaces based on user parameters
    if {[get_property CONFIG.PCW_USE_M_AXI_GP0 $cell] == 1} {
      set w0_val [get_property CONFIG.PCW_GP0_NUM_WRITE_THREADS $cell] 
      set r0_val [get_property CONFIG.PCW_GP0_NUM_READ_THREADS $cell] 
      set gp0 [get_bd_intf_pins $cell/M_AXI_GP0]
      set_property CONFIG.NUM_WRITE_THREADS $w0_val $gp0 
      set_property CONFIG.NUM_WRITE_THREADS.VALUE_SRC CONSTANT $gp0 
      set_property CONFIG.NUM_READ_THREADS $r0_val $gp0 
      set_property CONFIG.NUM_READ_THREADS.VALUE_SRC CONSTANT $gp0 
    }
    if {[get_property CONFIG.PCW_USE_M_AXI_GP1 $cell] == 1} {
      set w1_val [get_property CONFIG.PCW_GP1_NUM_WRITE_THREADS $cell] 
      set r1_val [get_property CONFIG.PCW_GP1_NUM_READ_THREADS $cell] 
      set gp1 [get_bd_intf_pins $cell/M_AXI_GP1]
      set_property CONFIG.NUM_WRITE_THREADS $w1_val $gp1 
      set_property CONFIG.NUM_WRITE_THREADS.VALUE_SRC CONSTANT $gp1 
      set_property CONFIG.NUM_READ_THREADS $r1_val $gp1 
      set_property CONFIG.NUM_READ_THREADS.VALUE_SRC CONSTANT $gp1 
    }

	#### Updating M_AXI interface parameter SUPPORTS_NARROW_BURST
	foreach mgp_intf {M_AXI_GP0 M_AXI_GP1} {
		if {[get_property CONFIG.PCW_USE_${mgp_intf} $cell] == 1} {
			set_property CONFIG.SUPPORTS_NARROW_BURST [get_property CONFIG.PCW_${mgp_intf}_SUPPORT_NARROW_BURST $cell] [get_bd_intf_pins ${cell}/${mgp_intf}]
		}
	}
	
	#### Updating FCLK interface parameter FREQ_HZ
	if {([get_property CONFIG.PCW_USE_CR_FABRIC $cell] == 1)} {
		foreach fclk_intf {FCLK_CLK0 FCLK_CLK1 FCLK_CLK2 FCLK_CLK3} {
			if {([get_property CONFIG.PCW_EN_[string map {FCLK_ ""} $fclk_intf]_PORT $cell] == 1)} {
				set_property CONFIG.FREQ_HZ [get_property CONFIG.PCW_[string map {FCLK_ ""} $fclk_intf]_FREQ $cell] [get_bd_pins ${cell}/${fclk_intf}]
			}
		}
	}
}

proc pre_propagate { cellpath otherInfo } {
	set cell [get_bd_cells $cellpath]

	######### DRC checks #########
	#### DRC check for M_AXI_GP0 and M_AXI_GP1 address ranges ####
	set data_space [get_bd_addr_spaces -of_objects $cell -filter "path == $cell/Data"]
	set addr_segments [get_bd_addr_segs -of_objects $data_space]
	foreach addr_segment $addr_segments {

		set segment_intf [get_bd_intf_pins -of_objects $addr_segment]
		set base_addr [get_property offset $addr_segment]
		set range [format 0x%x [get_property range $addr_segment]]
		set high_addr [format 0x%x [expr $base_addr + $range - 0x01]]
		if {[expr [lsearch $segment_intf $cell/M_AXI_GP0] > -1] && [expr [lsearch $segment_intf $cell/M_AXI_GP1] > -1]} {
			if {!(([expr $base_addr < 0x80000000] && [expr $base_addr > 0x3fffffff] && [expr $high_addr < 0x80000000] && [expr $high_addr > 0x3fffffff]) || ([expr $base_addr < 0xc0000000] && [expr $base_addr > 0x7fffffff] && [expr $high_addr < 0xc0000000] && [expr $high_addr > 0x7fffffff]))} {
				debug::send_message -severity "CRITICAL WARNING" -msg "Address segment $addr_segment with base address : $base_addr and high address : $high_addr is out of range for M_AXI_GP0 & M_AXI_GP1. Valid range for M_AXI_GP0 is 0x40000000 - 0x7fffffff. Valid range for M_AXI_GP1 is 0x80000000 - 0xbfffffff"
			}
		}
		if {[expr [lsearch $segment_intf $cell/M_AXI_GP0] > -1] && [expr [lsearch $segment_intf $cell/M_AXI_GP1] == -1]} {
			if {[expr $base_addr > 0x7fffffff] || [expr $base_addr < 0x40000000] || [expr $high_addr > 0x7fffffff] || [expr $high_addr < 0x40000000]} {
       				debug::send_message -severity "CRITICAL WARNING" -msg "Address segment $addr_segment with base address : $base_addr and high address : $high_addr is out of range for M_AXI_GP0. Valid range for M_AXI_GP0 is 0x40000000 - 0x7fffffff"
			}
		}
		if {[expr [lsearch $segment_intf $cell/M_AXI_GP0] == -1] && [expr [lsearch $segment_intf $cell/M_AXI_GP1] > -1]} {		
			if {[expr $base_addr > 0xbfffffff] || [expr $base_addr < 0x80000000] || [expr $high_addr > 0xbfffffff] || [expr $high_addr < 0x80000000]} {
				debug::send_message -severity "CRITICAL WARNING" -msg "Address segment $addr_segment with base address : $base_addr and high address : $high_addr is out of range for M_AXI_GP1. Valid range for M_AXI_GP1 is 0x80000000 - 0xbfffffff"
			}
		}
	}
}

proc propagate { cellpath otherInfo } {
########################################	
}

proc post_propagate { cellpath otherInfo } {
	set cell [get_bd_cells $cellpath]

	#### Modifying Port Width & SENSITIVITY of IRQ_F2P ####
	set intf [get_bd_pins $cellpath/IRQ_F2P]
	if {$intf != ""} {
		set port_width [get_property CONFIG.PortWidth $intf]
		if {$port_width != ""} {
			#### Update Port Width on IP ####
			set_property CONFIG.PCW_NUM_F2P_INTR_INPUTS $port_width $cell
			#### Update Sensitivity	on Interface ####
			set sensitivity [split [get_property CONFIG.SENSITIVITY $intf] ":"]
			set updated_sensitivity [list]
			foreach element $sensitivity {
				if {$element != "LEVEL_HIGH" && $element != "EDGE_RISING" && $element != "NULL"} {
					set element "LEVEL_HIGH"
					debug::send_message -severity "CRITICAL WARNING" -msg "Supported SENSITIVITY list for IRQ_F2P is LEVEL_HIGH and EDGE_RISING"
					#puts "Supported SENSITIVITY list for IRQ_F2P is LEVEL_HIGH and EDGE_RISING \n"
				}
				lappend updated_sensitivity $element				
			}
			set_property CONFIG.SENSITIVITY [join $updated_sensitivity ":"] $intf
		}	
	}

	#### Modifying SENSITIVITY of Core<0,1>_n<FIQ,IRQ> Interface####
	foreach intr {Core0_nFIQ Core0_nIRQ Core1_nFIQ Core1_nIRQ} { 
		set intf [get_bd_pins $cellpath/$intr]
		if {$intf != ""} {
			set sensitivity [get_property CONFIG.SENSITIVITY $intf]
			if {$sensitivity != "LEVEL_HIGH" && $sensitivity != "EDGE_RISING" & $sensitivity != "NULL"} {
				set sensitivity "LEVEL_HIGH" 	
			}
			set_property CONFIG.SENSITIVITY $sensitivity $intf
		}	
	}
	
	#### Adding AXI interface frequency to IP parameters
 	foreach axi_intf {M_AXI_GP0 M_AXI_GP1 S_AXI_GP0 S_AXI_GP1 S_AXI_ACP S_AXI_HP0 S_AXI_HP1 S_AXI_HP2 S_AXI_HP3} {
		if {[get_property CONFIG.PCW_USE_${axi_intf} $cell] == 1} {
			set_property CONFIG.PCW_${axi_intf}_FREQMHZ [expr [get_property CONFIG.FREQ_HZ [get_bd_intf_pins ${cell}/${axi_intf}]]/1000000] $cell
		}
	}

#### Adding warning message for SPI (EMIO) and SSIN pin is left float or tied LOW CR#869488 /processing_system7_0/SPI1_SS_I   /processing_system7_0/SPI0_SS_I
           foreach spi_intf {SPI_0 SPI_1} {
			       set spi_ssin_intf [get_bd_intf_pins -of_objects ${cell} -filter "path == $cell/$spi_intf"]
                     if {$spi_ssin_intf == "$cell/$spi_intf"} {
				       debug::send_message -severity "WARNING" -msg "When using EMIO pins for $spi_intf tie SSIN High in the PL bitstream"
	                 }	
           }
	
        #### Warning message for BFM License ####
	##::bd::send_msg –of $cell -type warning -msg_id 1 -text  "The Zynq BFM requires an AXI BFM license to run. Please ensure that you have purchased and setup the AXI BFM license prior to running simulation with this block. Please contact your Xilinx sales office for more information on purchasing this license." 
}
