//------------------------------------------------------------------------------
// File: axi_transactions.svh
// Description: AXI Transaction class for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_TRANSACTIONS_SVH
`define AXI_TRANSACTIONS_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

// AXI burst type definition
typedef enum bit[1:0] {
  FIXED = 2'b00,
  INCR  = 2'b01,
  WRAP  = 2'b10
} axi_burst_type_e;

// AXI transaction class
class axi_transaction extends uvm_sequence_item;
  // Transaction type
  typedef enum {READ, WRITE} trans_type_e;
  rand trans_type_e trans_type;

  // Common parameters
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 16;
  parameter ID_WIDTH = 8;
  parameter STRB_WIDTH = (DATA_WIDTH/8);

  // Common fields
  rand bit [ID_WIDTH-1:0]    id;
  rand bit [ADDR_WIDTH-1:0]  addr;
  rand axi_burst_type_e      burst_type;
  rand bit [2:0]             burst_size;
  rand bit [7:0]             burst_len;

  // Control signals
  rand bit                   lock;
  rand bit [3:0]             cache;
  rand bit [2:0]             prot;

  // Data fields
  rand bit [DATA_WIDTH-1:0]  data[];
  rand bit [STRB_WIDTH-1:0]  strb[];

  // Response fields
  bit [1:0]                  resp[];
  bit                        last[];

  // Registration macros
  `uvm_object_param_utils_begin(axi_transaction)
    `uvm_field_enum(trans_type_e, trans_type, UVM_ALL_ON)
    `uvm_field_int(id, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_enum(axi_burst_type_e, burst_type, UVM_ALL_ON)
    `uvm_field_int(burst_size, UVM_ALL_ON)
    `uvm_field_int(burst_len, UVM_ALL_ON)
    `uvm_field_int(lock, UVM_ALL_ON)
    `uvm_field_int(cache, UVM_ALL_ON)
    `uvm_field_int(prot, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
    `uvm_field_array_int(strb, UVM_ALL_ON)
    `uvm_field_array_int(resp, UVM_ALL_ON)
    `uvm_field_array_int(last, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constraints
  // Burst size constraint: burst size must be less than or equal to data width
  constraint valid_size {
    burst_size <= $clog2(STRB_WIDTH);
  }

  // Data array size constraint
  constraint data_array_size {
    solve burst_len before data;
    data.size() == burst_len + 1;
    strb.size() == burst_len + 1;
  }

  // Burst type specific constraints
  constraint burst_constraints {
    if (burst_type == FIXED) {
      // Force FIXED bursts to have exactly one data beat
      burst_len == 0;
      // Control burst size for stability
      burst_size inside {0, 1, 2};
    }
    else if (burst_type == WRAP) {
      burst_len inside {1, 3, 7, 15};
      // WRAP mode address alignment requirement
      (addr % (2**burst_size * (burst_len+1))) == 0;
    }
  }

  // STRB constraint (applies only to writes)
  constraint strb_constraints {
    if (trans_type == WRITE) {
      foreach (strb[i]) {
        // For standard operation, at least one byte must be written
        strb[i] != 0;
        
        // For FIXED bursts, use full strobe (all bytes enabled)
        if (burst_type == FIXED) {
          strb[i] == {STRB_WIDTH{1'b1}};
        }
      }
    }
  }

  // Initialize response arrays in post_randomize
  function void post_randomize();
    resp = new[burst_len + 1];
    last = new[burst_len + 1];
    
    foreach (last[i]) begin
      // Set LAST signal only on the final transfer
      last[i] = (i == burst_len);
    end
    
    // Debug message for visibility
    if (burst_type == FIXED) begin
      $display("Generated FIXED burst transaction: len=%0d, size=%0d, addr=0x%0h", 
               burst_len, burst_size, addr);
    end
  endfunction

  // Constructor
  function new(string name = "axi_transaction");
    super.new(name);
  endfunction

  // String conversion function
  function string convert2string();
    string s;
    s = super.convert2string();
    s = {s, $sformatf("\nTransaction Type: %s", trans_type.name())};
    s = {s, $sformatf("\nID: 0x%0h", id)};
    s = {s, $sformatf("\nAddress: 0x%0h", addr)};
    s = {s, $sformatf("\nBurst Type: %s", burst_type.name())};
    s = {s, $sformatf("\nBurst Size: %0d", burst_size)};
    s = {s, $sformatf("\nBurst Length: %0d", burst_len)};
    
    if (data.size() > 0) begin
      s = {s, "\nData: "};
      foreach (data[i]) begin
        s = {s, $sformatf("0x%0h ", data[i])};
      end
    end
    
    return s;
  endfunction
  
endclass

`endif // AXI_TRANSACTIONS_SVH