`ifndef AXI_DRIVER_SVH
`define AXI_DRIVER_SVH

// AXI Driver Class
// Receives transactions from sequencer and sends to AXI BFM
class axi_driver extends uvm_driver #(axi_seq_item);
  
  // UVM macro declaration
  `uvm_component_utils(axi_driver)
  
  // Configuration object
  axi_config cfg;
  
  // Virtual interface - with explicit parameterization
  virtual AXI4 #(.N(8), .I(8)) vif;
  
  // Analysis port for expected transactions
  uvm_analysis_port #(axi_seq_item) exp_port;
  
  // Mailboxes for BFM communication
  mailbox #(ABeat #(.N(8), .I(8))) ar_mbx;
  mailbox #(RBeat #(.N(8), .I(8))) r_mbx;
  mailbox #(ABeat #(.N(8), .I(8))) aw_mbx;
  mailbox #(WBeat #(.N(8))) w_mbx;
  mailbox #(BBeat #(.I(8))) b_mbx;
  
  // BFM Agent reference
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
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration object
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // Get virtual interface
    if (!uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface not found")
    end
    
    // Create expected transaction port - MOVED FROM CONNECT PHASE
    exp_port = new("exp_port", this);
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Connect phase - connect to BFM Agent
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Get BFM Agent
    if (!uvm_config_db#(Axi4MasterAgent #(.N(8), .I(8)))::get(this, "", "agent", agent)) begin
      `uvm_warning(get_type_name(), "BFM Agent not found, creating new instance")
      agent = new(ar_mbx, r_mbx, aw_mbx, w_mbx, b_mbx);
    end
    
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
      
      // Process transaction
      process_transaction(req);
      
      // Create response
      rsp = axi_seq_item::type_id::create("rsp");
      rsp.set_id_info(req);
      
      if (req.is_write) begin
        // Handle write response
        BBeat #(.I(8)) bb;
        b_mbx.get(bb);
        
        rsp.resp = bb.resp;
        rsp.id = bb.id;
        
        num_write_sent++;
      end
      else begin
        // Handle read response
        RBeat #(.N(8), .I(8)) rb;
        r_mbx.get(rb);
        
        rsp.rdata = rb.data;
        rsp.resp = rb.resp;
        rsp.id = rb.id;
        
        num_read_sent++;
      end
      
      // Send response
      seq_item_port.item_done(rsp);
      num_sent++;
      
      `uvm_info(get_type_name(), $sformatf("Transaction processed, response: %s", rsp.convert2string()), UVM_HIGH)
    end
  endtask : run_phase
  
  // Process transaction
  task process_transaction(axi_seq_item req);
    if (req.is_write) begin
      // Process write transaction
      ABeat #(.N(8), .I(8)) awbeat = new();
      WBeat #(.N(8)) wbeat = new();
      
      // Set address channel data
      awbeat.id = req.id;
      awbeat.addr = req.addr;
      awbeat.len = 0;  // Single transaction (no burst support)
      awbeat.size = 3; // 8 bytes (64-bit) data
      awbeat.burst = 1; // INCR burst type
      awbeat.lock = 0;
      awbeat.cache = 0;
      awbeat.prot = 0;
      awbeat.qos = 0;
      awbeat.region = 0;
      
      // Set data channel data
      wbeat.data = req.data;
      wbeat.strb = req.strb;
      wbeat.last = 1; // Last data (single transaction)
      
      // Send data to BFM
      `uvm_info(get_type_name(), $sformatf("Sending write transaction: addr=0x%0h, data=0x%0h", 
                                         req.addr, req.data), UVM_HIGH)
      aw_mbx.put(awbeat);
      w_mbx.put(wbeat);
    end
    else begin
      // Process read transaction
      ABeat #(.N(8), .I(8)) arbeat = new();
      
      // Set address channel data
      arbeat.id = req.id;
      arbeat.addr = req.addr;
      arbeat.len = 0;  // Single transaction (no burst support)
      arbeat.size = 3; // 8 bytes (64-bit) data
      arbeat.burst = 1; // INCR burst type
      arbeat.lock = 0;
      arbeat.cache = 0;
      arbeat.prot = 0;
      arbeat.qos = 0;
      arbeat.region = 0;
      
      // Send data to BFM
      `uvm_info(get_type_name(), $sformatf("Sending read transaction: addr=0x%0h", req.addr), UVM_HIGH)
      ar_mbx.put(arbeat);
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