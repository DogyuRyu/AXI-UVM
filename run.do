# run.do

# Test: basic read test
vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_read_test -t 1ps work.tb_top

# Test: write only test
# vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_write_test -t 1ps work.tb_top

# Test: burst test
# vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_burst_test -t 1ps work.tb_top

# Test: mixed read/write test
# vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_mixed_test -t 1ps work.tb_top

log -r /*

run -all

echo "Simulation Completed"