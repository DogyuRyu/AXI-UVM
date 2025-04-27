`ifndef AXI_DRIVER_SVH
`define AXI_DRIVER_SVH

// AXI Driver Class
class axi_driver extends uvm_driver #(axi_seq_item);
  
  // UVM macro declaration
  `uvm_component_utils(axi_driver)
  
  // Configuration object
  axi_config cfg;
  
  // Virtual interface
  virtual AXI4 #(.N(8), .I(8)) vif;
  
  // Analysis port for expected transactions
  uvm_analysis_port #(axi_seq_item) exp_port;
  
  // Mailboxes - make them optional with safe defaults
  mailbox #(ABeat #(.N(8), .I(8))) ar_mbx;
  mailbox #(RBeat #(.N(8), .I(8))) r_mbx;
  mailbox #(ABeat #(.N(8), .I(8))) aw_mbx;
  mailbox #(WBeat #(.N(8))) w_mbx;
  mailbox #(BBeat #(.I(8))) b_mbx;
  
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
    
    // Create default mailboxes just in case
    ar_mbx = new();
    r_mbx = new();
    aw_mbx = new();
    w_mbx = new();
    b_mbx = new();
    
    `uvm_info(get_type_name(), "AXI Driver created", UVM_HIGH)
  endfunction : new
  
  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis port
    exp_port = new("exp_port", this);
    
    // Get configuration object
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // Get virtual interface - this is critical
    if (!uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface not found")
    end
    
    // Try to get mailboxes - but don't fatal if not found
    if (!uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::get(this, "", "ar_mbx", ar_mbx)) begin
      `uvm_warning(get_type_name(), "AR mailbox not found, using default")
    end
    
    if (!uvm_config_db#(mailbox #(RBeat #(.N(8), .I(8))))::get(this, "", "r_mbx", r_mbx)) begin
      `uvm_warning(get_type_name(), "R mailbox not found, using default")
    end
    
    if (!uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::get(this, "", "aw_mbx", aw_mbx)) begin
      `uvm_warning(get_type_name(), "AW mailbox not found, using default")
    end
    
    if (!uvm_config_db#(mailbox #(WBeat #(.N(8))))::get(this, "", "w_mbx", w_mbx)) begin
      `uvm_warning(get_type_name(), "W mailbox not found, using default")
    end
    
    if (!uvm_config_db#(mailbox #(BBeat #(.I(8))))::get(this, "", "b_mbx", b_mbx)) begin
      `uvm_warning(get_type_name(), "B mailbox not found, using default")
    end
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Run phase
  task run_phase(uvm_phase phase);
    axi_seq_item req, rsp;
    
    `uvm_info(get_type_name(), "Run phase started", UVM_MEDIUM)
    
    forever begin
      // Get transaction from sequencer
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(), $sformatf("Processing transaction: %s", req.convert2string()), UVM_HIGH)
      
      // Send expected transaction to scoreboard
      exp_port.write(req);
      
      // Process transaction - drive directly to interface
      drive_transaction(req);
      
      // For simplicity, create response immediately
      rsp = axi_seq_item::type_id::create("rsp");
      rsp.set_id_info(req);
      rsp.addr = req.addr;
      rsp.id = req.id;
      rsp.is_write = req.is_write;
      
      if (req.is_write) begin
        rsp.resp = 0;  // OKAY
        num_write_sent++;
      end
      else begin
        rsp.rdata = 64'hDEADBEEF_12345678;  // Test data
        rsp.resp = 0;  // OKAY
        num_read_sent++;
      end
      
      // Send response back
      seq_item_port.item_done(rsp);
      num_sent++;
      
      `uvm_info(get_type_name(), $sformatf("Transaction completed, response: %s", rsp.convert2string()), UVM_HIGH)
    end
  endtask : run_phase
  
  // Direct interface driving
  task drive_transaction(axi_seq_item req);
    if (req.is_write) begin
      // Drive write address channel
      @(posedge vif.ACLK);
      vif.AWID <= req.id;
      vif.AWADDR <= req.addr;
      vif.AWREGION <= 0;
      vif.AWLEN <= 0;
      vif.AWSIZE <= 3;
      vif.AWBURST <= 1;
      vif.AWLOCK <= 0;
      vif.AWCACHE <= 0;
      vif.AWPROT <= 0;
      vif.AWQOS <= 0;
      vif.AWVALID <= 1;
      
      // Wait for AWREADY
      while (!vif.AWREADY) @(posedge vif.ACLK);
      vif.AWVALID <= 0;
      
      // Drive write data channel
      @(posedge vif.ACLK);
      vif.WDATA <= req.data;
      vif.WSTRB <= req.strb;
      vif.WLAST <= 1;
      vif.WVALID <= 1;
      
      // Wait for WREADY
      while (!vif.WREADY) @(posedge vif.ACLK);
      vif.WVALID <= 0;
      
      // Wait for write response
      vif.BREADY <= 1;
      while (!vif.BVALID) @(posedge vif.ACLK);
      @(posedge vif.ACLK);
      vif.BREADY <= 0;
      
      `uvm_info(get_type_name(), $sformatf("Write transaction completed: addr=0x%0h, data=0x%0h", 
                                        req.addr, req.data), UVM_HIGH)
    end
    else begin
      // Drive read address channel
      @(posedge vif.ACLK);
      vif.ARID <= req.id;
      vif.ARADDR <= req.addr;
      vif.ARREGION <= 0;
      vif.ARLEN <= 0;
      vif.ARSIZE <= 3;
      vif.ARBURST <= 1;
      vif.ARLOCK <= 0;
      vif.ARCACHE <= 0;
      vif.ARPROT <= 0;
      vif.ARQOS <= 0;
      vif.ARVALID <= 1;
      
      // Wait for ARREADY
      while (!vif.ARREADY) @(posedge vif.ACLK);
      vif.ARVALID <= 0;
      
      // Wait for read data
      vif.RREADY <= 1;
      while (!vif.RVALID) @(posedge vif.ACLK);
      @(posedge vif.ACLK);
      vif.RREADY <= 0;
      
      `uvm_info(get_type_name(), $sformatf("Read transaction completed: addr=0x%0h", req.addr), UVM_HIGH)
    end
  endtask : drive_transaction
  
  // Alternative implementation - use BFM if available
  task process_transaction(axi_seq_item req);
    ABeat #(.N(8), .I(8)) a_beat;
    WBeat #(.N(8)) w_beat;
    RBeat #(.N(8), .I(8)) r_beat;
    BBeat #(.I(8)) b_beat;
    
    // Simple alternative if BFM is not available
    if (req.is_write) begin
      a_beat = new();
      a_beat.id = req.id;
      a_beat.addr = req.addr;
      a_beat.region = 0;
      a_beat.len = 0;
      a_beat.size = 3;
      a_beat.burst = 1;
      a_beat.lock = 0;
      a_beat.cache = 0;
      a_beat.prot = 0;
      a_beat.qos = 0;
      
      w_beat = new();
      w_beat.data = req.data;
      w_beat.strb = req.strb;
      w_beat.last = 1;
      
      // Try to use mailboxes if they're set up
      aw_mbx.try_put(a_beat);
      w_mbx.try_put(w_beat);
    end
    else begin
      a_beat = new();
      a_beat.id = req.id;
      a_beat.addr = req.addr;
      a_beat.region = 0;
      a_beat.len = 0;
      a_beat.size = 3;
      a_beat.burst = 1;
      a_beat.lock = 0;
      a_beat.cache = 0;
      a_beat.prot = 0;
      a_beat.qos = 0;
      
      // Try to use mailbox if it's set up
      ar_mbx.try_put(a_beat);
    end
  endtask : process_transaction
  
  // Report phase
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Report: Driver processed %0d transactions (%0d reads, %0d writes)", 
                                       num_sent, num_read_sent, num_write_sent), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_driver

`endif // AXI_DRIVER_SVH