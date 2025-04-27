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
  
  // Mailboxes for communication with BFM
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
    
    // Create default mailboxes
    ar_mbx = new();
    r_mbx = new();
    aw_mbx = new();
    w_mbx = new();
    b_mbx = new();
    
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
    
    // Try to get mailboxes - but don't fatal if not found
    void'(uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::get(this, "", "ar_mbx", ar_mbx));
    void'(uvm_config_db#(mailbox #(RBeat #(.N(8), .I(8))))::get(this, "", "r_mbx", r_mbx));
    void'(uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::get(this, "", "aw_mbx", aw_mbx));
    void'(uvm_config_db#(mailbox #(WBeat #(.N(8))))::get(this, "", "w_mbx", w_mbx));
    void'(uvm_config_db#(mailbox #(BBeat #(.I(8))))::get(this, "", "b_mbx", b_mbx));
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Run phase - process transactions
  task run_phase(uvm_phase phase);
    axi_seq_item req, rsp;
    
    `uvm_info(get_type_name(), "Run phase started", UVM_MEDIUM)
    
    forever begin
      // Get transaction from sequencer
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(), $sformatf("Processing transaction: %s", req.convert2string()), UVM_MEDIUM)
      
      // Send expected transaction to scoreboard
      exp_port.write(req);
      
      // Direct interface driving - this is critical for seeing waveform activity
      drive_transaction(req);
      
      // Create response
      rsp = axi_seq_item::type_id::create("rsp");
      rsp.set_id_info(req);
      rsp.addr = req.addr;
      rsp.id = req.id;
      rsp.is_write = req.is_write;
      
      if (req.is_write) begin
        rsp.resp = 0;  // OKAY
        num_write_sent++;
        `uvm_info(get_type_name(), $sformatf("Write transaction completed: addr=0x%0h, data=0x%0h", 
                                           req.addr, req.data), UVM_MEDIUM)
      end
      else begin
        rsp.rdata = req.is_write ? 64'hDEADBEEF_12345678 : vif.RDATA;
        rsp.resp = 0;  // OKAY
        num_read_sent++;
        `uvm_info(get_type_name(), $sformatf("Read transaction completed: addr=0x%0h, data=0x%0h", 
                                          req.addr, rsp.rdata), UVM_MEDIUM)
      end
      
      // Send response back
      seq_item_port.item_done(rsp);
      num_sent++;
      
      `uvm_info(get_type_name(), $sformatf("Transaction completed, response: %s", rsp.convert2string()), UVM_HIGH)
    end
  endtask : run_phase
  
  // Direct interface driving
  task drive_transaction(axi_seq_item req);
    bit timeout;
    int timeout_count;
    
    if (req.is_write) begin
      `uvm_info(get_type_name(), $sformatf("Driving AXI write signals: addr=0x%0h, data=0x%0h", 
                                        req.addr, req.data), UVM_MEDIUM)
                                        
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
      
      // Debug output
      `uvm_info(get_type_name(), "Waiting for AWREADY...", UVM_LOW)
      
      // Wait for AWREADY with timeout
      timeout = 1;
      timeout_count = 0;
      
      while (timeout && timeout_count < 5) begin
        @(posedge vif.ACLK);
        if (vif.AWREADY) begin
          timeout = 0;
          `uvm_info(get_type_name(), "AWREADY received", UVM_LOW)
        end
        else begin
          timeout_count++;
          `uvm_info(get_type_name(), $sformatf("Waiting for AWREADY (%0d/5)", timeout_count), UVM_LOW)
        end
      end
      
      // Simply continue after timeout
      if (timeout) begin
        `uvm_warning(get_type_name(), "AWREADY not asserted, continuing anyway")
      end
      
      vif.AWVALID <= 0;
      
      // Drive write data channel
      @(posedge vif.ACLK);
      vif.WDATA <= req.data;
      vif.WSTRB <= req.strb;
      vif.WLAST <= 1;
      vif.WVALID <= 1;
      
      // Wait for WREADY with timeout
      timeout = 1;
      timeout_count = 0;
      
      while (timeout && timeout_count < 10) begin
        @(posedge vif.ACLK);
        if (vif.WREADY) begin
          timeout = 0;
        end
        else begin
          timeout_count++;
        end
      end
      
      if (timeout) begin
        `uvm_warning(get_type_name(), "WREADY not asserted after timeout")
      end
      
      vif.WVALID <= 0;
      
      // Wait for write response
      vif.BREADY <= 1;
      
      // Wait for BVALID with timeout
      timeout = 1;
      timeout_count = 0;
      
      while (timeout && timeout_count < 10) begin
        @(posedge vif.ACLK);
        if (vif.BVALID) begin
          timeout = 0;
        end
        else begin
          timeout_count++;
        end
      end
      
      if (timeout) begin
        `uvm_warning(get_type_name(), "BVALID not asserted after timeout")
      end
      else begin
        @(posedge vif.ACLK);
      end
      
      vif.BREADY <= 0;
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("Driving AXI read signals: addr=0x%0h", req.addr), UVM_MEDIUM)
      
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
      
      // Wait for ARREADY with timeout
      timeout = 1;
      timeout_count = 0;
      
      while (timeout && timeout_count < 10) begin
        @(posedge vif.ACLK);
        if (vif.ARREADY) begin
          timeout = 0;
        end
        else begin
          timeout_count++;
        end
      end
      
      if (timeout) begin
        `uvm_warning(get_type_name(), "ARREADY not asserted after timeout")
      end
      
      vif.ARVALID <= 0;
      
      // Wait for read data
      vif.RREADY <= 1;
      
      // Wait for RVALID with timeout
      timeout = 1;
      timeout_count = 0;
      
      while (timeout && timeout_count < 10) begin
        @(posedge vif.ACLK);
        if (vif.RVALID) begin
          timeout = 0;
        end
        else begin
          timeout_count++;
        end
      end
      
      if (timeout) begin
        `uvm_warning(get_type_name(), "RVALID not asserted after timeout")
      end
      else begin
        @(posedge vif.ACLK);
      end
      
      vif.RREADY <= 0;
    end
    
    // Also pass the transaction to BFM via mailboxes when possible
    if (req.is_write) begin
      ABeat #(.N(8), .I(8)) aw_beat;
      WBeat #(.N(8)) w_beat;
      
      aw_beat = new();
      aw_beat.id = req.id;
      aw_beat.addr = req.addr;
      aw_beat.region = 0;
      aw_beat.len = 0;
      aw_beat.size = 3;
      aw_beat.burst = 1;
      aw_beat.lock = 0;
      aw_beat.cache = 0;
      aw_beat.prot = 0;
      aw_beat.qos = 0;
      
      w_beat = new();
      w_beat.data = req.data;
      w_beat.strb = req.strb;
      w_beat.last = 1;
      
      void'(aw_mbx.try_put(aw_beat));
      void'(w_mbx.try_put(w_beat));
    end
    else begin
      ABeat #(.N(8), .I(8)) ar_beat;
      
      ar_beat = new();
      ar_beat.id = req.id;
      ar_beat.addr = req.addr;
      ar_beat.region = 0;
      ar_beat.len = 0;
      ar_beat.size = 3;
      ar_beat.burst = 1;
      ar_beat.lock = 0;
      ar_beat.cache = 0;
      ar_beat.prot = 0;
      ar_beat.qos = 0;
      
      void'(ar_mbx.try_put(ar_beat));
    end
  endtask : drive_transaction
  
  // Report phase - output driver statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Report: Driver processed %0d transactions (%0d reads, %0d writes)", 
                                       num_sent, num_read_sent, num_write_sent), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_driver

`endif // AXI_DRIVER_SVH