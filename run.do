# run.do - Updated for better wave visualization and longer runtime

# Start simulation with visibility preservation
vsim -voptargs="+acc" -t 1ps work.axi_top_tb

# Set simulation log options
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

# Add waveforms - organize signals for better visibility
add wave -position insertpoint sim:/axi_top_tb/clk
add wave -position insertpoint sim:/axi_top_tb/rstn

# AXI Interface Signals - explicitly add with organized grouping
add wave -position insertpoint -expand -group "AXI Clock/Reset" sim:/axi_top_tb/axi_if/ACLK
add wave -position insertpoint -expand -group "AXI Clock/Reset" sim:/axi_top_tb/axi_if/ARESETn

# Write Address Channel
add wave -position insertpoint -expand -group "Write Address Channel" sim:/axi_top_tb/axi_if/AWID
add wave -position insertpoint -expand -group "Write Address Channel" sim:/axi_top_tb/axi_if/AWADDR
add wave -position insertpoint -expand -group "Write Address Channel" sim:/axi_top_tb/axi_if/AWLEN
add wave -position insertpoint -expand -group "Write Address Channel" sim:/axi_top_tb/axi_if/AWSIZE
add wave -position insertpoint -expand -group "Write Address Channel" sim:/axi_top_tb/axi_if/AWBURST
add wave -position insertpoint -expand -group "Write Address Channel" sim:/axi_top_tb/axi_if/AWVALID
add wave -position insertpoint -expand -group "Write Address Channel" sim:/axi_top_tb/axi_if/AWREADY

# Write Data Channel
add wave -position insertpoint -expand -group "Write Data Channel" sim:/axi_top_tb/axi_if/WDATA
add wave -position insertpoint -expand -group "Write Data Channel" sim:/axi_top_tb/axi_if/WSTRB
add wave -position insertpoint -expand -group "Write Data Channel" sim:/axi_top_tb/axi_if/WLAST
add wave -position insertpoint -expand -group "Write Data Channel" sim:/axi_top_tb/axi_if/WVALID
add wave -position insertpoint -expand -group "Write Data Channel" sim:/axi_top_tb/axi_if/WREADY

# Write Response Channel
add wave -position insertpoint -expand -group "Write Response Channel" sim:/axi_top_tb/axi_if/BID
add wave -position insertpoint -expand -group "Write Response Channel" sim:/axi_top_tb/axi_if/BRESP
add wave -position insertpoint -expand -group "Write Response Channel" sim:/axi_top_tb/axi_if/BVALID
add wave -position insertpoint -expand -group "Write Response Channel" sim:/axi_top_tb/axi_if/BREADY

# Read Address Channel
add wave -position insertpoint -expand -group "Read Address Channel" sim:/axi_top_tb/axi_if/ARID
add wave -position insertpoint -expand -group "Read Address Channel" sim:/axi_top_tb/axi_if/ARADDR
add wave -position insertpoint -expand -group "Read Address Channel" sim:/axi_top_tb/axi_if/ARLEN
add wave -position insertpoint -expand -group "Read Address Channel" sim:/axi_top_tb/axi_if/ARSIZE
add wave -position insertpoint -expand -group "Read Address Channel" sim:/axi_top_tb/axi_if/ARBURST
add wave -position insertpoint -expand -group "Read Address Channel" sim:/axi_top_tb/axi_if/ARVALID
add wave -position insertpoint -expand -group "Read Address Channel" sim:/axi_top_tb/axi_if/ARREADY

# Read Data Channel
add wave -position insertpoint -expand -group "Read Data Channel" sim:/axi_top_tb/axi_if/RID
add wave -position insertpoint -expand -group "Read Data Channel" sim:/axi_top_tb/axi_if/RDATA
add wave -position insertpoint -expand -group "Read Data Channel" sim:/axi_top_tb/axi_if/RRESP
add wave -position insertpoint -expand -group "Read Data Channel" sim:/axi_top_tb/axi_if/RLAST
add wave -position insertpoint -expand -group "Read Data Channel" sim:/axi_top_tb/axi_if/RVALID
add wave -position insertpoint -expand -group "Read Data Channel" sim:/axi_top_tb/axi_if/RREADY

# DUT signals
add wave -position insertpoint -group "DUT" sim:/axi_top_tb/dut/*

# Run simulation with regular updates to wave display
run 50ns
wave update
run 50ns
wave update
run 50ns
wave update
run 50ns
wave update
run 50ns
wave update
run 800ns

# Zoom to full waveform view
wave zoom full

# Final check - force some signals to verify waveform visibility
echo "Testing waveform visibility with forced signals..."
force -deposit sim:/axi_top_tb/axi_if/AWVALID 1
force -deposit sim:/axi_top_tb/axi_if/AWADDR 32'hABCD1234
run 10ns
force -deposit sim:/axi_top_tb/axi_if/AWVALID 0
run 10ns
wave update
wave zoom full

echo "Simulation completed. Check waves for signal activity."