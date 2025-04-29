# compile.do

if {[file exists work]} {
  vdel -all
}
vlib work

vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" interfaces.sv

vlog -sv +acc=npr axi_slave.v

vlog -sv +acc=npr +incdir+. -timescale "1ns/1ps" tb_top.sv

echo "Compilation Completed"