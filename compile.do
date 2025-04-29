# Quit any existing simulation
quit -sim

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

# Map work library
vmap work work

# 직접 UVM 경로 설정 - 시스템에 맞게 조정
set UVM_HOME "/package/eda/mg/questa2021.4/questasim/verilog_src/uvm-1.1d"
puts "Using UVM path: $UVM_HOME"

# Compile UVM package
vlog -sv +define+UVM_NO_DPI +incdir+$UVM_HOME/src $UVM_HOME/src/uvm_pkg.sv $UVM_HOME/src/uvm_macros.svh

# Compile design files with UVM include path
vlog -sv +incdir+$UVM_HOME/src design.sv

# Compile testbench files with UVM include path
vlog -sv +incdir+$UVM_HOME/src interface.sv
vlog -sv +incdir+$UVM_HOME/src transaction.sv
vlog -sv +incdir+$UVM_HOME/src sequencer.sv
vlog -sv +incdir+$UVM_HOME/src driver.sv
vlog -sv +incdir+$UVM_HOME/src monitor.sv
vlog -sv +incdir+$UVM_HOME/src agent.sv
vlog -sv +incdir+$UVM_HOME/src scoreboard.sv
vlog -sv +incdir+$UVM_HOME/src subscriber.sv
vlog -sv +incdir+$UVM_HOME/src environment.sv
vlog -sv +incdir+$UVM_HOME/src sequence.sv
vlog -sv +incdir+$UVM_HOME/src test.sv

# Finally compile the top module with UVM include path
vlog -sv +incdir+$UVM_HOME/src testbench.sv

echo "Compilation completed"