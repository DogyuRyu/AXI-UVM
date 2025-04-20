if {$argc > 0} {
  set test_name [lindex $argv 0]
} else {
  set test_name "axi_single_rw_test"
}

if {$argc > 1} {
  set verbosity [lindex $argv 1]
} else {
  set verbosity "UVM_MEDIUM"
}

vsim -novopt -t 1ps -sv_lib uvm_dpi work.axi_top_tb +UVM_TESTNAME=$test_name +UVM_VERBOSITY=$verbosity -L uvm

add wave -position insertpoint sim:/axi_top_tb/*
add wave -position insertpoint sim:/axi_top_tb/axi_if/*
add wave -position insertpoint sim:/axi_top_tb/dut/*

run 100us