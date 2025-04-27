# compile.do - Updated with +acc options

# Delete previous compiled files
if {[file exists work]} {
  vdel -all
}

# Create library
vlib work

# Compile interfaces and BFM related files with +acc option
vlog -sv +acc=npr interfaces.sv
vlog -sv +acc=npr Axi4Types.sv
vlog -sv +acc=npr Axi4.sv
vlog -sv +acc=npr Axi4Agents.sv
vlog -sv +acc=npr Axi4Drivers.sv
vlog -sv +acc=npr Axi4BFMs.sv

# Compile interface adapter
vlog -sv +acc=npr axi_interface_adapter.sv

# Compile DUT
vlog -sv +acc=npr axi_slave.v

# Compile UVM testbench
vlog -sv +acc=npr axi_top_tb.sv

echo "Compilation completed"