# run.do - With multiple test options

# Test: Basic Write/Read Test (Uncomment to run)
vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_read_test -t 1ps work.tb_top

# Test: Write-only Test (Uncomment to run)
# vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_write_test -t 1ps work.tb_top

# Test: Burst Transfers Test (Uncomment to run)
# vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_burst_test -t 1ps work.tb_top

# Test: Mixed Read/Write Test (Uncomment to run)
# vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_mixed_test -t 1ps work.tb_top

# Optional logging
log -r /*

# Run simulation
run -all

echo "Simulation completed."