`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_transactions.sv"

class axi_scoreboard extends uvm_component;

  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp #(axi_transaction, axi_scoreboard) imp;

  bit [31:0] expected_rdata;

  function new(string name = "axi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    imp = new("imp", this);
  endfunction

  function void write(axi_transaction tr);
    if (tr.cmd == AXI_READ) begin
      if (tr.rdata !== expected_rdata) begin
        `uvm_error("AXI_SCB", $sformatf("READ MISMATCH: got 0x%08x, expected 0x%08x", tr.rdata, expected_rdata))
      end else begin
        `uvm_info("AXI_SCB", "READ MATCH", UVM_LOW)
      end
    end
    else if (tr.cmd == AXI_WRITE) begin
      `uvm_info("AXI_SCB", $sformatf("WRITE RESPONSE: %0d", tr.resp), UVM_LOW)
    end
  endfunction

endclass

`endif // AXI_SCOREBOARD_SV
