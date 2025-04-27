# 이전 컴파일된 파일 삭제
if {[file exists work]} {
  vdel -all
}

# 라이브러리 생성
vlib work

# 인터페이스 및 BFM 관련 파일 컴파일
vlog -sv interfaces.sv
vlog -sv Axi4Types.sv
vlog -sv Axi4.sv
vlog -sv Axi4Agents.sv
vlog -sv Axi4Drivers.sv
vlog -sv Axi4BFMs.sv

# 인터페이스 어댑터 컴파일
vlog -sv axi_interface_adapter.sv

# DUT 컴파일
vlog -sv axi_slave.v

# UVM 테스트벤치 컴파일 (UVM 라이브러리 연결)
vlog -sv axi_top_tb_simple.sv

echo "컴파일이 완료되었습니다. run.do를 실행하여 시뮬레이션을 시작하세요."