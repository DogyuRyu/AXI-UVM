`ifndef AXI_SEQUENCE_SV
`define AXI_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_transactions.sv"

class axi_write_sequence extends uvm_sequence #(axi_transaction);

  `uvm_object_utils(axi_write_sequence)

  function new(string name = "axi_write_sequence");
    super.new(name);
  endfunction

  task body();
    axi_transaction tr;
    `uvm_info(get_type_name(), "Starting AXI Write Sequence", UVM_MEDIUM)

    tr = axi_transaction::type_id::create("tr", null);
    tr.cmd   = AXI_WRITE;
    tr.addr  = 32'h1000_0000;
    tr.data  = 32'hAAAAAAAA;
    tr.wstrb = 4'b1111;
    tr.prot  = 3'b000;

    start_item(tr);
    finish_item(tr);
  endtask

endclass

class axi_read_sequence extends uvm_sequence #(axi_transaction);

  `uvm_object_utils(axi_read_sequence)

  function new(string name = "axi_read_sequence");
    super.new(name);
  endfunction

  task body();
    axi_transaction tr;
    `uvm_info(get_type_name(), "Starting AXI Read Sequence", UVM_MEDIUM)

    tr = axi_transaction::type_id::create("tr", null);
    tr.cmd  = AXI_READ;
    tr.addr = 32'h1000_0000;
    tr.prot = 3'b000;

    start_item(tr);
    finish_item(tr);
  endtask

endclass

`endif // AXI_SEQUENCE_SV
