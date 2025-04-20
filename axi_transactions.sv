`ifndef AXI_TRANSACTIONS_SV
`define AXI_TRANSACTIONS_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

typedef enum {AXI_READ, AXI_WRITE} axi_cmd_e;

class axi_transaction extends uvm_sequence_item;

  `uvm_object_utils(axi_transaction)  // ✅ 꼭 추가되어야 함

  rand axi_cmd_e      cmd;
  rand bit [31:0]     addr;
  rand bit [31:0]     data;
  rand bit [3:0]      wstrb;
  rand bit [2:0]      prot;
       bit [31:0]     rdata;
       bit [1:0]      resp;

  constraint wstrb_valid { wstrb inside {[4'b0001:4'b1111]}; }

  function new(string name = "axi_transaction");
    super.new(name);
  endfunction

  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("cmd",   int'(cmd), $bits(cmd), UVM_DEC);
    printer.print_field("addr", addr, $bits(addr), UVM_HEX);
    printer.print_field("data", data, $bits(data), UVM_HEX);
    printer.print_field("wstrb", wstrb, $bits(wstrb), UVM_BIN);
    printer.print_field("prot", prot, $bits(prot), UVM_BIN);
    printer.print_field("rdata", rdata, $bits(rdata), UVM_HEX);
    printer.print_field("resp", resp, $bits(resp), UVM_DEC);
  endfunction

endclass

`endif
