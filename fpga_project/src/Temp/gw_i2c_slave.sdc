//Copyright (C)2014-2019 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.1.01 Beta
//Created Time: 2019-09-17 10:35:33
create_clock -name CLK_50M -period 20 -waveform {0 10} [get_ports {clk_50m}]
create_generated_clock -name CLKOUT_50M -source [get_ports {clk_50m}] -master_clock CLK_50M [get_nets {clkout_50m}]
