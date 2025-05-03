do compile.do

echo "=== Running test_case_1 ==="
#vsim -assertdebug -uvmcontrol=all -t 1ps work.tb_top +UVM_TESTNAME=test_case_1

echo "=== Running test_case_2 ==="
#vsim -assertdebug -uvmcontrol=all -t 1ps work.tb_top +UVM_TESTNAME=test_case_2

echo "=== Running test_case_3 ==="
#vsim -assertdebug -uvmcontrol=all -t 1ps work.tb_top +UVM_TESTNAME=test_case_3

echo "=== Running test_case_4 ==="
#vsim -assertdebug -uvmcontrol=all -t 1ps work.tb_top +UVM_TESTNAME=test_case_4

echo "=== Running test_case_5 ==="
#vsim -assertdebug -uvmcontrol=all -t 1ps work.tb_top +UVM_TESTNAME=test_case_5

echo "All tests completed"