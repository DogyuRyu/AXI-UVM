# run.do - Updated to ensure waves are captured properly

# Start simulation with visibility preservation
vsim -voptargs="+acc" -t 1ps work.axi_top_tb

# Set simulation log options
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

# Add waveforms - more explicit signal path
add wave -position insertpoint sim:/axi_top_tb/*
add wave -position insertpoint sim:/axi_top_tb/axi_if/*
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/ACLK
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/ARESETn
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/AWID
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/AWADDR
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/AWVALID
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/AWREADY
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/WDATA
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/WVALID
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/WREADY
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/BVALID
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/BREADY
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/ARADDR
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/ARVALID
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/ARREADY
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/RDATA
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/RVALID
add wave -position insertpoint -expand -group "AXI Interface" sim:/axi_top_tb/axi_if/RREADY

# Run simulation longer - 1000ns instead of typical 10us
run 1000ns

# Zoom to full wave
wave zoom full

# Log message
echo "Simulation completed. Check waves for signal activity."