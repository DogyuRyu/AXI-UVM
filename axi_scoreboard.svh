`ifndef AXI_SCOREBOARD_SVH
`define AXI_SCOREBOARD_SVH

// AXI Scoreboard Class
// Compares expected transactions with actual transactions
class axi_scoreboard extends uvm_scoreboard;
  
  // UVM macro declaration
  `uvm_component_utils(axi_scoreboard)
  
  // Configuration object
  axi_config cfg;
  
  // TLM ports - receive transactions from driver and monitor
  uvm_analysis_imp #(axi_seq_item, axi_scoreboard) item_from_monitor;
  uvm_analysis_export #(axi_seq_item) item_from_driver_export;
  uvm_tlm_analysis_fifo #(axi_seq_item) driver_fifo;
  
  // Queue for expected transactions
  axi_seq_item exp_queue[$];
  
  // Memory model
  bit [7:0] mem[*];  // Sparse array - only stores actually accessed addresses
  
  // Statistics counters
  int num_transactions;
  int num_matches;
  int num_mismatches;
  
  // UVM verbosity setting
  int unsigned verbosity_level = UVM_MEDIUM;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_from_monitor = new("item_from_monitor", this);
    item_from_driver_export = new("item_from_driver_export", this);
    driver_fifo = new("driver_fifo", this);
    num_transactions = 0;
    num_matches = 0;
    num_mismatches = 0;
    `uvm_info(get_type_name(), "AXI Scoreboard created", UVM_HIGH)
  endfunction : new
  
  // Build phase - get configuration object
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration object
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // Connect phase - connect TLM ports
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect driver export to FIFO
    item_from_driver_export.connect(driver_fifo.analysis_export);
    
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // Run phase - process transactions
  task run_phase(uvm_phase phase);
    axi_seq_item driver_item;
    
    forever begin
      // Get expected transaction from driver
      driver_fifo.get(driver_item);
      process_driver_item(driver_item);
    end
  endtask : run_phase
  
  // Process driver transaction (expected transaction)
  function void process_driver_item(axi_seq_item item);
    axi_seq_item exp_item;
    
    // Log message
    `uvm_info(get_type_name(), $sformatf("Received expected transaction from driver: %s", item.convert2string()), verbosity_level)
    
    // Copy expected transaction
    exp_item = axi_seq_item::type_id::create("exp_item");
    exp_item.copy(item);
    
    // If write transaction, update memory
    if (item.is_write) begin
      bit [63:0] data = item.data;
      bit [7:0] strb = item.strb;
      
      // Update memory based on write strobes
      for (int i = 0; i < 8; i++) begin
        if (strb[i]) begin
          mem[item.addr + i] = data[i*8 +: 8];
          `uvm_info(get_type_name(), $sformatf("Memory write: addr=0x%0h, data[%0d]=0x%0h", 
                                             item.addr+i, i, data[i*8 +: 8]), UVM_HIGH)
        end
      end
    end
    // If read transaction, read data from memory
    else begin
      bit [63:0] data = 0;
      
      // Read 8 bytes
      for (int i = 0; i < 8; i++) begin
        if (mem.exists(item.addr + i))
          data[i*8 +: 8] = mem[item.addr + i];
        else
          data[i*8 +: 8] = 0; // Uninitialized memory treated as 0
      end
      
      exp_item.rdata = data;
      `uvm_info(get_type_name(), $sformatf("Memory read: addr=0x%0h, expected data=0x%0h", 
                                         item.addr, data), UVM_HIGH)
    end
    
    // Add expected transaction to queue
    exp_queue.push_back(exp_item);
  endfunction : process_driver_item
  
  // Receive transaction from monitor
  function void write(axi_seq_item item);
    axi_seq_item exp_item;
    bit found = 0;
    
    // Log message
    `uvm_info(get_type_name(), $sformatf("Received actual transaction from monitor: %s", item.convert2string()), verbosity_level)
    
    // Find matching expected transaction
    foreach (exp_queue[i]) begin
      if ((exp_queue[i].addr == item.addr) && (exp_queue[i].id == item.id) && 
          (exp_queue[i].is_write == item.is_write)) begin
        exp_item = exp_queue[i];
        exp_queue.delete(i);
        found = 1;
        break;
      end
    end
    
    // If no matching expected transaction found
    if (!found) begin
      `uvm_error(get_type_name(), $sformatf("Unexpected transaction detected: %s", item.convert2string()))
      num_mismatches++;
      return;
    end
    
    // Compare transactions
    num_transactions++;
    
    // For write transactions, only check response code
    if (item.is_write) begin
      if (exp_item.resp == item.resp) begin
        `uvm_info(get_type_name(), $sformatf("Write transaction match - addr=0x%0h, resp=0x%0h", 
                                          item.addr, item.resp), verbosity_level)
        num_matches++;
      end
      else begin
        `uvm_error(get_type_name(), $sformatf("Write transaction mismatch - addr=0x%0h\nExpected resp=0x%0h\nActual resp=0x%0h", 
                                          item.addr, exp_item.resp, item.resp))
        num_mismatches++;
      end
    end
    // For read transactions, check both data and response code
    else begin
      if ((exp_item.rdata == item.rdata) && (exp_item.resp == item.resp)) begin
        `uvm_info(get_type_name(), $sformatf("Read transaction match - addr=0x%0h, data=0x%0h, resp=0x%0h", 
                                          item.addr, item.rdata, item.resp), verbosity_level)
        num_matches++;
      end
      else begin
        `uvm_error(get_type_name(), $sformatf("Read transaction mismatch - addr=0x%0h\nExpected data=0x%0h, resp=0x%0h\nActual data=0x%0h, resp=0x%0h", 
                                          item.addr, exp_item.rdata, exp_item.resp, item.rdata, item.resp))
        num_mismatches++;
      end
    end
  endfunction : write
  
  // Check phase - verify pending transactions
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    
    // Check for pending expected transactions
    if (exp_queue.size() > 0) begin
      `uvm_error(get_type_name(), $sformatf("%0d expected transactions not received", exp_queue.size()))
      
      foreach (exp_queue[i]) begin
        `uvm_info(get_type_name(), $sformatf("Pending expected transaction: %s", exp_queue[i].convert2string()), UVM_LOW)
      end
    end
  endfunction : check_phase
  
  // Report phase - output scoreboard statistics
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), $sformatf("Report: Scoreboard checked %0d transactions", num_transactions), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("       %0d transactions matched", num_matches), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("       %0d transactions mismatched", num_mismatches), UVM_LOW)
    
    if (num_mismatches == 0)
      `uvm_info(get_type_name(), "TEST PASSED", UVM_NONE)
    else
      `uvm_error(get_type_name(), "TEST FAILED")
  endfunction : report_phase
  
endclass : axi_scoreboard

`endif // AXI_SCOREBOARD_SVH