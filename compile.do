# Quit any existing simulation
quit -sim

# Delete existing work directory if exists
if {[file exists work]} {
  vdel -all -lib work
}

# Create work library
vlib work

# Compile all testbench files using MFCU
vlog -sv -mfcu +acc=npr +incdir+. -timescale "1ns/1ps" \
  axi_interface.sv \
  axi_transaction.sv \
  axi_sequencer.sv \
  axi_driver.sv \
  axi_monitor.sv \
  axi_agent.sv \
  axi_scoreboard.sv \
  axi_subscriber.sv \
  axi_environment.sv \
  axi_sequence.sv \
  axi_test.sv \
  axi_design.sv \
  axi_testbench.sv

echo "Compilation Completed"