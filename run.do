# run.do - for single simulation

# Start simulation
vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=axi_single_rw_test -t 1ps work.axi_top_tb

# Optional logging
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

# Run simulation
run -all

echo "Simulation completed."
