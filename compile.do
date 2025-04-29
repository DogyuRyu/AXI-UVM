# Quit any existing simulation
quit -sim

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

# Map work library
vmap work work

# 시스템에 UVM 또는 OVM 라이브러리 경로 찾기
set UVM_PATH "/package/eda/mg/questa2021.4/questasim/verilog_src/uvm-1.1d"
set OVM_PATH "/package/eda/mg/questa2021.4/questasim/verilog_src/ovm-2.1.2"

# 컴파일 시 매크로 오버라이드 설정
set OVERRIDE "+define+UVM_MACROS_SVH +define+UVM_CMDLINE_NO_DPI +define+UVM_REGEX_NO_DPI +define+UVM_NO_DPI"

# OVM에서 UVM으로 변환 매크로 (이는 OVM 매크로를 UVM으로 매핑)
set COMPAT_ARGS "+define+OVM_TO_UVM +define+OVM_MLK_RECORD_POLICY"

# UVM 패키지 컴파일 
vlog -sv $OVERRIDE +incdir+$UVM_PATH/src $UVM_PATH/src/uvm_pkg.sv

# 디자인 파일 컴파일
vlog -sv +incdir+$UVM_PATH/src design.sv

# 테스트벤치 파일 컴파일 - 모두 UVM 및 OVM 패스 포함
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src interface.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src transaction.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src sequencer.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src driver.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src monitor.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src agent.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src scoreboard.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src subscriber.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src environment.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src sequence.sv
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src test.sv

# 최종적으로 톱 모듈 컴파일
vlog -sv $OVERRIDE $COMPAT_ARGS +incdir+$UVM_PATH/src +incdir+$OVM_PATH/src testbench.sv

echo "Compilation completed"