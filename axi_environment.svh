//------------------------------------------------------------------------------
// File: axi_env.svh
// Description: AXI Test Environment for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_ENV_SVH
`define AXI_ENV_SVH

class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)
  
  // Components
  axi_agent        agent;
  axi_scoreboard   scoreboard;
  
  // Virtual interface
  virtual axi_intf vif;
  
  // Configuration
  bit has_scoreboard = 1;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create agent
    agent = axi_agent::type_id::create("agent", this);
    
    // Create scoreboard if enabled
    if(has_scoreboard) begin
      scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
    end
    
    // Get virtual interface from config DB
    if(!uvm_config_db#(virtual axi_intf)::get(this, "", "vif", vif))
      `uvm_fatal("AXI_ENV", "Virtual interface must be set for environment!")
    
    // Pass interface to agent components
    uvm_config_db#(virtual axi_intf)::set(this, "agent.*", "vif", vif);
  endfunction
  
  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect agent to scoreboard if scoreboard exists
    if(has_scoreboard) begin
      agent.write_port.connect(scoreboard.write_export);
      agent.read_port.connect(scoreboard.read_export);
    end
  endfunction
  
  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Environment-specific run phase activities can be added here
  endtask
  
endclass

`endif // AXI_ENV_SVH