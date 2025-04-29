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
  interface.sv \
  transaction.sv \
  sequencer.sv \
  driver.sv \
  monitor.sv \
  agent.sv \
  scoreboard.sv \
  subscriber.sv \
  environment.sv \
  sequence.sv \
  test.sv \
  design.sv \
  testbench.sv

echo "Compilation Completed"