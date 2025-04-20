# 시뮬레이션 실행 스크립트

# 시뮬레이션 시작
vsim -t 1ps work.axi_top_tb

# 파형 추가
add wave -position insertpoint sim:/axi_top_tb/*
add wave -position insertpoint sim:/axi_top_tb/axi_if/*
add wave -position insertpoint sim:/axi_top_tb/dut/*

# 시뮬레이션 실행
run 100us

# 로그 메시지
echo "시뮬레이션이 완료되었습니다."