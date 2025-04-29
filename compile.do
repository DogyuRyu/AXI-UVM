# Quit any existing simulation
quit -sim

# Create work library if it doesn't exist
if {![file exists work]} {
    vlib work
}

# Map work library
vmap work work

# Questa의 내장 UVM 라이브러리 사용
vlog -sv +define+UVM_HDL_NO_DPI -L mtiUvm -ntb_opts uvm

# 디자인 파일 컴파일
vlog -sv -L mtiUvm -ntb_opts uvm design.sv

# 테스트벤치 파일 컴파일 (하나씩 일관된 순서대로)
vlog -sv -L mtiUvm -ntb_opts uvm interface.sv
vlog -sv -L mtiUvm -ntb_opts uvm transaction.sv
vlog -sv -L mtiUvm -ntb_opts uvm sequencer.sv
vlog -sv -L mtiUvm -ntb_opts uvm driver.sv
vlog -sv -L mtiUvm -ntb_opts uvm monitor.sv
vlog -sv -L mtiUvm -ntb_opts uvm agent.sv
vlog -sv -L mtiUvm -ntb_opts uvm scoreboard.sv
vlog -sv -L mtiUvm -ntb_opts uvm subscriber.sv
vlog -sv -L mtiUvm -ntb_opts uvm environment.sv
vlog -sv -L mtiUvm -ntb_opts uvm sequence.sv
vlog -sv -L mtiUvm -ntb_opts uvm test.sv

# 마지막으로 탑 모듈 컴파일
vlog -sv -L mtiUvm -ntb_opts uvm testbench.sv

echo "Compilation completed"