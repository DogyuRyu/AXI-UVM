`ifndef AXI_MONITOR_SVH
`define AXI_MONITOR_SVH

// AXI Monitor Class
// Observes and analyzes transactions on the AXI interface
class axi_monitor extends uvm_monitor;
  
  // UVM macro declaration
  `uvm_component_utils(axi_monitor)
  
  // Configuration object
  axi_config cfg;
  
  // Virtual interface - with explicit parameterization
  virtual AXI4 #(.N(8), .I(8)) vif;
  
  // Analysis port - sends transactions to scoreboard
  uvm_analysis_port #(axi_seq_item) item_collected_port;
  
  // Transaction counters
  int num_collected;
  int num_read_collected;
  int num_write_collected;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    num_collected = 0;
    num_read_collected = 0;
    num_write_collected = 0;
    item_collected_port = new("item_collected_port", this);
    `uvm_info(get_type_name(), "AXI Monitor created", UVM_HIGH)
  endfunction : new
  
  // Build phase - get configuration object
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration object
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // Get virtual interface - with explicit parameterization
    if (!uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface not found")
    end
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Run phase - start transaction monitoring
  task run_phase(uvm_phase phase);
    axi_seq_item read_trans[$];  // Queue of in-progress read transactions
    axi_seq_item write_trans[$]; // Queue of in-progress write transactions
    
    `uvm_info(get_type_name(), "Run phase started", UVM_MEDIUM)
    
    // Monitor all channels in parallel
    fork
      // Monitor read address channel
      monitor_ar_channel(read_trans);
      
      // Monitor read data channel
      monitor_r_channel(read_trans);
      
      // Monitor write address channel
      monitor_aw_channel(write_trans);
      
      // Monitor write data channel
      monitor_w_channel(write_trans);
      
      // Monitor write response channel
      monitor_b_channel(write_trans);
      
      // Monitor reset
      monitor_reset();
    join
  endtask : run_phase
  
  // Monitor read address channel
  task monitor_ar_channel(ref axi_seq_item read_trans[$]);
    axi_seq_item tr;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.ARVALID && vif.ARREADY) begin
        // Create new read transaction
        tr = axi_seq_item::type_id::create("tr");
        tr.addr = vif.ARADDR;
        tr.id = vif.ARID;
        tr.is_write = 0;  // Read transaction
        
        `uvm_info(get_type_name(), $sformatf("Detected read transaction: addr=0x%0h, id=0x%0h", 
                                           tr.addr, tr.id), UVM_HIGH)
        
        // Add to read transaction queue
        read_trans.push_back(tr);
      end
    end
  endtask : monitor_ar_channel
  
  // Monitor read data channel
  task monitor_r_channel(ref axi_seq_item read_trans[$]);
    int i;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.RVALID && vif.RREADY) begin
        // Find the corresponding read transaction by ID
        for (i = 0; i < read_trans.size(); i++) begin
          if (read_trans[i].id == vif.RID) begin
            read_trans[i].rdata = vif.RDATA;
            read_trans[i].resp = vif.RRESP;
            
            `uvm_info(get_type_name(), $sformatf("Completed read transaction: addr=0x%0h, data=0x%0h, resp=0x%0h", 
                                               read_trans[i].addr, read_trans[i].rdata, read_trans[i].resp), UVM_HIGH)
            
            // Transaction complete - send to analysis port
            if (vif.RLAST) begin
              item_collected_port.write(read_trans[i]);
              num_collected++;
              num_read_collected++;
              read_trans.delete(i);
            end
            
            break;
          end
        end
      end
    end
  endtask : monitor_r_channel
  
  // Monitor write address channel
  task monitor_aw_channel(ref axi_seq_item write_trans[$]);
    axi_seq_item tr;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.AWVALID && vif.AWREADY) begin
        // Create new write transaction
        tr = axi_seq_item::type_id::create("tr");
        tr.addr = vif.AWADDR;
        tr.id = vif.AWID;
        tr.is_write = 1;  // Write transaction
        
        `uvm_info(get_type_name(), $sformatf("Detected write transaction: addr=0x%0h, id=0x%0h", 
                                           tr.addr, tr.id), UVM_HIGH)
        
        // Add to write transaction queue
        write_trans.push_back(tr);
      end
    end
  endtask : monitor_aw_channel
  
  // Monitor write data channel
  task monitor_w_channel(ref axi_seq_item write_trans[$]);
    int i;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.WVALID && vif.WREADY) begin
        // Add data to in-progress write transaction
        if (write_trans.size() > 0) begin
          i = write_trans.size() - 1; // Most recent transaction
          write_trans[i].data = vif.WDATA;
          write_trans[i].strb = vif.WSTRB;
          
          `uvm_info(get_type_name(), $sformatf("Write data: data=0x%0h, strb=0x%0h", 
                                             write_trans[i].data, write_trans[i].strb), UVM_HIGH)
        end
      end
    end
  endtask : monitor_w_channel
  
  // Monitor write response channel
  task monitor_b_channel(ref axi_seq_item write_trans[$]);
    int i;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.BVALID && vif.BREADY) begin
        // Find the corresponding write transaction by ID
        for (i = 0; i < write_trans.size(); i++) begin
          if (write_trans[i].id == vif.BID) begin
            write_trans[i].resp = vif.BRESP;
            
            `uvm_info(get_type_name(), $sformatf("Completed write transaction: addr=0x%0h, data=0x%0h, resp=0x%0h", 
                                               write_trans[i].addr, write_trans[i].data, write_trans[i].resp), UVM_HIGH)
            
            // Transaction complete - send to analysis port
            item_collected_port.write(write_trans[i]);
            num_collected++;
            num_write_collected++;
            write_trans.delete(i);
            
            break;
          end
        end
      end
    end
  endtask : monitor_b_channel
  
  // Monitor reset
  task monitor_reset();
    forever begin
      @(negedge vif.ARESETn);
      `uvm_info(get_type_name(), "Reset detected", UVM_MEDIUM)
      
      // Wait during reset
      wait(vif.ARESETn);
      `uvm_info(get_type_name(), "Reset released", UVM_MEDIUM)
    end
  endtask : monitor_reset
  
  // Report phase - output monitor statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Report: Monitor collected %0d transactions (%0d reads, %0d writes)", 
                                       num_collected, num_read_collected, num_write_collected), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_monitor

`endif // AXI_MONITOR_SVH