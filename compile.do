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

vlog -sv axi_sequence.svh
vlog -sv axi_sequencer.svh
vlog -sv axi_driver.svh
vlog -sv axi_monitor.svh
vlog -sv axi_scoreboard.svh
vlog -sv axi_agent.svh
vlog -sv axi_environment.svh
vlog -sv axi_test.svh

# DUT 컴파일
vlog -sv axi_slave.v

# UVM 테스트벤치 컴파일
vlog -sv axi_top_tb.sv

echo "컴파일이 완료되었습니다. run.do를 실행하여 시뮬레이션을 시작하세요."