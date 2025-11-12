# Artix 7 AC701 Pin Assignments
############################
# On-board Slide Switches  #
############################
set_property -dict { PACKAGE_PIN P6   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; #GPIO_SW_N
set_property -dict { PACKAGE_PIN T5   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];#GPIO_SW_S
set_property -dict { PACKAGE_PIN R5   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]; #GPIO_SW_W
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]; #GPIO_SW_E
set_property -dict { PACKAGE_PIN U6   IOSTANDARD LVCMOS33 } [get_ports { sw[4] }]; #GPIO_SW_C

set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports { RESET }]; #CPU_Reset
set_property -dict { PACKAGE_PIN M21   IOSTANDARD LVCMOS33 } [get_ports { CLK }]; #USER_CLOCK_P = 156.25 MHz
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLK]
############################
# On-board led             #
############################
set_property -dict { PACKAGE_PIN M26   IOSTANDARD LVCMOS33 } [get_ports { LED[0] }];
set_property -dict { PACKAGE_PIN T24   IOSTANDARD LVCMOS33 } [get_ports { LED[1] }];
set_property -dict { PACKAGE_PIN T25   IOSTANDARD LVCMOS33 } [get_ports { LED[2] }];
set_property -dict { PACKAGE_PIN R26   IOSTANDARD LVCMOS33 } [get_ports { LED[3] }];

set_property -dict { PACKAGE_PIN P26   IOSTANDARD LVCMOS33 } [get_ports { RsRx }]; #PMOD_0
set_property -dict { PACKAGE_PIN T22   IOSTANDARD LVCMOS33 } [get_ports { RsTx }]; #PMOD_1
#set_property -dict { PACKAGE_PIN R22   IOSTANDARD LVCMOS33 } [get_ports { LED[6] }]; #PMOD_2
#set_property -dict { PACKAGE_PIN T23   IOSTANDARD LVCMOS33 } [get_ports { LED[7] }]; #PMOD_3



###################################
# LCD Display Header (J23)        #
###################################
set_property -dict { PACKAGE_PIN L25   IOSTANDARD LVCMOS33 } [get_ports { LCD_DB_OUT[4] }]; # LCD Header Pin 4
set_property -dict { PACKAGE_PIN M24   IOSTANDARD LVCMOS33 } [get_ports { LCD_DB_OUT[5] }]; # LCD Header Pin 3
set_property -dict { PACKAGE_PIN M25   IOSTANDARD LVCMOS33 } [get_ports { LCD_DB_OUT[6] }]; # LCD Header Pin 2
set_property -dict { PACKAGE_PIN L22   IOSTANDARD LVCMOS33 } [get_ports { LCD_DB_OUT[7] }]; # LCD Header Pin 1

# --- LCD Control Pins ---
set_property -dict { PACKAGE_PIN L24   IOSTANDARD LVCMOS33 } [get_ports { LCD_RW_OUT }]; # LCD Header Pin 10
set_property -dict { PACKAGE_PIN L23   IOSTANDARD LVCMOS33 } [get_ports { LCD_RS_OUT }]; # LCD Header Pin 11
set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS33 } [get_ports { LCD_E_OUT }];  # LCD Header Pin 9