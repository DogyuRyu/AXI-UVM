# If not already compiled, compile the design and testbench
if {![file exists work/_info]} {
    do compile.do
}

# Use a graphical interface for the simulation
vsim tb_top

# Add wave to the waveform viewer
add wave -position insertpoint sim:/tb_top/intf/*
add wave -position insertpoint sim:/tb_top/inst/*

# Set radix for viewing signals
radix -hexadecimal

# Run the simulation for 10us or until completion
run 10us

echo "Simulation completed"