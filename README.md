# Kria Test Firmware

Firmware for the PL side of the Kria Test board. Target is the Kria K26 module.

## Timing Endpoint

This firmware includes the timing endpoint logic plus Virtual IO (VIO) and Internal Logic Analyzer (ILA) "chipscope" modules for debugging.

## Build Strategy

This design is meant to be built using Vivado NON PROJECT MODE. That means you run the tcl build script from the command line like this:

	$ vivado -mode tcl -source vivado_batch.tcl

This can be done on a linux machine with Vivado installed. Let me know if you need access to one of these PCs. Alternatively, you can install Cygwin on top of windows and enter the command in a Cygwin terminal window. If you install Cygwin you should also install some optional stuff like git.

## Output Files

After the build script completes the output files, which includes the BIN/BIT files along with all report files are in Xilinx/output. The BIT and BIN files will be renamed to kriatest_GITcommitID.bit and kriatest_GITcommitID.bin.
