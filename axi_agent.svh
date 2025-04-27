`ifndef AXI_AGENT_SVH
`define AXI_AGENT_SVH

// AXI Agent Class
// Contains driver, sequencer, and monitor for the AXI UVM environment
class axi_agent extends uvm_agent;
  
  // UVM macro declaration
  `uvm_component_utils(axi_agent)
  
  // Configuration object
  axi_config cfg;
  
  // Sequencer, driver, monitor declaration
  axi_sequencer sequencer;
  axi_driver    driver;
  axi_monitor   monitor;
  
  // TLM port - send transactions to scoreboard
  uvm_analysis_port #(axi_seq_item) analysis_port;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
    `uvm_info(get_type_name(), "AXI Agent created", UVM_HIGH)
  endfunction : new
  
  // Build phase - create components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration object
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // Create sequencer, driver, monitor
    sequencer = axi_sequencer::type_id::create("sequencer", this);
    driver = axi_driver::type_id::create("driver", this);
    monitor = axi_monitor::type_id::create("monitor", this);
    
    // Pass configuration object
    uvm_config_db#(axi_config)::set(this, "sequencer", "cfg", cfg);
    uvm_config_db#(axi_config)::set(this, "driver", "cfg", cfg);
    uvm_config_db#(axi_config)::set(this, "monitor", "cfg", cfg);
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Connect phase - connect components
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect driver and sequencer
    driver.seq_item_port.connect(sequencer.seq_item_export);
    
    // Connect monitor to analysis port (for scoreboard)
    monitor.item_collected_port.connect(analysis_port);
    
    // REMOVE THIS LINE: driver.exp_port = new("exp_port", driver);
    
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // Report phase - output agent statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "Report: AXI Agent completed", UVM_LOW)
  endfunction : report_phase
  
endclass : axi_agent

`endif // AXI_AGENT_SVH