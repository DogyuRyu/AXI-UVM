# 모든 테스트 케이스를 순차적으로 실행하는 스크립트

# 먼저 컴파일
do compile.do

echo "=== Running test_case_1 ==="
vsim -c -t 1ps -do "run 10us; exit" tb_top +UVM_TESTNAME=test_case_1

echo "=== Running test_case_2 ==="
vsim -c -t 1ps -do "run 10us; exit" tb_top +UVM_TESTNAME=test_case_2

echo "=== Running test_case_3 ==="
vsim -c -t 1ps -do "run 10us; exit" tb_top +UVM_TESTNAME=test_case_3

echo "=== Running test_case_4 ==="
vsim -c -t 1ps -do "run 10us; exit" tb_top +UVM_TESTNAME=test_case_4

echo "=== Running test_case_5 ==="
vsim -c -t 1ps -do "run 10us; exit" tb_top +UVM_TESTNAME=test_case_5

echo "All tests completed"