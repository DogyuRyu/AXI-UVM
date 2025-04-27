# 시뮬레이션 실행 스크립트

# 시뮬레이션 시작
vsim -t 1ps work.axi_top_tb_simple

# 시뮬레이션 로그 설정
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
log -r /*

# 파형 추가
add wave -position insertpoint sim:/axi_top_tb_simple/*
add wave -position insertpoint sim:/axi_top_tb_simple/axi_if/*

# 시뮬레이션 실행
run 10us

# 로그 메시지
echo "시뮬레이션이 완료되었습니다."