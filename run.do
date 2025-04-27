# run.do - Updated to use -voptargs="+acc" instead of -novopt

# Start simulation with visibility preservation
vsim -voptargs="+acc" -t 1ps work.axi_top_tb

# Set simulation log options
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

# Add waveforms
add wave -position insertpoint sim:/axi_top_tb/*
add wave -position insertpoint sim:/axi_top_tb/axi_if/*
add wave -position insertpoint sim:/axi_top_tb/dut/*
add wave -position insertpoint sim:/axi_top_tb/adapter/*

# Run simulation
run 10us

# Log message
echo "Simulation completed."