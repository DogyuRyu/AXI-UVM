if {[file exists work]} {
  vdel -all
}

vlib work

vlog -sv src/interfaces.sv
vlog -sv src/Axi4Types.sv
vlog -sv src/Axi4.sv
vlog -sv src/Axi4Agents.sv
vlog -sv src/Axi4Drivers.sv
vlog -sv src/Axi4BFMs.sv

vlog -sv axi_interface_adapter.sv

vlog -sv axi_sequence.svh
vlog -sv axi_sequencer.svh
vlog -sv axi_driver.svh
vlog -sv axi_monitor.svh
vlog -sv axi_scoreboard.svh
vlog -sv axi_agent.svh
vlog -sv axi_environment.svh
vlog -sv axi_test.svh

vlog -sv axi_slave.v

vlog -sv axi_top_tb.sv
