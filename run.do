# run.do - Run multiple tests sequentially after compile

# Run axi_single_rw_test
vsim -c -do "vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_single_rw_test -t 1ps work.axi_top_tb; run -all; quit"

# Run axi_multiple_rw_test
vsim -c -do "vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_multiple_rw_test -t 1ps work.axi_top_tb; run -all; quit"

# Run axi_memory_test
vsim -c -do "vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_memory_test -t 1ps work.axi_top_tb; run -all; quit"

# Run axi_random_test
vsim -c -do "vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_random_test -t 1ps work.axi_top_tb; run -all; quit"

echo "All tests completed."
