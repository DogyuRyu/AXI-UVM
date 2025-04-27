# compile.do

# Delete previous compiled files
if {[file exists work]} {
  vdel -all
}

# Create library
vlib work

# Compile interfaces and BFM related files
vlog -sv interfaces.sv
vlog -sv Axi4Types.sv
vlog -sv Axi4.sv
vlog -sv Axi4Agents.sv
vlog -sv Axi4Drivers.sv
vlog -sv Axi4BFMs.sv

# Compile interface adapter
vlog -sv axi_interface_adapter.sv

# Compile DUT
vlog -sv axi_slave.v

# Compile simple testbench
vlog -sv axi_top_tb_simple.sv

echo "Compilation completed. Run 'run.do' to start the simulation."