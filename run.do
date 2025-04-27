# run.do

# Start simulation
vsim -t 1ps work.axi_top_tb_simple

# Set simulation log options
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

# Add waveforms
add wave -position insertpoint sim:/axi_top_tb_simple/*
add wave -position insertpoint sim:/axi_top_tb_simple/axi_if/*

# Add DUT signals (uncomment if you implement DUT and adapter)
# add wave -position insertpoint sim:/axi_top_tb_simple/dut/*
# add wave -position insertpoint sim:/axi_top_tb_simple/adapter/*

# Run simulation
run 10us

# Log message
echo "Simulation completed."