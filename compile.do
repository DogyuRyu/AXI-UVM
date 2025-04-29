# Quit any existing simulation
quit -sim

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

# Map work library
vmap work work

# UVM path adjustment for Questa/ModelSim environment
# Try to find UVM 1.2 first, then fall back to 1.1d if needed
set VSIM_PATH [exec dirname [exec which vsim]]
set UVM_1_2_PATH "$VSIM_PATH/../verilog_src/uvm-1.2"
set UVM_1_1D_PATH "$VSIM_PATH/../verilog_src/uvm-1.1d"

if {[file exists $UVM_1_2_PATH]} {
    set UVM_HOME $UVM_1_2_PATH
    puts "Using UVM 1.2 at: $UVM_HOME"
} elseif {[file exists $UVM_1_1D_PATH]} {
    set UVM_HOME $UVM_1_1D_PATH
    puts "Using UVM 1.1d at: $UVM_HOME"
} else {
    puts "Warning: Could not find UVM library at expected paths"
    puts "Trying to use the default UVM path in QuestaSim installation"
    set UVM_HOME "$VSIM_PATH/../verilog_src/uvm"
}

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

# Finally compile the top module
vlog -sv testbench.sv

echo "Compilation completed"