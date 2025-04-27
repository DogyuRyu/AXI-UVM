`ifndef AXI_ENVIRONMENT_SVH
`define AXI_ENVIRONMENT_SVH

// AXI Environment Class
// Contains agent and scoreboard for the AXI UVM environment
class axi_environment extends uvm_env;
  
  // UVM macro declaration
  `uvm_component_utils(axi_environment)
  
  // Configuration object
  axi_config cfg;
  
  // Agent and scoreboard declaration
  axi_agent      agent;
  axi_scoreboard scoreboard;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Environment created", UVM_HIGH)
  endfunction : new
  
  // Build phase - create components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create or get configuration object
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "Creating default configuration", UVM_MEDIUM)
      cfg = axi_config::type_id::create("cfg");
    end
    
    // Create agent
    agent = axi_agent::type_id::create("agent", this);
    
    // Create scoreboard
    scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
    
    // Pass configuration object
    uvm_config_db#(axi_config)::set(this, "agent", "cfg", cfg);
    uvm_config_db#(axi_config)::set(this, "scoreboard", "cfg", cfg);
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Connect phase - connect components
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect agent's monitor to scoreboard
    agent.monitor.item_collected_port.connect(scoreboard.item_from_monitor);
    
    // Create a special export in scoreboard for expected transactions from driver
    // Use transaction export and import pattern instead of direct connection
    
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // Report phase - output environment statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "Report: AXI Environment completed", UVM_LOW)
  endfunction : report_phase
  
endclass : axi_environment

`endif // AXI_ENVIRONMENT_SVH