# FPAI: board-equivalent clock for independent PS IP synthesis.
create_clock -name PJTAG_TCK -period 100.000 -waveform {0.000 50.000} [get_ports PJTAG_TCK]
