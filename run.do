# run.do

# Test: basic read test
vsim -voptargs="+acc" +UVM_VERBOSITY=UVM_MEDIUM +UVM_TESTNAME=axi_read_test -t 1ps work.tb_top

log -r /*

run -all

echo "Simulation Completed"