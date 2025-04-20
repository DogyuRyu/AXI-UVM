# 시뮬레이션 실행 스크립트

# 인자로 테스트 이름을 받음 (기본값: axi_single_rw_test)
if {$argc > 0} {
  set test_name [lindex $argv 0]
} else {
  set test_name "axi_single_rw_test"
}

# verbosity 설정
if {$argc > 1} {
  set verbosity [lindex $argv 1]
} else {
  set verbosity "UVM_MEDIUM"
}

echo "테스트 실행: $test_name (Verbosity: $verbosity)"

# 시뮬레이션 시작
vsim -novopt -t 1ps -L mtiUvm -quiet -sv_lib mtiUvm work.axi_top_tb +UVM_TESTNAME=$test_name +UVM_VERBOSITY=$verbosity

# 파형 추가
add wave -position insertpoint sim:/axi_top_tb/*
add wave -position insertpoint sim:/axi_top_tb/axi_if/*
add wave -position insertpoint sim:/axi_top_tb/dut/*

# 시뮬레이션 실행
run 100us

# 로그 메시지
echo "시뮬레이션이 완료되었습니다."