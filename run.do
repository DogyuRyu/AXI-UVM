vsim -c -do "vlog *.svh *.sv; vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_single_rw_test -t 1ps work.axi_top_tb; run -all; quit"
vsim -c -do "vlog *.svh *.sv; vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_multiple_rw_test -t 1ps work.axi_top_tb; run -all; quit"
vsim -c -do "vlog *.svh *.sv; vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_memory_test -t 1ps work.axi_top_tb; run -all; quit"
vsim -c -do "vlog *.svh *.sv; vsim -voptargs=\"+acc\" +UVM_TESTNAME=axi_random_test -t 1ps work.axi_top_tb; run -all; quit"

