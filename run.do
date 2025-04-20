# 시뮬레이션 실행 스크립트

# 시뮬레이션 시작
vsim work.axi_top_tb_simple

# 파형 추가
add wave -position insertpoint sim:/axi_top_tb_simple/*
add wave -position insertpoint sim:/axi_top_tb_simple/axi_if/*
add wave -position insertpoint sim:/axi_top_tb_simple/dut/*

# 시뮬레이션 실행
run 100us

# 로그 메시지
echo "시뮬레이션이 완료되었습니다."