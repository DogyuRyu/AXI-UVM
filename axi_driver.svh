`ifndef AXI_DRIVER_SVH
`define AXI_DRIVER_SVH

// AXI Driver Class
// Receives transactions from the sequencer and sends them to the AXI BFM
class axi_driver extends uvm_driver #(axi_seq_item);
  
  // UVM macro declaration
  `uvm_component_utils(axi_driver)
  
  // Configuration object
  axi_config cfg;
  
  // Virtual interface with explicit parameterization
  virtual AXI4 #(.N(8), .I(8)) vif;
  
  // Analysis port for expected transactions
  uvm_analysis_port #(axi_seq_item) exp_port;
  
  // Mailboxes for communication with BFM - these will be retrieved from config_db
  mailbox #(ABeat #(.N(8), .I(8))) ar_mbx;
  mailbox #(RBeat #(.N(8), .I(8))) r_mbx;
  mailbox #(ABeat #(.N(8), .I(8))) aw_mbx;
  mailbox #(WBeat #(.N(8))) w_mbx;
  mailbox #(BBeat #(.I(8))) b_mbx;
  
  // Master agent reference - to interact with BFM
  Axi4MasterAgent #(.N(8), .I(8)) agent;
  
  // Transaction counters
  int num_sent;
  int num_read_sent;
  int num_write_sent;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    num_sent = 0;
    num_read_sent = 0;
    num_write_sent = 0;
    `uvm_info(get_type_name(), "AXI Driver created", UVM_HIGH)
  endfunction : new
  
  // Build phase - get configuration object and mailboxes
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis port
    exp_port = new("exp_port", this);
    
    // Get configuration object
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // Get virtual interface
    if (!uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface not found")
    end
    
    // Get mailboxes from config_db - CRITICAL for connecting to BFM
    if (!uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::get(this, "", "ar_mbx", ar_mbx)) begin
      `uvm_fatal(get_type_name(), "Failed to get AR mailbox")
    end
    
    if (!uvm_config_db#(mailbox #(RBeat #(.N(8), .I(8))))::get(this, "", "r_mbx", r_mbx)) begin
      `uvm_fatal(get_type_name(), "Failed to get R mailbox")
    end
    
    if (!uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::get(this, "", "aw_mbx", aw_mbx)) begin
      `uvm_fatal(get_type_name(), "Failed to get AW mailbox")
    end
    
    if (!uvm_config_db#(mailbox #(WBeat #(.N(8))))::get(this, "", "w_mbx", w_mbx)) begin
      `uvm_fatal(get_type_name(), "Failed to get W mailbox")
    end
    
    if (!uvm_config_db#(mailbox #(BBeat #(.I(8))))::get(this, "", "b_mbx", b_mbx)) begin
      `uvm_fatal(get_type_name(), "Failed to get B mailbox")
    end
    
    // Get master agent
    if (!uvm_config_db#(Axi4MasterAgent #(.N(8), .I(8)))::get(this, "", "agent", agent)) begin
      `uvm_error(get_type_name(), "Failed to get agent reference, some BFM functionality may be limited")
    end
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // Run phase - process transactions
  task run_phase(uvm_phase phase);
    axi_seq_item req, rsp;
    
    `uvm_info(get_type_name(), "Run phase started", UVM_MEDIUM)
    
    forever begin
      // Get transaction from sequencer
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(), $sformatf("Processing transaction: %s", req.convert2string()), UVM_HIGH)
      
      // Send expected transaction to scoreboard
      exp_port.write(req);
      
      // Process transaction and send to BFM
      process_transaction(req);
      
      // Wait for response - for now using a simple delay
      // In a more complete implementation, wait for actual response from BFM
      if (req.is_write) begin
        BBeat #(.I(8)) b_beat;
        b_beat = new();
        b_mbx.get(b_beat);  // Wait for write response
        
        // Create response
        rsp = axi_seq_item::type_id::create("rsp");
        rsp.set_id_info(req);
        rsp.addr = req.addr;
        rsp.id = req.id;
        rsp.is_write = 1;
        rsp.resp = b_beat.resp;
        num_write_sent++;
      end
      else begin
        RBeat #(.N(8), .I(8)) r_beat;
        r_beat = new();
        r_mbx.get(r_beat);  // Wait for read response
        
        // Create response
        rsp = axi_seq_item::type_id::create("rsp");
        rsp.set_id_info(req);
        rsp.addr = req.addr;
        rsp.id = req.id;
        rsp.is_write = 0;
        rsp.rdata = r_beat.data;
        rsp.resp = r_beat.resp;
        num_read_sent++;
      end
      
      // Send response back to sequencer
      seq_item_port.item_done(rsp);
      num_sent++;
      
      `uvm_info(get_type_name(), $sformatf("Transaction completed, response: %s", rsp.convert2string()), UVM_HIGH)
    end
  endtask : run_phase
  
  // Process transaction - convert UVM transaction to BFM transaction
  task process_transaction(axi_seq_item req);
    // Declare all variables at the beginning of the task
    ABeat #(.N(8), .I(8)) aw_beat;
    WBeat #(.N(8)) w_beat;
    ABeat #(.N(8), .I(8)) ar_beat;
    
    if (req.is_write) begin
      // Create and populate AXI write address beat
      aw_beat = new();
      aw_beat.id = req.id;
      aw_beat.addr = req.addr;
      aw_beat.region = 0;
      aw_beat.len = 0;  // Single transfer
      aw_beat.size = 3; // 8 bytes (2^3)
      aw_beat.burst = 1; // INCR mode
      aw_beat.lock = 0;
      aw_beat.cache = 0;
      aw_beat.prot = 0;
      aw_beat.qos = 0;
      
      // Create and populate AXI write data beat
      w_beat = new();
      w_beat.data = req.data;
      w_beat.strb = req.strb;
      w_beat.last = 1; // Last transfer
      
      `uvm_info(get_type_name(), $sformatf("Sending write transaction to BFM: addr=0x%0h, data=0x%0h", 
                                         req.addr, req.data), UVM_HIGH)
      
      // Send to BFM via mailboxes
      aw_mbx.put(aw_beat);
      w_mbx.put(w_beat);
    end
    else begin
      // Create and populate AXI read address beat
      ar_beat = new();
      ar_beat.id = req.id;
      ar_beat.addr = req.addr;
      ar_beat.region = 0;
      ar_beat.len = 0;  // Single transfer
      ar_beat.size = 3; // 8 bytes (2^3)
      ar_beat.burst = 1; // INCR mode
      ar_beat.lock = 0;
      ar_beat.cache = 0;
      ar_beat.prot = 0;
      ar_beat.qos = 0;
      
      `uvm_info(get_type_name(), $sformatf("Sending read transaction to BFM: addr=0x%0h", 
                                         req.addr), UVM_HIGH)
      
      // Send to BFM via mailbox
      ar_mbx.put(ar_beat);
    end
  endtask : process_transaction
  
  // Report phase - output driver statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Report: Driver processed %0d transactions (%0d reads, %0d writes)", 
                                       num_sent, num_read_sent, num_write_sent), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_driver

`endif // AXI_DRIVER_SVH