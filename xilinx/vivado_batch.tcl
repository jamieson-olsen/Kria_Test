# Simple TCL script for Vivado builds so I don't have use that damn GUI
# Jamieson Olsen <jamieson@fnal.gov>
#
# vivado -mode tcl -source vivado_batch.tcl

# general setup stuff...

set_param general.maxThreads 4
set outputDir ./output
file mkdir $outputDir
set_part xck26-sfvs784-2LV

# load the VHDL sources...

read_vhdl ../kria_test_package.vhd

# timing endpoint firmware from bristol UK folks, this is version 2
# here is their source tree, sources taken from the "endpoint" and "common" directories

read_vhdl ../timing/ep_src/pdts_defs.vhd
read_vhdl ../timing/ep_src/pdts_ep_defs.vhd
read_vhdl ../timing/ep_src/pdts_clock_defs.vhd
read_vhdl ../timing/ep_src/pdts_code8b10bpkg.vhd
read_vhdl ../timing/ep_src/pdts_endpoint.vhd
	read_vhdl ../timing/ep_src/pdts_ep_cdr.vhd
		read_vhdl ../timing/ep_src/pdts_cdr_sampler.vhd
	read_vhdl ../timing/ep_src/pdts_ep_core.vhd
		read_vhdl ../timing/ep_src/pdts_ep_sm.vhd
			read_vhdl ../timing/ep_src/pdts_synchro.vhd
			read_vhdl ../timing/ep_src/pdts_synchro_pulse.vhd
		read_vhdl ../timing/ep_src/pdts_rx.vhd
			read_vhdl ../timing/ep_src/pdts_rx_phy.vhd
				read_vhdl ../timing/ep_src/pdts_del.vhd
				read_vhdl ../timing/ep_src/pdts_dec8b10b.vhd
			read_vhdl ../timing/ep_src/pdts_rx_pkt.vhd
				read_vhdl ../timing/ep_src/pdts_cksum.vhd
					read_vhdl ../timing/ep_src/outputlogic_crc16.vhd
			read_vhdl ../timing/ep_src/pdts_ep_ctrl.vhd
				read_vhdl ../timing/ep_src/pdts_ep_transactor.vhd
			read_vhdl ../timing/ep_src/pdts_pktbuf.vhd
				read_vhdl ../timing/ep_src/pdts_lutram.vhd
		read_vhdl ../timing/ep_src/pdts_ep_ctrlmux.vhd
		read_vhdl ../timing/ep_src/pdts_ep_regfile.vhd
		read_vhdl ../timing/ep_src/pdts_tx.vhd
			read_vhdl ../timing/ep_src/pdts_idle_gen.vhd
			read_vhdl ../timing/ep_src/pdts_acmd_arb.vhd
			read_vhdl ../timing/ep_src/pdts_tx_phy.vhd
				read_vhdl ../timing/ep_src/pdts_enc8b10b.vhd
			read_vhdl ../timing/ep_src/pdts_tx_pkt.vhd
		read_vhdl ../timing/ep_src/pdts_ep_tstamp.vhd
	read_vhdl ../timing/ep_src/pdts_mod.vhd
read_vhdl ../timing/pdts_endpoint_wrapper.vhd
read_vhdl ../timing/endpoint.vhd

read_vhdl ../kria_test.vhd

# Load IP blocks xci files
read_ip ../src/ip/DAPHNE_V3_1E_ila_0_0.xci
read_ip ../src/ip/DAPHNE_V3_1E_vio_0_0.xci
read_ip ../src/ip/DAPHNE_V3_1E_zynq_ultra_ps_e_0_0.xci

set_property target_language VHDL [current_project]
generate_target all [get_files ../src/ip/*.xci]

# Load general timing and placement constraints...

read_xdc -verbose ./constraints.xdc

# get the git SHA hash (commit id) and pass it to the top level source
# keep it simple just use the short form of the long SHA-1 number.
# Note this is a 7 character HEX string, e.g. 28 bits, but Vivado requires 
# this number to be in Verilog notation, even if the top level source is VHDL.

set git_sha [exec git rev-parse --short=7 HEAD]
set v_git_sha "28'h$git_sha"
puts "INFO: passing git commit number $v_git_sha to top level generic"

# synth design...

synth_design -top daphne2 -generic version=$v_git_sha
report_clocks -file $outputDir/clocks.rpt
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_power -file $outputDir/post_synth_power.rpt
report_utilization -file $outputDir/post_synth_util.rpt

# place...

opt_design
place_design -directive WLDrivenBlockPlacement
phys_opt_design -directive AggressiveFanoutOpt
# write_checkpoint -force $outputDir/post_place
report_timing_summary -file $outputDir/post_place_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_place_timing.rpt

# route...

route_design -directive HigherDelayCost
# write_checkpoint -force $outputDir/post_route

# generate reports...

report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_route_timing.rpt
report_clock_utilization -file $outputDir/clock_util.rpt
report_utilization -file $outputDir/post_route_util.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt
report_io -file $outputDir/io.rpt

# write out VHDL and constraints for timing sim...

#write_vhdl -force $outputDir/vivpram_impl_netlist.v
#write_xdc -no_fixed_only -force $outputDir/bft_impl.xdc

# generate bitstream...

write_bitstream -force -bin_file $outputDir/daphne2_$git_sha.bit

# write out ILA debug probes file
write_debug_probes -force $outputDir/probes.ltx

exit


