#! /bin/tcsh -f
# By Jamil Khatib
# This file for compiling the tdm project files using Cadence nc-sim tool
# You need to create sim directory in the same level of the code directory 
# From OpenCores CVS
# You have to start the simulation in this directory
#$Log: build_fifo.csh,v $
#Revision 1.1  2001/06/04 20:23:04  khatib
#Initial Release
#
#Revision 1.1  2001/06/03 09:19:56  jamil
#Initial Release
#
mkdir -p work
mkdir -p utility
mkdir -p memLib

# Utility files
ncvhdl -work utility -cdslib ./cds.lib -logfile ncvhdl.log -append_log -errormax 15 -update -v93 -linedebug -messages -status ../tools_pkg.vhd

#memLib
ncvhdl -work memLib -cdslib ./cds.lib -logfile ncvhdl.log -append_log -errormax 15 -update -v93 -linedebug -messages -status ../../libs/memLib/mem_pkg.vhd

ncvhdl -work memLib -cdslib ./cds.lib -logfile ncvhdl.log -append_log -errormax 15 -update -v93 -linedebug -messages -status ../../dpmem/core/dpmem.vhd

ncvhdl -work memLib -cdslib ./cds.lib -logfile ncvhdl.log -append_log -errormax 15 -update -v93 -linedebug -messages -status ../core/fifo.vhd

ncvhdl -work memLib -cdslib ./cds.lib -logfile ncvhdl.log -append_log -errormax 15 -update -v93 -linedebug -messages -status ../tb/fifo_tb.vhd
