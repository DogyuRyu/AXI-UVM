//------------------------------------------------------------------------------
// File: axi_monitor.svh
// Description: AXI Monitor for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_MONITOR_SVH
`define AXI_MONITOR_SVH

class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)
  
  // Virtual interface handle
  virtual axi_intf vif;
  
  // Analysis ports
  uvm_analysis_port #(axi_transaction) write_port;
  uvm_analysis_port #(axi_transaction) read_port;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    write_port = new("write_port", this);
    read_port = new("read_port", this);
  endfunction
  
  // Build phase - get interface handle
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface from config DB
    if(!uvm_config_db#(virtual axi_intf)::get(this, "", "vif", vif))
      `uvm_fatal("AXI_MONITOR", "Virtual interface must be set for monitor!")
  endfunction
  
  // Run phase - main monitor process
  virtual task run_phase(uvm_phase phase);
    `uvm_info("AXI_MONITOR", "Monitor starting...", UVM_MEDIUM)
    
    fork
      monitor_write_transactions();
      monitor_read_transactions();
    join
  endtask
  
  // Monitor write transactions
  virtual task monitor_write_transactions();
    axi_transaction write_trans;
    bit [7:0] data_beat_count;
    int unsigned data_index;
    
    forever begin
      // Wait for AWVALID and AWREADY handshake
      @(vif.mon_cb);
      if(vif.mon_cb.AWVALID && vif.mon_cb.AWREADY) begin
        // Create transaction
        write_trans = axi_transaction::type_id::create("write_trans");
        write_trans.trans_type = axi_transaction::WRITE;
        
        // Capture address phase signals
        write_trans.id = vif.mon_cb.AWID;
        write_trans.addr = vif.mon_cb.AWADDR;
        write_trans.burst_len = vif.mon_cb.AWLEN;
        write_trans.burst_size = vif.mon_cb.AWSIZE;
        write_trans.burst_type = axi_burst_type_e'(vif.mon_cb.AWBURST);
        write_trans.lock = vif.mon_cb.AWLOCK;
        write_trans.cache = vif.mon_cb.AWCACHE;
        write_trans.prot = vif.mon_cb.AWPROT;
        
        // Allocate arrays based on burst length
        write_trans.data = new[write_trans.burst_len + 1];
        write_trans.strb = new[write_trans.burst_len + 1];
        write_trans.resp = new[1]; // Only one response for write
        
        // Reset data beat counter
        data_beat_count = 0;
        data_index = 0;
        
        // Monitor data phase
        fork : write_data_phase
          // Timeout process
          begin
            repeat(1000) @(vif.mon_cb);
            `uvm_error("AXI_MONITOR", "Timeout waiting for write data phase")
            disable write_data_phase;
          end
          
          // Data collection process
          begin
            // Loop for each data beat
            while(data_beat_count <= write_trans.burst_len) begin
              @(vif.mon_cb);
              if(vif.mon_cb.WVALID && vif.mon_cb.WREADY) begin
                // Capture data
                write_trans.data[data_index] = vif.mon_cb.WDATA;
                write_trans.strb[data_index] = vif.mon_cb.WSTRB;
                
                // Check WLAST
                if(data_beat_count == write_trans.burst_len) begin
                  if(!vif.mon_cb.WLAST)
                    `uvm_error("AXI_MONITOR", "WLAST not asserted on last data beat")
                end
                else if(vif.mon_cb.WLAST) begin
                  `uvm_warning("AXI_MONITOR", "WLAST asserted before last data beat")
                  data_beat_count = write_trans.burst_len; // Adjust to match reality
                end
                
                data_beat_count++;
                data_index++;
              end
              
              // Exit loop when all data beats are captured
              if(data_beat_count > write_trans.burst_len) break;
            end
            
            disable write_data_phase;
          end
        join
        
        // Monitor response phase
        fork : write_resp_phase
          // Timeout process
          begin
            repeat(1000) @(vif.mon_cb);
            `uvm_error("AXI_MONITOR", "Timeout waiting for write response phase")
            disable write_resp_phase;
          end
          
          // Response collection process
          begin
            @(vif.mon_cb);
            while(!(vif.mon_cb.BVALID && vif.mon_cb.BREADY)) @(vif.mon_cb);
            
            // Capture response
            write_trans.resp[0] = vif.mon_cb.BRESP;
            
            // Check ID
            if(write_trans.id != vif.mon_cb.BID)
              `uvm_error("AXI_MONITOR", $sformatf("Write response ID mismatch: Expected %0h, Got %0h", 
                         write_trans.id, vif.mon_cb.BID))
            
            disable write_resp_phase;
          end
        join
        
        // Write complete transaction to analysis port
        write_port.write(write_trans);
        `uvm_info("AXI_MONITOR", $sformatf("Captured write transaction: %s", write_trans.convert2string()), UVM_HIGH)
      end
    end
  endtask
  
  // Monitor read transactions
  virtual task monitor_read_transactions();
    axi_transaction read_trans;
    bit [7:0] data_beat_count;
    int unsigned data_index;
    
    forever begin
      // Wait for ARVALID and ARREADY handshake
      @(vif.mon_cb);
      if(vif.mon_cb.ARVALID && vif.mon_cb.ARREADY) begin
        // Create transaction
        read_trans = axi_transaction::type_id::create("read_trans");
        read_trans.trans_type = axi_transaction::READ;
        
        // Capture address phase signals
        read_trans.id = vif.mon_cb.ARID;
        read_trans.addr = vif.mon_cb.ARADDR;
        read_trans.burst_len = vif.mon_cb.ARLEN;
        read_trans.burst_size = vif.mon_cb.ARSIZE;
        read_trans.burst_type = axi_burst_type_e'(vif.mon_cb.ARBURST);
        read_trans.lock = vif.mon_cb.ARLOCK;
        read_trans.cache = vif.mon_cb.ARCACHE;
        read_trans.prot = vif.mon_cb.ARPROT;
        
        // Allocate arrays based on burst length
        read_trans.data = new[read_trans.burst_len + 1];
        read_trans.resp = new[read_trans.burst_len + 1];
        read_trans.last = new[read_trans.burst_len + 1];
        
        // Reset data beat counter
        data_beat_count = 0;
        data_index = 0;
        
        // Monitor data phase
        fork : read_data_phase
          // Timeout process
          begin
            repeat(1000) @(vif.mon_cb);
            `uvm_error("AXI_MONITOR", "Timeout waiting for read data phase")
            disable read_data_phase;
          end
          
          // Data collection process
          begin
            // Loop for each data beat
            while(data_beat_count <= read_trans.burst_len) begin
              @(vif.mon_cb);
              if(vif.mon_cb.RVALID && vif.mon_cb.RREADY) begin
                // Capture data and response
                read_trans.data[data_index] = vif.mon_cb.RDATA;
                read_trans.resp[data_index] = vif.mon_cb.RRESP;
                read_trans.last[data_index] = vif.mon_cb.RLAST;
                
                // Check RID
                if(read_trans.id != vif.mon_cb.RID)
                  `uvm_error("AXI_MONITOR", $sformatf("Read data ID mismatch: Expected %0h, Got %0h", 
                             read_trans.id, vif.mon_cb.RID))
                
                // Check RLAST
                if(data_beat_count == read_trans.burst_len) begin
                  if(!vif.mon_cb.RLAST)
                    `uvm_error("AXI_MONITOR", "RLAST not asserted on last data beat")
                end
                else if(vif.mon_cb.RLAST) begin
                  `uvm_warning("AXI_MONITOR", "RLAST asserted before last data beat")
                  data_beat_count = read_trans.burst_len; // Adjust to match reality
                end
                
                data_beat_count++;
                data_index++;
              end
              
              // Exit loop when all data beats are captured
              if(data_beat_count > read_trans.burst_len) break;
            end
            
            disable read_data_phase;
          end
        join
        
        // Write complete transaction to analysis port
        read_port.write(read_trans);
        `uvm_info("AXI_MONITOR", $sformatf("Captured read transaction: %s", read_trans.convert2string()), UVM_HIGH)
      end
    end
  endtask
  
endclass

`endif // AXI_MONITOR_SVH