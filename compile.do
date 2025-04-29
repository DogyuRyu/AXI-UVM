# Quit any existing simulation
quit -sim

# Delete existing work directory if exists
if {[file exists work]} {
  vdel -all
}

# Create work library
vlib work

# Compile interface and testbench files
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" interface.sv
vlog -sv +acc=npr design.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" transaction.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" sequencer.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" driver.sv 
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" monitor.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" agent.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" scoreboard.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" subscriber.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" environment.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" sequence.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" test.sv
vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" testbench.sv

echo "Compilation Completed"