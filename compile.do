# Quit any existing simulation
quit -sim

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

# Map work library
vmap work work

# Define SystemVerilog UVM compile options
set UVM_HOME $env(UVM_HOME)
set DEFINES "-define UVM_NO_DPI"

# Compile UVM package
vlog -sv +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv

# Compile design files
vlog -sv design.sv

# Compile testbench files (one at a time with correct order)
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

# Finally compile the top module using the include_files.sv indirectly
vlog -sv testbench.sv

echo "Compilation completed"