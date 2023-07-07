# Kria_Test PL FPGA constraints
# note this is only for the logic on the PL side of the Zynq device!
# Jamieson Olsen <jamieson@fnal.gov>

# #############################################################################
# Timing constraints...
# Note: Xilinx IP core constraints will be applied automatically
# when the *.xcix file is added to the project

# define primary clocks...

create_clock -name rx0_tmg_clk  -period 16.000  [get_ports rx0_tmg_p] ;# 62.5MHz timing endpoint clock
create_clock -name sysclk       -period 10.000  [get_ports sysclk_p] ;# 100MHz system clock
#create_clock -name gth_refclk   -period 6.400   [get_ports gth0_refclk_p] ;# 156.25MHz GTH 10G clock

# rename the auto-generated clocks...

create_generated_clock -name local_clk62p5  [get_pins endpoint_inst/mmcm0_inst/CLKOUT0]
create_generated_clock -name sclk200        [get_pins endpoint_inst/mmcm0_inst/CLKOUT1]
create_generated_clock -name sclk100        [get_pins endpoint_inst/mmcm0_inst/CLKOUT2]
create_generated_clock -name mmcm0_clkfbout [get_pins endpoint_inst/mmcm0_inst/CLKFBOUT]

create_generated_clock -name ep_clk62p5      [get_pins endpoint_inst/pdts_endpoint_inst/pdts_endpoint_inst/rxcdr/mmcm/CLKOUT0]
create_generated_clock -name ep_clk4x        [get_pins endpoint_inst/pdts_endpoint_inst/pdts_endpoint_inst/rxcdr/mmcm/CLKOUT1]
create_generated_clock -name ep_clk2x        [get_pins endpoint_inst/pdts_endpoint_inst/pdts_endpoint_inst/rxcdr/mmcm/CLKOUT1]
create_generated_clock -name ep_clkfbout     [get_pins endpoint_inst/pdts_endpoint_inst/pdts_endpoint_inst/rxcdr/mmcm/CLKFBOUT] 

#create_generated_clock -name daqclk0      [get_pins core_inst/core_mgt4_inst/daq_quad_inst/U0/gt_usrclk_source/txoutclk_mmcm0_i/mmcm_adv_inst/CLKOUT0]
#create_generated_clock -name daqclk1      [get_pins core_inst/core_mgt4_inst/daq_quad_inst/U0/gt_usrclk_source/txoutclk_mmcm0_i/mmcm_adv_inst/CLKOUT1]
#create_generated_clock -name daq_clkfbout [get_pins core_inst/core_mgt4_inst/daq_quad_inst/U0/gt_usrclk_source/txoutclk_mmcm0_i/mmcm_adv_inst/CLKFBOUT]

#create_generated_clock -name fclk0           -master_clock ep_clk62p5 [get_pins endpoint_inst/mmcm1_inst/CLKOUT0]
create_generated_clock -name mclk0           -master_clock ep_clk62p5 [get_pins endpoint_inst/mmcm1_inst/CLKOUT1]
create_generated_clock -name mmcm1_clkfbout0 -master_clock ep_clk62p5 [get_pins endpoint_inst/mmcm1_inst/CLKFBOUT]
#create_generated_clock -name fclk1           -master_clock local_clk62p5 [get_pins endpoint_inst/mmcm1_inst/CLKOUT0]
create_generated_clock -name mclk1           -master_clock local_clk62p5 [get_pins endpoint_inst/mmcm1_inst/CLKOUT1]
create_generated_clock -name mmcm1_clkfbout1 -master_clock local_clk62p5 [get_pins endpoint_inst/mmcm1_inst/CLKFBOUT]

set_clock_groups -name async_groups -asynchronous \
-group {sysclk sclk100 mmcm0_clkfbout} -group {sclk200} -group {local_clk62p5} \
-group {mclk0 mmcm1_clkfbout0} -group {mclk1 mmcm1_clkfbout1} \
-group {ep_clk62p5 ep_clk4x ep_clk2x ep_clkfbout} -group {rx0_tmg_clk} 

# tell Vivado about places where signals cross clock domains so timing can be ignored here...
#set_false_path -from [get_pins fe_inst/gen_afe[*].afe_inst/auto_fsm_inst/done_reg_reg/C]      
#set_false_path -from [get_pins fe_inst/gen_afe[*].afe_inst/auto_fsm_inst/warn_reg_reg/C]      
#set_false_path -from [get_pins fe_inst/gen_afe[*].afe_inst/auto_fsm_inst/errcnt_reg_reg[*]/C] 


# #############################################################################
# Pin LOCation and IOSTANDARD Constraints
# taken from Xilinx XDC file for Kria K26 SOM - Rev 1

# Timing Interface, bank 43, VCCO=3.3V

set_property PACKAGE_PIN  AF10 [get_ports {sfp_tmg_los}] ;# SOM240_2_C52
set_property PACKAGE_PIN  AE10 [get_ports {sfp_tmg_abs}] ;# SOM240_2_C51
set_property PACKAGE_PIN  AD12 [get_ports {sfp_tmg_tx_dis}] ;# SOM240_2_C50
set_property IOSTANDARD LVTTL [get_ports {sfp_tmg_los}]
set_property IOSTANDARD LVTTL [get_ports {sfp_tmg_abs}]
set_property IOSTANDARD LVTTL [get_ports {sfp_tmg_tx_dis}]

# Timing Interface, bank 64, VCCO=1.8V
# RX pair has 100 ohm terminator installed on the board
# RX pair enters on a "GC" clock capable input

set_property PACKAGE_PIN AD5 [get_ports {tx0_tmg_p}] ;# SOM240_2_C29
set_property PACKAGE_PIN AD4 [get_ports {tx0_tmg_n}] ;# SOM240_2_C30
set_property PACKAGE_PIN AE5 [get_ports {rx0_tmg_p}] ;# SOM240_2_C41
set_property PACKAGE_PIN AF5 [get_ports {rx0_tmg_n}] ;# SOM240_2_C42
set_property IOSTANDARD LVDS [get_ports {tx0_tmg_?}]
set_property IOSTANDARD LVDS [get_ports {rx0_tmg_?}]
set_property DIFF_TERM FALSE [get_ports {rx0_tmg_?}]

# System clock 100MHz, bank 66, VCCO=1.8V, HPIO
# enable internal termination on this LVDS input

set_property PACKAGE_PIN C3 [get_ports {sysclk_p}] ;# SOM240_1_A6
set_property PACKAGE_PIN C2 [get_ports {sysclk_n}] ;# SOM240_1_A7
set_property IOSTANDARD LVDS [get_ports {sysclk_p}]
set_property IOSTANDARD LVDS [get_ports {sysclk_n}]
set_property DIFF_TERM TRUE [get_ports {sysclk_p}]
set_property DIFF_TERM TRUE [get_ports {sysclk_n}]

# PL I2C Master, bank 43, VCCO=3.3V

#set_property PACKAGE_PIN AB11 [get_ports {pl_scl}] ;# SOM240_2_B49
#set_property PACKAGE_PIN AC11 [get_ports {pl_sda}] ;# SOM240_2_B50
#set_property PACKAGE_PIN AH12 [get_ports {pl_i2c_resetn}] ;# SOM240_2_C46
#set_property IOSTANDARD LVTTL [get_ports {pl_scl}]
#set_property IOSTANDARD LVTTL [get_ports {pl_sda}]
#set_property IOSTANDARD LVTTL [get_ports {pl_i2c_resetn}]

# PL DAC SPI Master, bank 43, VCCO=3.3V

#set_property PACKAGE_PIN AD10 [get_ports {dac_spi_din}] ;# SOM240_2_B45
#set_property PACKAGE_PIN AD11 [get_ports {dac_spi_sclk}] ;# SOM240_2_B44
#set_property PACKAGE_PIN AA11 [get_ports {dac_spi_syncn}] ;# SOM240_2_B46
#set_property PACKAGE_PIN AA10 [get_ports {dac_spi_ldacn}] ;# SOM240_2_B48
#set_property IOSTANDARD LVTTL [get_ports {dac_spi_din}]
#set_property IOSTANDARD LVTTL [get_ports {dac_spi_sclk}]
#set_property IOSTANDARD LVTTL [get_ports {dac_spi_syncn}]
#set_property IOSTANDARD LVTTL [get_ports {dac_spi_ldacn}]

# DAQ Links GTH support signals, bank 43, VCCO=3.3V

#set_property PACKAGE_PIN Y9 [get_ports {sfp_gth0_los}] ;# SOM240_2_A48
#set_property PACKAGE_PIN Y10 [get_ports {sfp_gth0_abs}] ;# SOM240_2_A47
#set_property PACKAGE_PIN W10 [get_ports {sfp_gth0_tx_dis}] ;# SOM240_2_A46
#set_property IOSTANDARD LVTTL [get_ports {sfp_gth0_los}]
#set_property IOSTANDARD LVTTL [get_ports {sfp_gth0_abs}]
#set_property IOSTANDARD LVTTL [get_ports {sfp_gth0_tx_dis}]

#set_property PACKAGE_PIN AB9 [get_ports {sfp_gth1_los}] ;# SOM240_2_A52
#set_property PACKAGE_PIN AB10 [get_ports {sfp_gth1_abs}] ;# SOM240_2_A51
#set_property PACKAGE_PIN AA8 [get_ports {sfp_gth1_tx_dis}] ;# SOM240_2_A50
#set_property IOSTANDARD LVTTL [get_ports {sfp_gth1_los}]
#set_property IOSTANDARD LVTTL [get_ports {sfp_gth1_abs}]
#set_property IOSTANDARD LVTTL [get_ports {sfp_gth1_tx_dis}]

# DAQ links are GTH bank 224, channels 0 and 1

# set_property LOC GTH_CHANNEL_X0Y6 [get_cells sender_inst/gtpe2_i]

#set_property LOC Y6 [get_ports gth_refclk0_p] ;# SOM240_2_C3
#set_property LOC Y5 [get_ports gth_refclk0_n] ;# SOM240_2_C4

#set_property LOC W4 [get_ports tx0_gth_p] ;# SOM240_2_D9
#set_property LOC W3 [get_ports tx0_gth_n] ;# SOM240_2_D10
#set_property LOC Y2 [get_ports rx0_gth_p] ;# SOM240_2_B9
#set_property LOC Y1 [get_ports rx0_gth_n] ;# SOM240_2_B10

#set_property LOC U4 [get_ports tx1_gth_p] ;# SOM240_2_C7
#set_property LOC U3 [get_ports tx1_gth_n] ;# SOM240_2_C8
#set_property LOC V2 [get_ports rx1_gth_p] ;# SOM240_2_D1
#set_property LOC V1 [get_ports rx1_gth_n] ;# SOM240_2_D2

# PL Status LEDs, bank 43, VCCO=3.3V

set_property PACKAGE_PIN AG11 [get_ports {pl_stat_led[3]}] ;# SOM240_2_D50
set_property PACKAGE_PIN AF11 [get_ports {pl_stat_led[2]}] ;# SOM240_2_D49
set_property PACKAGE_PIN AH10 [get_ports {pl_stat_led[1]}] ;# SOM240_2_D48
set_property PACKAGE_PIN AG10 [get_ports {pl_stat_led[0]}] ;# SOM240_2_D46
set_property IOSTANDARD LVTTL [get_ports {pl_stat_led[?]}]

# General bitstream constraints...
# need to double check these for Kria Zynq Ultrascale+

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

