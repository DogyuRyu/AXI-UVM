//------------------------------------------------------------------------------
// File: axi_agent.svh
// Description: AXI Agent for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_AGENT_SVH
`define AXI_AGENT_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_agent extends uvm_agent;
  `uvm_component_utils(axi_agent)
  
  // Agent components
  axi_sequencer      sequencer;
  axi_driver         driver;
  axi_monitor        monitor;
  
  // Configuration
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  // Analysis port
  uvm_analysis_port #(axi_transaction) write_port;
  uvm_analysis_port #(axi_transaction) read_port;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create the monitor (always present)
    monitor = axi_monitor::type_id::create("monitor", this);
    
    // Create analysis ports
    write_port = new("write_port", this);
    read_port = new("read_port", this);
    
    // Create sequencer and driver if active
    if(is_active == UVM_ACTIVE) begin
      sequencer = axi_sequencer::type_id::create("sequencer", this);
      driver = axi_driver::type_id::create("driver", this);
    end
  endfunction
  
  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect monitor ports to agent ports
    monitor.write_port.connect(write_port);
    monitor.read_port.connect(read_port);
    
    // Connect driver and sequencer if active
    if(is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
  
  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Agent-specific run phase activities can be added here
  endtask
  
endclass

`endif // AXI_AGENT_SVH