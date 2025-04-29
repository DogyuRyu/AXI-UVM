//------------------------------------------------------------------------------
// File: axi_sequencer.svh
// Description: AXI Sequencer class for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_SEQUENCER_SVH
`define AXI_SEQUENCER_SVH

class axi_sequencer extends uvm_sequencer #(axi_transaction);
  `uvm_component_utils(axi_sequencer)
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Additional sequencer functionality can be added here if needed
  
endclass

`endif // AXI_SEQUENCER_SVH