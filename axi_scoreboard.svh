//------------------------------------------------------------------------------
// File: axi_scoreboard.svh
// Description: AXI Scoreboard for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_SCOREBOARD_SVH
`define AXI_SCOREBOARD_SVH

class axi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_scoreboard)
  
  // Analysis exports
  uvm_analysis_imp #(axi_transaction, axi_scoreboard) write_export;
  uvm_analysis_imp #(axi_transaction, axi_scoreboard) read_export;
  
  // Memory model for checking
  bit [7:0] mem[bit [63:0]];
  
  // Transaction counters
  int num_writes;
  int num_reads;
  int num_errors;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    write_export = new("write_export", this);
    read_export = new("read_export", this);
    num_writes = 0;
    num_reads = 0;
    num_errors = 0;
  endfunction
  
  // Write function - handles write transactions
  virtual function void write(axi_transaction trans);
    if(trans.trans_type == axi_transaction::WRITE)
      process_write(trans);
    else
      process_read(trans);
  endfunction
  
  // Process write transaction
  virtual function void process_write(axi_transaction trans);
    bit [63:0] addr;
    bit [7:0] data_slice;
    int bytes_per_data, addr_offset;
    
    // Calculate bytes per data transfer
    bytes_per_data = 2**trans.burst_size;
    
    // Log transaction
    `uvm_info("SCOREBOARD", $sformatf("Processing WRITE transaction: %s", trans.convert2string()), UVM_MEDIUM)
    
    // Process each data beat
    for(int beat = 0; beat <= trans.burst_len; beat++) begin
      // Calculate address for this beat based on burst type
      case(trans.burst_type)
        FIXED: addr = trans.addr; // Address remains the same
        INCR:  addr = trans.addr + (beat * bytes_per_data); // Incremental addressing
        WRAP:  begin // Wrapped addressing
          int wrap_boundary = (trans.addr / (bytes_per_data * (trans.burst_len + 1))) * 
                                (bytes_per_data * (trans.burst_len + 1));
          addr = trans.addr + (beat * bytes_per_data);
          if(addr >= wrap_boundary + (bytes_per_data * (trans.burst_len + 1)))
            addr = wrap_boundary + (addr - (wrap_boundary + (bytes_per_data * (trans.burst_len + 1))));
        end
        default: `uvm_error("SCOREBOARD", $sformatf("Invalid burst type: %s", trans.burst_type))
      endcase
      
      // Store data byte by byte according to strobe
      for(int i = 0; i < bytes_per_data; i++) begin
        addr_offset = i % bytes_per_data;
        
        // Only write if the corresponding strobe bit is set
        if(trans.strb[beat][addr_offset]) begin
          data_slice = (trans.data[beat] >> (8 * addr_offset)) & 8'hFF;
          mem[addr + addr_offset] = data_slice;
          `uvm_info("SCOREBOARD", $sformatf("Write: Addr=0x%0h, Data=0x%0h", addr + addr_offset, data_slice), UVM_HIGH)
        end
      end
    end
    
    num_writes++;
  endfunction
  
  // Process read transaction
  virtual function void process_read(axi_transaction trans);
    bit [63:0] addr;
    bit [7:0] expected_data_slice;
    bit [31:0] expected_data;
    int bytes_per_data;
    
    // Calculate bytes per data transfer
    bytes_per_data = 2**trans.burst_size;
    
    // Log transaction
    `uvm_info("SCOREBOARD", $sformatf("Processing READ transaction: %s", trans.convert2string()), UVM_MEDIUM)
    
    // Process each data beat
    for(int beat = 0; beat <= trans.burst_len; beat++) begin
      // Calculate address for this beat based on burst type
      case(trans.burst_type)
        FIXED: addr = trans.addr; // Address remains the same
        INCR:  addr = trans.addr + (beat * bytes_per_data); // Incremental addressing
        WRAP:  begin // Wrapped addressing
          int wrap_boundary = (trans.addr / (bytes_per_data * (trans.burst_len + 1))) * 
                                (bytes_per_data * (trans.burst_len + 1));
          addr = trans.addr + (beat * bytes_per_data);
          if(addr >= wrap_boundary + (bytes_per_data * (trans.burst_len + 1)))
            addr = wrap_boundary + (addr - (wrap_boundary + (bytes_per_data * (trans.burst_len + 1))));
        end
        default: `uvm_error("SCOREBOARD", $sformatf("Invalid burst type: %s", trans.burst_type))
      endcase
      
      // Construct expected data from memory
      expected_data = 0;
      for(int i = 0; i < bytes_per_data; i++) begin
        if(mem.exists(addr + i)) begin
          expected_data_slice = mem[addr + i];
        end
        else begin
          expected_data_slice = 0; // Default to 0 if address not written before
          `uvm_info("SCOREBOARD", $sformatf("Read from uninitialized address 0x%0h", addr + i), UVM_HIGH)
        end
        
        expected_data |= (expected_data_slice << (8 * i));
      end
      
      // Compare expected and actual data
      if(expected_data !== trans.data[beat]) begin
        `uvm_error("SCOREBOARD", $sformatf("Data mismatch at address 0x%0h: Expected 0x%0h, Got 0x%0h", 
                   addr, expected_data, trans.data[beat]))
        num_errors++;
      end
      else begin
        `uvm_info("SCOREBOARD", $sformatf("Data match at address 0x%0h: 0x%0h", addr, expected_data), UVM_HIGH)
      end
    end
    
    num_reads++;
  endfunction
  
  // Report phase - print statistics
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD", $sformatf("Scoreboard statistics:"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Write transactions: %0d", num_writes), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Read transactions: %0d", num_reads), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Errors detected: %0d", num_errors), UVM_LOW)
    
    if(num_errors == 0)
      `uvm_info("SCOREBOARD", "TEST PASSED: No errors detected", UVM_LOW)
    else
      `uvm_error("SCOREBOARD", $sformatf("TEST FAILED: %0d errors detected", num_errors))
  endfunction
  
endclass

`endif // AXI_SCOREBOARD_SVH