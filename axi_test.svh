//------------------------------------------------------------------------------
// File: axi_test.svh
// Description: AXI Test Classes for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_TEST_SVH
`define AXI_TEST_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

// Base test class
class axi_base_test extends uvm_test;
  `uvm_component_utils(axi_base_test)
  
  // Environment
  axi_env env;
  
  // Virtual interface
  virtual axi_intf vif;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create environment
    env = axi_env::type_id::create("env", this);
    
    // Get virtual interface from config DB
    if(!uvm_config_db#(virtual axi_intf)::get(this, "", "vif", vif))
      `uvm_fatal("AXI_BASE_TEST", "Virtual interface must be set for test!")
    
    // Pass interface to environment
    uvm_config_db#(virtual axi_intf)::set(this, "env", "vif", vif);
  endfunction
  
  // End of elaboration phase
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
    // Print topology
    uvm_top.print_topology();
  endfunction
  
  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Base test doesn't start any sequences
    // Derived tests will override this to start specific sequences
  endtask
  
endclass

// Write test class - tests basic write functionality
class axi_write_test extends axi_base_test;
  `uvm_component_utils(axi_write_test)
  
  // Sequence
  axi_write_sequence write_seq;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Create and start write sequence
    write_seq = axi_write_sequence::type_id::create("write_seq");
    
    // Configure sequence parameters if needed
    write_seq.num_transactions = 20;
    
    phase.raise_objection(this);
    `uvm_info("AXI_WRITE_TEST", "Starting write test", UVM_LOW)
    
    write_seq.start(env.agent.sequencer);
    
    `uvm_info("AXI_WRITE_TEST", "Write test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
  
endclass

// Read test class - tests basic read functionality
class axi_read_test extends axi_base_test;
  `uvm_component_utils(axi_read_test)
  
  // Sequences
  axi_write_sequence write_seq;
  axi_read_sequence read_seq;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Create sequences
    write_seq = axi_write_sequence::type_id::create("write_seq");
    read_seq = axi_read_sequence::type_id::create("read_seq");
    
    // Configure sequence parameters
    write_seq.num_transactions = 10;
    read_seq.num_transactions = 10;
    
    phase.raise_objection(this);
    `uvm_info("AXI_READ_TEST", "Starting read test", UVM_LOW)
    
    // First write data, then read it
    write_seq.start(env.agent.sequencer);
    read_seq.start(env.agent.sequencer);
    
    `uvm_info("AXI_READ_TEST", "Read test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
  
endclass

// Burst test class - tests burst transfers
class axi_burst_test extends axi_base_test;
  `uvm_component_utils(axi_burst_test)
  
  // Sequences
  axi_burst_write_sequence burst_write_seq;
  axi_burst_read_sequence burst_read_seq;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Create sequences
    burst_write_seq = axi_burst_write_sequence::type_id::create("burst_write_seq");
    burst_read_seq = axi_burst_read_sequence::type_id::create("burst_read_seq");
    
    // Configure sequence parameters
    burst_write_seq.num_transactions = 5;
    burst_write_seq.burst_type_to_test = INCR; // Test incremental bursts
    
    burst_read_seq.num_transactions = 5;
    burst_read_seq.burst_type_to_test = INCR; // Test incremental bursts
    
    phase.raise_objection(this);
    `uvm_info("AXI_BURST_TEST", "Starting burst test with INCR bursts", UVM_LOW)
    
    // First write data with bursts, then read it
    burst_write_seq.start(env.agent.sequencer);
    burst_read_seq.start(env.agent.sequencer);
    
    // Now test WRAP bursts
    burst_write_seq.burst_type_to_test = WRAP;
    burst_read_seq.burst_type_to_test = WRAP;
    
    `uvm_info("AXI_BURST_TEST", "Starting burst test with WRAP bursts", UVM_LOW)
    burst_write_seq.start(env.agent.sequencer);
    burst_read_seq.start(env.agent.sequencer);
    
    `uvm_info("AXI_BURST_TEST", "Burst test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
  
endclass

// Mixed test class - tests random mixed read/write traffic
class axi_mixed_test extends axi_base_test;
  `uvm_component_utils(axi_mixed_test)
  
  // Sequence
  axi_mixed_sequence mixed_seq;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Create sequence
    mixed_seq = axi_mixed_sequence::type_id::create("mixed_seq");
    
    // Configure sequence parameters
    mixed_seq.num_transactions = 50;
    
    phase.raise_objection(this);
    `uvm_info("AXI_MIXED_TEST", "Starting mixed read/write test", UVM_LOW)
    
    mixed_seq.start(env.agent.sequencer);
    
    `uvm_info("AXI_MIXED_TEST", "Mixed test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
  
endclass

`endif // AXI_TEST_SVH