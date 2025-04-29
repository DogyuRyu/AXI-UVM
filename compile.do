# compile.do - Simplified version

# Delete previous compiled files and create library
if {[file exists work]} {
  vdel -all
}
vlib work

# Compile all files
vlog -sv +acc=npr interfaces.sv
vlog -sv +acc=npr axi_transactions.svh
vlog -sv +acc=npr axi_sequences.svh
vlog -sv +acc=npr axi_sequencer.svh
vlog -sv +acc=npr axi_driver.svh
vlog -sv +acc=npr axi_monitor.svh
vlog -sv +acc=npr axi_scoreboard.svh
vlog -sv +acc=npr axi_agent.svh
vlog -sv +acc=npr axi_env.svh
vlog -sv +acc=npr axi_test.svh
vlog -sv +acc=npr axi_slave.v
vlog -sv +acc=npr tb_top.sv

echo "Compilation completed"