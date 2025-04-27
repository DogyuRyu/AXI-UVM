`ifndef AXI_SEQUENCER_SVH
`define AXI_SEQUENCER_SVH

// AXI Configuration class (used in sequencer and other components)
class axi_config extends uvm_object;

  // UVM macro declaration
  `uvm_object_utils(axi_config)
  
  // AXI configuration parameters
  int AXI_DW = 64;  // Data width
  int AXI_AW = 32;  // Address width
  int AXI_IW = 8;   // ID width
  int AXI_SW;       // Strobe width (automatically calculated)
  
  // Other settings
  bit has_coverage = 1;             // Enable coverage
  bit has_checks = 1;               // Enable checks
  int unsigned outstanding_req = 8; // Maximum concurrent requests
  int unsigned max_transaction_time_ns = 1000; // Maximum transaction time (ns)
  
  // Constructor
  function new(string name = "axi_config");
    super.new(name);
    // Strobe width is data width / 8
    AXI_SW = AXI_DW >> 3;
    `uvm_info(get_type_name(), "AXI configuration created", UVM_HIGH)
  endfunction : new
  
  // Convert to string function
  virtual function string convert2string();
    string s;
    s = super.convert2string();
    s = {s, $sformatf("\n AXI_DW = %0d", AXI_DW)};
    s = {s, $sformatf("\n AXI_AW = %0d", AXI_AW)};
    s = {s, $sformatf("\n AXI_IW = %0d", AXI_IW)};
    s = {s, $sformatf("\n AXI_SW = %0d", AXI_SW)};
    s = {s, $sformatf("\n has_coverage = %0d", has_coverage)};
    s = {s, $sformatf("\n has_checks = %0d", has_checks)};
    s = {s, $sformatf("\n outstanding_req = %0d", outstanding_req)};
    s = {s, $sformatf("\n max_transaction_time_ns = %0d", max_transaction_time_ns)};
    return s;
  endfunction : convert2string
  
  // Copy configuration function
  virtual function void copy_config(axi_config cfg);
    this.AXI_DW = cfg.AXI_DW;
    this.AXI_AW = cfg.AXI_AW;
    this.AXI_IW = cfg.AXI_IW;
    this.AXI_SW = cfg.AXI_SW;
    this.has_coverage = cfg.has_coverage;
    this.has_checks = cfg.has_checks;
    this.outstanding_req = cfg.outstanding_req;
    this.max_transaction_time_ns = cfg.max_transaction_time_ns;
    `uvm_info(get_type_name(), "Configuration copied", UVM_HIGH)
  endfunction : copy_config
  
endclass : axi_config

// AXI Sequencer class
// UVM sequencer for axi_seq_item transactions
class axi_sequencer extends uvm_sequencer #(axi_seq_item);
  
  // UVM macro declaration
  `uvm_component_utils(axi_sequencer)
  
  // Configuration object (configurable parameters)
  axi_config cfg;
  
  // Transaction counter
  int num_transactions;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    num_transactions = 0;
    `uvm_info(get_type_name(), "AXI Sequencer created", UVM_HIGH)
  endfunction : new
  
  // Build phase - get configuration object
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration object (if available)
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
  endfunction : build_phase
  
  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // Report phase - output sequencer statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    // FIXED: Use num_transactions instead of trying to call seq_item_export.count()
    `uvm_info(get_type_name(), $sformatf("Report: Sequencer processed %0d transactions", 
                                       num_transactions), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_sequencer

`endif // AXI_SEQUENCER_SVH