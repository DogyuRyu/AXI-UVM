# If not already compiled, compile the design and testbench
if {![file exists work/_info]} {
    do compile.do
}

# Use a graphical interface for the simulation
vsim tb_top

# Run the simulation for 10us or until completion
run 10us

echo "Simulation completed"