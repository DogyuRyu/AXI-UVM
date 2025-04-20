`ifndef AXI_SEQUENCER_SV
`define AXI_SEQUENCER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_transactions.sv"

class axi_sequencer extends uvm_sequencer #(axi_transaction);

  `uvm_component_utils(axi_sequencer)

  function new(string name = "axi_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif // AXI_SEQUENCER_SV
