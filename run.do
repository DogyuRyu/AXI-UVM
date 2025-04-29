# Run compilation if needed
do compile.do

# Start simulation
vsim tb_top

# Add waveform
add wave -position insertpoint sim:/tb_top/intf/*
add wave -position insertpoint sim:/tb_top/inst/*

# Set radix for viewing signals
radix -hexadecimal

# Run the simulation for 10us or until completion
run 10us

echo "Simulation completed"