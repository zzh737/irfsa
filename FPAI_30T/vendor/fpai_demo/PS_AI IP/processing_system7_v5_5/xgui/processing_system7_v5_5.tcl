#Definitional proc to organize widgets for parameters.

load librdi_iptasks[info sharedlibextension]
source_ipfile "xgui/validate_update.tcl"

proc init_gui { IPINST } {
	if { [ info exists ::env(ZYNQ_CUSTOM_GUI) ] } {
		set en $::env(ZYNQ_CUSTOM_GUI)
	} else {
		set en 1
	}
	if { $en == 1} {
		set ZynqCustWid [ ipgui::add_custom_widget $IPINST -parent $IPINST -name "PS7 Configuration" -class_name ZynqPanel]
		ipgui::add_param $IPINST -name PCW_DDR_RAM_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_RAM_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SDIO0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SDIO0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SDIO1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SDIO1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC0_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC0_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC1_BASEADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC1_HIGHADDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK_CLK0_BUF -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK_CLK1_BUF -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK_CLK2_BUF -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK_CLK3_BUF -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_FREQ_MHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BANK_ADDR_COUNT -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ROW_ADDR_COUNT -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_COL_ADDR_COUNT -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CL -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CWL -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RCD -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RP -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RAS_MIN -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_FAW -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_AL -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY2 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY3 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_0_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_1_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_2_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_3_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_0_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_1_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_2_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_3_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY2 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY3 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CPU_CPU_6X4X_MAX_RANGE -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CRYSTAL_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_APU_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_USB0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_USB1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CAN0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CAN1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_I2C_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PCAP_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TPIU_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FPGA0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FPGA1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FPGA2_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FPGA3_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_APU_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UIPARAM_ACT_DDR_FREQ_MHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_DCI_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_QSPI_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_SMC_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_ENET0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ACT_ENET1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ACT_USB0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_USB1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_SDIO_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_UART_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_SPI_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_CAN_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_CAN0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_CAN1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_I2C_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_WDT_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TTC_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_PCAP_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TPIU_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CLK0_FREQ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CLK1_FREQ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CLK2_FREQ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CLK3_FREQ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_OVERRIDE_BASIC_CLOCK -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CPU_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_DDR_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK0_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK1_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK2_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK3_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK0_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK1_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK2_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_FCLK3_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TPIU_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_DIVISOR1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PCAP_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_DIVISOR0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_ARMPLL_CTRL_FBDIV -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_IOPLL_CTRL_FBDIV -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_DDRPLL_CTRL_FBDIV -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_CPU_CPU_PLL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_IO_IO_PLL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_DDR_DDR_PLL_FREQMHZ -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_VALID -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_VALID -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_VALID -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_VALID -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_VALID -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_CAN0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_CAN1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_ENET0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_ENET1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_PTP_ENET0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_PTP_ENET1 -parent $ZynqCustWid -widget comboBox

		set PCW_EN_EMIO_GPIO [ipgui::add_param $IPINST -name PCW_EN_EMIO_GPIO -parent $ZynqCustWid -widget comboBox]
		set_property locked true $PCW_EN_EMIO_GPIO

		ipgui::add_param $IPINST -name PCW_EN_EMIO_I2C0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_I2C1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_PJTAG -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_SDIO0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_CD_SDIO0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_WP_SDIO0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_SDIO1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_CD_SDIO1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_WP_SDIO1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_SPI0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_SPI1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_UART0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_UART1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_MODEM_UART0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_MODEM_UART1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_TTC0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_TTC1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_WDT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_TRACE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_AXI_NONSECURE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_M_AXI_GP0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_M_AXI_GP1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_S_AXI_GP0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_S_AXI_GP1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_S_AXI_ACP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP2 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP3 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_GP0_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_GP1_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP0_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP1_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP2_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP3_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_DMA0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_DMA1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_DMA2 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_DMA3 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_TRACE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_PIPELINE_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_INCLUDE_TRACE_BUFFER -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_BUFFER_FIFO_SIZE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_TRACE_DATA_EDGE_DETECTOR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_BUFFER_CLOCK_DELAY -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_CROSS_TRIGGER -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN2 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN3 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT2 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT3 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_DEBUG -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_CR_FABRIC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_AXI_FABRIC_IDLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_DDR_BYPASS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_FABRIC_INTERRUPT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_PROC_EVENT_BUS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_EXPANDED_IOP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_HIGH_OCM -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_PS_SLCR_REGISTERS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_EXPANDED_PS_SLCR_REGISTERS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_CORESIGHT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_EMIO_SRAM_INT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_EMIO_GPIO_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GP0_NUM_WRITE_THREADS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GP0_NUM_READ_THREADS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GP1_NUM_WRITE_THREADS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GP1_NUM_READ_THREADS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART0_BAUD_RATE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART1_BAUD_RATE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_4K_TIMER -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_ENABLE_STATIC_REMAP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_SUPPORT_NARROW_BURST -parent $ZynqCustWid -widget comboBox

		set PCW_M_AXI_GP0_THREAD_ID_WIDTH [ipgui::add_param $IPINST -name PCW_M_AXI_GP0_THREAD_ID_WIDTH -parent $ZynqCustWid -widget comboBox]
		set_property locked true $PCW_M_AXI_GP0_THREAD_ID_WIDTH

		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_ENABLE_STATIC_REMAP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_SUPPORT_NARROW_BURST -parent $ZynqCustWid -widget comboBox

		set PCW_M_AXI_GP1_THREAD_ID_WIDTH [ipgui::add_param $IPINST -name PCW_M_AXI_GP1_THREAD_ID_WIDTH -parent $ZynqCustWid -widget comboBox]
		set_property locked true $PCW_M_AXI_GP1_THREAD_ID_WIDTH

		ipgui::add_param $IPINST -name PCW_S_AXI_GP0_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_GP1_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_INCLUDE_ACP_TRANS_CHECK -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USE_DEFAULT_ACP_USER_VAL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_ARUSER_VAL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_AWUSER_VAL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP0_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP0_DATA_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP1_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP1_DATA_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP2_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP2_DATA_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP3_ID_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_S_AXI_HP3_DATA_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NUM_F2P_INTR_INPUTS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_DDR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_SMC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_QSPI -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CAN0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CAN1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_ENET0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_ENET1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_GPIO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_I2C0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_I2C1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_PJTAG -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_SDIO0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_SDIO1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_SPI0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_SPI1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_UART0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_UART1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_MODEM_UART0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_MODEM_UART1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_TTC0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_TTC1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_WDT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_TRACE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_USB0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_USB1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DQ_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DQS_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DM_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_PRIMITIVE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLK0_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLK1_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLK2_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLK3_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_RST0_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_RST1_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_RST2_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_RST3_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG0_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG1_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG2_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG3_PORT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC_ABORT_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC2_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC3_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC4_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC5_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC6_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_DMAC7_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_SMC_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_QSPI_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_CTI_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_GPIO_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_USB0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_ENET0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_SDIO0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_I2C0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_SPI0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_UART0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_CAN0_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_USB1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_ENET1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_SDIO1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_I2C1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_SPI1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_UART1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_P2F_CAN1_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_IRQ_F2P_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_IRQ_F2P_MODE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CORE0_FIQ_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CORE0_IRQ_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CORE1_FIQ_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CORE1_IRQ_INTR -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_VALUE_SILVERSION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GP0_EN_MODIFIABLE_TXN -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GP1_EN_MODIFIABLE_TXN -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_IMPORT_BOARD_PRESET -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PERIPHERAL_BOARD_PRESET  -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PRESET_BANK0_VOLTAGE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_PRESET_BANK1_VOLTAGE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ADV_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_MEMORY_TYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ECC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BUS_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_HIGH_TEMP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_PARTNO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DRAM_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DEVICE_CAPACITY -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_SPEED_BIN -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_TRAIN_READ_GATE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_TRAIN_DATA_EYE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_STOP_EN -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_USE_INTERNAL_VREF -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_2 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_3 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_0 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_1 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_2 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_3 -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PORT0_HPR_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PORT1_HPR_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PORT2_HPR_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PORT3_HPR_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_HPRLPR_QUEUE_PARTITION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NAND_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NAND_NAND_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NAND_GRP_D8_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NAND_GRP_D8_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_NOR_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_A25_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_A25_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS0_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS0_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS1_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS1_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_INT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_INT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_QSPI_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SINGLE_SS_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SINGLE_SS_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SS1_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SS1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SINGLE_QSPI_DATA_MODE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DUAL_STACK_QSPI_DATA_MODE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DUAL_PARALLEL_QSPI_DATA_MODE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_IO1_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_IO1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_FBCLK_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_GRP_FBCLK_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_INTERNAL_HIGHADDRESS -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_ENET0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_GRP_MDIO_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_GRP_MDIO_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET_RESET_SELECT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_RESET_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_ENET1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_GRP_MDIO_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_GRP_MDIO_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_RESET_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_SD0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_GRP_CD_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_GRP_CD_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_GRP_WP_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_GRP_WP_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_GRP_POW_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD0_GRP_POW_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_SD1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_GRP_CD_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_GRP_CD_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_GRP_WP_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_GRP_WP_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_GRP_POW_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SD1_GRP_POW_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART0_UART0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART0_GRP_FULL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART0_GRP_FULL_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART1_UART1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART1_GRP_FULL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART1_GRP_FULL_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_SPI0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS0_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS1_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS2_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS2_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_SPI1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS0_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS1_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS2_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS2_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN0_CAN0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN0_GRP_CLK_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN0_GRP_CLK_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN1_CAN1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN1_GRP_CLK_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN1_GRP_CLK_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_TRACE_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_2BIT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_2BIT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_4BIT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_4BIT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_8BIT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_8BIT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_16BIT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_16BIT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_32BIT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_GRP_32BIT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TRACE_INTERNAL_WIDTH -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_WDT_WDT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC0_TTC0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC1_TTC1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_PJTAG_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_PJTAG_PJTAG_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB0_USB0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB_RESET_SELECT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB0_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB0_RESET_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB1_USB1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB1_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB1_RESET_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_I2C0_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_GRP_INT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_GRP_INT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C0_RESET_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_I2C1_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_GRP_INT_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_GRP_INT_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C_RESET_SELECT -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_RESET_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C1_RESET_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_PERIPHERAL_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_MIO_GPIO_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_MIO_GPIO_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_EMIO_GPIO_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_GPIO_EMIO_GPIO_IO -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_APU_CLK_RATIO_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_FREQMHZ -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CPU_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DDR_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK0_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK1_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK2_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FCLK3_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN0_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_CAN1_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TPIU_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC0_CLK0_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC0_CLK1_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC0_CLK2_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC1_CLK0_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC1_CLK1_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_TTC1_CLK2_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_PCAP_PERIPHERAL_CLKSRC -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_USB_RESET_POLARITY -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_ENET_RESET_POLARITY -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_I2C_RESET_POLARITY -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_0_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_0_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_0_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_0_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_1_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_1_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_1_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_1_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_2_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_2_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_2_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_2_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_3_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_3_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_3_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_3_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_4_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_4_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_4_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_4_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_5_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_5_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_5_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_5_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_6_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_6_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_6_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_6_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_7_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_7_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_7_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_7_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_8_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_8_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_8_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_8_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_9_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_9_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_9_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_9_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_10_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_10_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_10_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_10_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_11_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_11_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_11_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_11_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_12_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_12_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_12_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_12_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_13_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_13_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_13_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_13_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_14_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_14_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_14_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_14_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_15_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_15_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_15_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_15_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_16_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_16_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_16_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_16_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_17_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_17_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_17_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_17_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_18_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_18_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_18_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_18_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_19_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_19_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_19_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_19_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_20_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_20_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_20_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_20_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_21_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_21_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_21_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_21_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_22_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_22_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_22_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_22_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_23_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_23_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_23_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_23_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_24_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_24_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_24_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_24_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_25_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_25_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_25_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_25_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_26_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_26_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_26_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_26_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_27_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_27_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_27_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_27_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_28_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_28_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_28_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_28_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_29_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_29_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_29_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_29_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_30_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_30_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_30_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_30_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_31_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_31_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_31_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_31_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_32_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_32_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_32_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_32_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_33_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_33_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_33_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_33_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_34_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_34_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_34_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_34_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_35_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_35_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_35_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_35_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_36_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_36_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_36_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_36_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_37_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_37_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_37_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_37_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_38_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_38_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_38_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_38_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_39_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_39_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_39_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_39_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_40_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_40_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_40_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_40_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_41_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_41_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_41_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_41_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_42_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_42_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_42_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_42_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_43_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_43_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_43_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_43_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_44_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_44_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_44_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_44_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_45_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_45_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_45_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_45_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_46_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_46_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_46_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_46_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_47_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_47_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_47_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_47_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_48_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_48_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_48_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_48_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_49_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_49_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_49_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_49_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_50_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_50_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_50_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_50_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_51_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_51_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_51_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_51_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_52_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_52_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_52_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_52_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_53_PULLUP -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_53_IOTYPE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_53_DIRECTION -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_MIO_53_SLEW -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name preset -parent $ZynqCustWid -widget presetComboBox

		ipgui::add_param $IPINST -name PCW_UIPARAM_GENERATE_SUMMARY -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_MIO_TREE_PERIPHERALS -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_MIO_TREE_SIGNALS -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PS7_SI_REV -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FPGA_FCLK0_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FPGA_FCLK1_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FPGA_FCLK2_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_FPGA_FCLK3_ENABLE -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_TR -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_PC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_WP -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_CEOE -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_WC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_RC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_WE_TIME -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_TR -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_PC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_WP -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_CEOE -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_WC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_RC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_WE_TIME -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_TR -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_PC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_WP -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_CEOE -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_WC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_RC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS0_WE_TIME -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_TR -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_PC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_WP -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_CEOE -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_WC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_RC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NOR_CS1_WE_TIME -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_RR -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_AR -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_CLR -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_WP -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_REA -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_WC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_RC -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T0 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T1 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T2 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T3 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T4 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T5 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T6 -parent $ZynqCustWid -widget textEdit

		ipgui::add_param $IPINST -name PCW_PACKAGE_NAME -parent $ZynqCustWid -widget comboBox

		ipgui::add_param $IPINST -name PCW_PLL_BYPASSMODE_ENABLE -parent $ZynqCustWid -widget comboBox

		set_property show_ipsymbol false [ipgui::get_canvasspec -of $IPINST]
		set canvas_spec [ipgui::get_canvasspec -of $IPINST]
		set_property ip_logo "data/zynqconfig/guidata/zynq_100x30.png" $canvas_spec
	} else {
		set ddr_page [ ipgui::add_page $IPINST  -name "ddr" -layout vertical]
		set_property display_name "ddr" $ddr_page
		set clock_page [ ipgui::add_page $IPINST  -name "clock" -layout vertical]
		set_property display_name "clock" $clock_page
		set mio_page [ ipgui::add_page $IPINST  -name "mio" -layout vertical]
		set_property display_name "mio" $mio_page
		set misc_page [ ipgui::add_page $IPINST  -name "Voltage/IO/Pullup" -layout vertical]
		set_property display_name "Voltage/IO/Pullup" $misc_page
		set smc_page [ ipgui::add_page $IPINST  -name "smc timings" -layout vertical]
		set_property display_name "smc timings" $smc_page
		set general_page [ ipgui::add_page $IPINST  -name "general" -layout vertical]
		set_property display_name "general" $general_page
		set tempPanel [ipgui::add_panel $IPINST -name tempPanel -parent $IPINST -layout horizontal]

		ipgui::add_param $IPINST -name PCW_DDR_RAM_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_DDR_RAM_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_UART0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_UART0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_UART1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_UART1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_I2C0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_I2C0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_I2C1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_I2C1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SPI0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SPI0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SPI1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SPI1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CAN0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CAN0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CAN1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CAN1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GPIO_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GPIO_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_ENET0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_ENET0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_ENET1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_ENET1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SDIO0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SDIO0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SDIO1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_SDIO1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USB0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USB0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USB1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USB1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_TTC0_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_TTC0_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_TTC1_BASEADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_TTC1_HIGHADDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FCLK_CLK0_BUF -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FCLK_CLK1_BUF -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FCLK_CLK2_BUF -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FCLK_CLK3_BUF -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_FREQ_MHZ -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BANK_ADDR_COUNT -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ROW_ADDR_COUNT -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_COL_ADDR_COUNT -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CL -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CWL -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RCD -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RP -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RC -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_RAS_MIN -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_T_FAW -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_AL -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY0 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY1 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY2 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BOARD_DELAY3 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_0_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_1_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_2_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_3_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_0_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_1_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_2_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_3_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_0_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_1_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_2_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_3_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_0_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_1_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_2_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_3_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_0_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_1_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_2_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_3_PACKAGE_LENGTH -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_0_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_1_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_2_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQS_3_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_0_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_1_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_2_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DQ_3_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_0_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_1_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_2_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_3_PROPOGATION_DELAY -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_0 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_1 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_2 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_DQS_TO_CLK_DELAY_3 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY0 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY1 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY2 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_DDR_BOARD_DELAY3 -parent $ddr_page -widget textEdit 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_CPU_CPU_6X4X_MAX_RANGE -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CRYSTAL_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_APU_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_USB0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_USB1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_I2C_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK2_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK2_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_PCAP_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TPIU_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FPGA0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FPGA1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FPGA2_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FPGA3_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_APU_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_ACT_DDR_FREQ_MHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_DCI_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_QSPI_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_SMC_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_ENET0_PERIPHERAL_FREQMHZ -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_ENET1_PERIPHERAL_FREQMHZ -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_USB0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_USB1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_SDIO_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_UART_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_SPI_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_CAN_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_CAN0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_CAN1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_I2C_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_WDT_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TTC_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_PCAP_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TPIU_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CLK0_FREQ -parent $general_page -widget textEdit 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CLK1_FREQ -parent $general_page -widget textEdit 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CLK2_FREQ -parent $general_page -widget textEdit 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CLK3_FREQ -parent $general_page -widget textEdit 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_OVERRIDE_BASIC_CLOCK -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CPU_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DDR_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK0_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK1_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK2_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK3_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK0_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK1_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK2_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK3_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TPIU_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_DIVISOR1 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_PCAP_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK0_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK1_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK2_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK0_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK1_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK2_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_DIVISOR0 -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ARMPLL_CTRL_FBDIV -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_IOPLL_CTRL_FBDIV -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DDRPLL_CTRL_FBDIV -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CPU_CPU_PLL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_IO_IO_PLL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DDR_DDR_PLL_FREQMHZ -parent $clock_page -widget textEdit 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_VALID -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_VALID -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_VALID -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_VALID -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_VALID -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_CAN0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_CAN1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_ENET0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_ENET1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_PTP_ENET0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_PTP_ENET1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_GPIO -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_I2C0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_I2C1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_PJTAG -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_SDIO0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_CD_SDIO0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_WP_SDIO0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_SDIO1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_CD_SDIO1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_WP_SDIO1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_SPI0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_SPI1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_UART0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_UART1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_MODEM_UART0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_MODEM_UART1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_TTC0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_TTC1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_WDT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_TRACE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_AXI_NONSECURE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_M_AXI_GP0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_M_AXI_GP1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_S_AXI_GP0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_S_AXI_GP1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_S_AXI_ACP -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP2 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_S_AXI_HP3 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_GP0_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_GP1_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP0_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP1_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP2_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP3_FREQMHZ -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_DMA0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_DMA1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_DMA2 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_DMA3 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_TRACE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_TRACE_PIPELINE_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_INCLUDE_TRACE_BUFFER -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_TRACE_BUFFER_FIFO_SIZE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_TRACE_DATA_EDGE_DETECTOR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_TRACE_BUFFER_CLOCK_DELAY -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_CROSS_TRIGGER -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN2 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_IN3 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT2 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FTM_CTI_OUT3 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_DEBUG -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_CR_FABRIC -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_AXI_FABRIC_IDLE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_DDR_BYPASS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_FABRIC_INTERRUPT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_PROC_EVENT_BUS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_EXPANDED_IOP -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_HIGH_OCM -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_PS_SLCR_REGISTERS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_EXPANDED_PS_SLCR_REGISTERS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_CORESIGHT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_EMIO_SRAM_INT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GPIO_EMIO_GPIO_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GP0_NUM_WRITE_THREADS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GP0_NUM_READ_THREADS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GP1_NUM_WRITE_THREADS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GP1_NUM_READ_THREADS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_UART0_BAUD_RATE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_UART1_BAUD_RATE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_4K_TIMER -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_ENABLE_STATIC_REMAP -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP0_SUPPORT_NARROW_BURST -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		set PCW_M_AXI_GP0_THREAD_ID_WIDTH [ipgui::add_param $IPINST -name PCW_M_AXI_GP0_THREAD_ID_WIDTH -parent $general_page -widget comboBox]
		set_property locked true $PCW_M_AXI_GP0_THREAD_ID_WIDTH
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_ENABLE_STATIC_REMAP -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_M_AXI_GP1_SUPPORT_NARROW_BURST -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		set PCW_M_AXI_GP1_THREAD_ID_WIDTH [ipgui::add_param $IPINST -name PCW_M_AXI_GP1_THREAD_ID_WIDTH -parent $general_page -widget comboBox]
		set_property locked true $PCW_M_AXI_GP1_THREAD_ID_WIDTH
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_GP0_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_GP1_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_INCLUDE_ACP_TRANS_CHECK -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_USE_DEFAULT_ACP_USER_VAL -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_ARUSER_VAL -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_ACP_AWUSER_VAL -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP0_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP0_DATA_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP1_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP1_DATA_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP2_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP2_DATA_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP3_ID_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_S_AXI_HP3_DATA_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_NUM_F2P_INTR_INPUTS -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_DDR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_SMC -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_QSPI -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CAN0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CAN1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_ENET0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_ENET1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_GPIO -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_I2C0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_I2C1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_PJTAG -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_SDIO0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_SDIO1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_SPI0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_SPI1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_UART0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_UART1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_MODEM_UART0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_MODEM_UART1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_TTC0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_TTC1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_WDT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_TRACE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_USB0 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_USB1 -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_DQ_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_DQS_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_DM_WIDTH -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_MIO_PRIMITIVE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLK0_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLK1_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLK2_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLK3_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_RST0_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_RST1_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_RST2_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_RST3_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG0_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG1_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG2_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_EN_CLKTRIG3_PORT -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC_ABORT_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC2_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC3_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC4_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC5_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC6_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_DMAC7_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_SMC_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_QSPI_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_CTI_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_GPIO_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_USB0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_ENET0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_SDIO0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_I2C0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_SPI0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_UART0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_CAN0_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_USB1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_ENET1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_SDIO1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_I2C1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_SPI1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_UART1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_P2F_CAN1_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_IRQ_F2P_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_IRQ_F2P_MODE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CORE0_FIQ_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CORE0_IRQ_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CORE1_FIQ_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_CORE1_IRQ_INTR -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_VALUE_SILVERSION -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GP0_EN_MODIFIABLE_TXN -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_GP1_EN_MODIFIABLE_TXN -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		set PCW_IMPORT_BOARD_PRESET [ipgui::add_param $IPINST -name PCW_IMPORT_BOARD_PRESET -parent $misc_page -widget textEdit]
		foreach key [getlistofuserparam] {
			set_property allow_cyclic_dependency $key $PCW_IMPORT_BOARD_PRESET
		}
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_PERIPHERAL_BOARD_PRESET  -parent $misc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_PRESET_BANK0_VOLTAGE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_PRESET_BANK1_VOLTAGE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ENABLE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ADV_ENABLE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_MEMORY_TYPE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_ECC -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BUS_WIDTH -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_BL -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_HIGH_TEMP -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_PARTNO -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DRAM_WIDTH -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_DEVICE_CAPACITY -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_SPEED_BIN -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_TRAIN_READ_GATE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_TRAIN_DATA_EYE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_CLOCK_STOP_EN -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_DDR_USE_INTERNAL_VREF -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_0 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_1 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_2 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_WRITEPORT_3 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_0 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_1 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_2 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PRIORITY_READPORT_3 -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PORT0_HPR_ENABLE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PORT1_HPR_ENABLE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PORT2_HPR_ENABLE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_PORT3_HPR_ENABLE -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_HPRLPR_QUEUE_PARTITION -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_LPR_TO_CRITICAL_PRIORITY_LEVEL -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_HPR_TO_CRITICAL_PRIORITY_LEVEL -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		ipgui::add_param $IPINST -name PCW_DDR_WRITE_TO_CRITICAL_PRIORITY_LEVEL -parent $ddr_page -widget comboBox 
		ipgui::add_row $IPINST -parent $ddr_page
		set PCW_NAND_PERIPHERAL_ENABLE [ipgui::add_param $IPINST -name PCW_NAND_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox]
		set_property allow_cyclic_dependency "PCW_NOR_PERIPHERAL_ENABLE" $PCW_NAND_PERIPHERAL_ENABLE
		set_property allow_cyclic_dependency "PCW_QSPI_PERIPHERAL_ENABLE" $PCW_NAND_PERIPHERAL_ENABLE
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NAND_NAND_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NAND_GRP_D8_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NAND_GRP_D8_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		set PCW_NOR_PERIPHERAL_ENABLE [ipgui::add_param $IPINST -name PCW_NOR_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox]
		set_property allow_cyclic_dependency "PCW_NAND_PERIPHERAL_ENABLE" $PCW_NOR_PERIPHERAL_ENABLE
		set_property allow_cyclic_dependency "PCW_QSPI_PERIPHERAL_ENABLE" $PCW_NOR_PERIPHERAL_ENABLE
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_NOR_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_A25_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_A25_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS0_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS0_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS1_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_CS1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS1_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_CS1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_INT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_NOR_GRP_SRAM_INT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		set PCW_QSPI_PERIPHERAL_ENABLE [ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox]
		set_property allow_cyclic_dependency "PCW_NAND_PERIPHERAL_ENABLE" $PCW_QSPI_PERIPHERAL_ENABLE
		set_property allow_cyclic_dependency "PCW_NOR_PERIPHERAL_ENABLE" $PCW_QSPI_PERIPHERAL_ENABLE
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_QSPI_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SINGLE_SS_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SINGLE_SS_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SS1_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_SS1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SINGLE_QSPI_DATA_MODE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_DUAL_STACK_QSPI_DATA_MODE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_DUAL_PARALLEL_QSPI_DATA_MODE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_IO1_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_IO1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_FBCLK_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_GRP_FBCLK_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_QSPI_INTERNAL_HIGHADDRESS -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET0_ENET0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET0_GRP_MDIO_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET0_GRP_MDIO_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET_RESET_SELECT -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET0_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET0_RESET_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET1_ENET1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET1_GRP_MDIO_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET1_GRP_MDIO_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET1_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_ENET1_RESET_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_SD0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_GRP_CD_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_GRP_CD_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_GRP_WP_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_GRP_WP_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_GRP_POW_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD0_GRP_POW_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_SD1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_GRP_CD_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_GRP_CD_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_GRP_WP_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_GRP_WP_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_GRP_POW_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SD1_GRP_POW_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART0_UART0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART0_GRP_FULL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART0_GRP_FULL_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART1_UART1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART1_GRP_FULL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_UART1_GRP_FULL_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_SPI0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS0_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS1_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS2_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI0_GRP_SS2_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_SPI1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS0_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS1_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS2_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_SPI1_GRP_SS2_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN0_CAN0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN0_GRP_CLK_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN0_GRP_CLK_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN1_CAN1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN1_GRP_CLK_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_CAN1_GRP_CLK_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_TRACE_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_2BIT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_2BIT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_4BIT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_4BIT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_8BIT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_8BIT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_16BIT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_16BIT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_32BIT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_GRP_32BIT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TRACE_INTERNAL_WIDTH -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_WDT_WDT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TTC0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TTC0_TTC0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TTC1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_TTC1_TTC1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_PJTAG_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_PJTAG_PJTAG_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB0_USB0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB_RESET_SELECT -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB0_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB0_RESET_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB1_USB1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB1_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_USB1_RESET_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C0_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C0_I2C0_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C0_GRP_INT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C0_GRP_INT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C0_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C0_RESET_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C1_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C1_I2C1_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C1_GRP_INT_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C1_GRP_INT_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C_RESET_SELECT -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C1_RESET_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_I2C1_RESET_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_GPIO_PERIPHERAL_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_GPIO_MIO_GPIO_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_GPIO_MIO_GPIO_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_GPIO_EMIO_GPIO_ENABLE -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_GPIO_EMIO_GPIO_IO -parent $mio_page -widget comboBox 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_APU_CLK_RATIO_ENABLE -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_FREQMHZ -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_FREQMHZ -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CPU_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DDR_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SMC_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_QSPI_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SDIO_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_UART_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_SPI_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK0_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK1_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK2_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FCLK3_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET0_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_ENET1_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN0_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_CAN1_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TPIU_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK0_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK1_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC0_CLK2_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK0_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK1_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_TTC1_CLK2_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_WDT_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_DCI_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_PCAP_PERIPHERAL_CLKSRC -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_USB_RESET_POLARITY -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_ENET_RESET_POLARITY -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_I2C_RESET_POLARITY -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_0_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_0_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_0_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_0_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_1_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_1_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_1_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_1_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_2_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_2_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_2_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_2_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_3_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_3_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_3_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_3_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_4_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_4_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_4_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_4_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_5_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_5_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_5_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_5_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_6_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_6_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_6_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_6_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_7_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_7_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_7_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_7_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_8_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_8_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_8_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_8_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_9_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_9_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_9_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_9_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_10_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_10_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_10_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_10_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_11_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_11_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_11_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_11_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_12_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_12_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_12_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_12_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_13_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_13_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_13_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_13_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_14_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_14_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_14_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_14_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_15_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_15_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_15_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_15_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_16_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_16_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_16_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_16_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_17_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_17_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_17_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_17_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_18_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_18_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_18_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_18_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_19_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_19_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_19_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_19_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_20_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_20_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_20_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_20_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_21_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_21_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_21_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_21_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_22_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_22_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_22_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_22_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_23_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_23_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_23_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_23_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_24_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_24_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_24_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_24_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_25_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_25_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_25_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_25_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_26_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_26_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_26_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_26_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_27_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_27_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_27_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_27_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_28_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_28_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_28_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_28_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_29_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_29_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_29_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_29_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_30_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_30_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_30_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_30_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_31_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_31_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_31_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_31_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_32_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_32_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_32_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_32_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_33_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_33_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_33_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_33_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_34_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_34_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_34_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_34_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_35_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_35_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_35_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_35_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_36_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_36_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_36_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_36_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_37_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_37_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_37_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_37_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_38_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_38_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_38_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_38_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_39_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_39_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_39_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_39_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_40_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_40_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_40_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_40_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_41_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_41_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_41_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_41_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_42_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_42_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_42_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_42_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_43_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_43_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_43_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_43_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_44_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_44_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_44_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_44_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_45_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_45_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_45_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_45_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_46_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_46_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_46_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_46_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_47_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_47_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_47_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_47_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_48_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_48_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_48_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_48_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_49_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_49_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_49_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_49_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_50_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_50_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_50_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_50_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_51_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_51_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_51_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_51_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_52_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_52_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_52_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_52_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_53_PULLUP -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_53_IOTYPE -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_53_DIRECTION -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_MIO_53_SLEW -parent $misc_page -widget comboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name preset -parent $misc_page -widget presetComboBox 
		ipgui::add_row $IPINST -parent $misc_page
		ipgui::add_param $IPINST -name PCW_UIPARAM_GENERATE_SUMMARY -parent $mio_page -widget textEdit 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_MIO_TREE_PERIPHERALS -parent $mio_page -widget textEdit 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_MIO_TREE_SIGNALS -parent $mio_page -widget textEdit 
		ipgui::add_row $IPINST -parent $mio_page
		ipgui::add_param $IPINST -name PCW_PS7_SI_REV -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_FPGA_FCLK0_ENABLE -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FPGA_FCLK1_ENABLE -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FPGA_FCLK2_ENABLE -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_FPGA_FCLK3_ENABLE -parent $clock_page -widget comboBox 
		ipgui::add_row $IPINST -parent $clock_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_TR -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_PC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_WP -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_CEOE -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_WC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_T_RC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS0_WE_TIME -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_TR -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_PC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_WP -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_CEOE -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_WC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_T_RC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_SRAM_CS1_WE_TIME -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_TR -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_PC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_WP -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_CEOE -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_WC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS0_T_RC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS0_WE_TIME -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_TR -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_PC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_WP -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_CEOE -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_WC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS1_T_RC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NOR_CS1_WE_TIME -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_RR -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_AR -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_CLR -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_WP -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_REA -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_WC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_NAND_CYCLES_T_RC -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T0 -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T1 -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T2 -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T3 -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T4 -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T5 -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_SMC_CYCLE_T6 -parent $smc_page -widget textEdit 
		ipgui::add_row $IPINST -parent $smc_page
		ipgui::add_param $IPINST -name PCW_PACKAGE_NAME -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		ipgui::add_param $IPINST -name PCW_PLL_BYPASSMODE_ENABLE -parent $general_page -widget comboBox 
		ipgui::add_row $IPINST -parent $general_page
		send_msg_id PS7init-3 INFO "Initilize" -verbose
		set canvas_spec [ipgui::get_canvasspec -of $IPINST]
		set_property ip_logo "data/zynqconfig/guidata/zynq_100x30.png" $canvas_spec
		#Initialize $IPINST
	}
}
