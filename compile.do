# Quit any existing simulation
quit -sim

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

# Map work library
vmap work work

# Compile design files
vlog -sv design.sv

# Compile testbench files
vlog -sv interface.sv
vlog -sv transaction.sv
vlog -sv sequencer.sv
vlog -sv driver.sv
vlog -sv monitor.sv
vlog -sv agent.sv
vlog -sv scoreboard.sv
vlog -sv subscriber.sv
vlog -sv environment.sv
vlog -sv sequence.sv
vlog -sv test.sv

# Compile top module
vlog -sv testbench.sv

echo "Compilation completed"