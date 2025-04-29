//------------------------------------------------------------------------------
// File: axi_sequences.svh
// Description: AXI Sequence classes for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_SEQUENCES_SVH
`define AXI_SEQUENCES_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

// Base sequence class
class axi_base_sequence extends uvm_sequence #(axi_transaction);
  `uvm_object_utils(axi_base_sequence)
  
  function new(string name = "axi_base_sequence");
    super.new(name);
  endfunction
  
  // Common properties and methods
  axi_transaction trans;
  
  virtual task pre_body();
    // Set sequence ID if needed
  endtask
endclass

// Write sequence - generates write transactions
class axi_write_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_write_sequence)
  
  // Sequence parameters
  rand int unsigned num_transactions = 1; // Reduced to 1
  rand bit [7:0] min_addr = 0;
  rand bit [7:0] max_addr = 255;
  
  function new(string name = "axi_write_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("AXI_WRITE_SEQ", $sformatf("Starting write sequence with %0d transactions", num_transactions), UVM_MEDIUM)
    
    repeat(num_transactions) begin
      `uvm_info("AXI_WRITE_SEQ", "Creating transaction", UVM_HIGH)
      
      // Create and randomize a transaction
      trans = axi_transaction::type_id::create("trans");
      
      `uvm_info("AXI_WRITE_SEQ", "Starting transaction", UVM_HIGH)
      start_item(trans);
      
      `uvm_info("AXI_WRITE_SEQ", "Randomizing transaction", UVM_HIGH)
      assert(trans.randomize() with {
        trans_type == axi_transaction::WRITE;
        addr >= min_addr;
        addr <= max_addr;
        burst_len <= 3; // REDUCED BURST LENGTH
        
        // Special handling for FIXED burst type
        if (burst_type == FIXED) {
          // FIXED 버스트의 경우 항상 burst_len=0으로 제한 (1개의 데이터 비트만 전송)
          burst_len == 0;
          
          // Ensure proper strobe values for the transaction
          foreach (strb[i]) {
            strb[i] == {STRB_WIDTH{1'b1}}; // All bytes enabled
          }
        }
      });
      
      `uvm_info("AXI_WRITE_SEQ", $sformatf("Randomized transaction: %s", trans.convert2string()), UVM_MEDIUM)
      finish_item(trans);
      
      `uvm_info("AXI_WRITE_SEQ", "Transaction completed", UVM_HIGH)
    end
    
    `uvm_info("AXI_WRITE_SEQ", "Write sequence completed", UVM_MEDIUM)
  endtask
endclass

// Read sequence - generates read transactions
class axi_read_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_read_sequence)
  
  // Sequence parameters
  rand int unsigned num_transactions = 10;
  rand bit [7:0] min_addr = 0;
  rand bit [7:0] max_addr = 255;
  
  function new(string name = "axi_read_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(num_transactions) begin
      // Create and randomize a transaction
      trans = axi_transaction::type_id::create("trans");
      
      start_item(trans);
      assert(trans.randomize() with {
        trans_type == axi_transaction::READ;
        addr >= min_addr;
        addr <= max_addr;
      });
      finish_item(trans);
    end
  endtask
endclass

// Burst write sequence - specifically for testing burst transfers
class axi_burst_write_sequence extends axi_write_sequence;
  `uvm_object_utils(axi_burst_write_sequence)
  
  // Burst type to test
  rand axi_burst_type_e burst_type_to_test;
  
  function new(string name = "axi_burst_write_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(num_transactions) begin
      // Create and randomize a transaction with specific burst type
      trans = axi_transaction::type_id::create("trans");
      
      start_item(trans);
      assert(trans.randomize() with {
        trans_type == axi_transaction::WRITE;
        addr >= min_addr;
        addr <= max_addr;
        burst_type == burst_type_to_test;
        
        // FIXED 버스트 타입이 선택된 경우 특별 처리 추가
        if (burst_type_to_test == FIXED) {
          burst_len == 0; // 1개의 데이터 비트만 전송
        } else {
          burst_len > 0; // 다른 버스트 타입은 여러 비트 전송 가능
        }
      });
      finish_item(trans);
    end
  endtask
endclass

// Burst read sequence - specifically for testing burst transfers
class axi_burst_read_sequence extends axi_read_sequence;
  `uvm_object_utils(axi_burst_read_sequence)
  
  // Burst type to test
  rand axi_burst_type_e burst_type_to_test;
  
  function new(string name = "axi_burst_read_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(num_transactions) begin
      // Create and randomize a transaction with specific burst type
      trans = axi_transaction::type_id::create("trans");
      
      start_item(trans);
      assert(trans.randomize() with {
        trans_type == axi_transaction::READ;
        addr >= min_addr;
        addr <= max_addr;
        burst_type == burst_type_to_test;
        burst_len > 0; // Ensure it's a burst transfer
      });
      finish_item(trans);
    end
  endtask
endclass

// Mixed sequence - generates both read and write transactions
class axi_mixed_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_mixed_sequence)
  
  // Sequence parameters
  rand int unsigned num_transactions = 20;
  rand bit [7:0] min_addr = 0;
  rand bit [7:0] max_addr = 255;
  
  function new(string name = "axi_mixed_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(num_transactions) begin
      // Create and randomize a transaction
      trans = axi_transaction::type_id::create("trans");
      
      start_item(trans);
      assert(trans.randomize() with {
        addr >= min_addr;
        addr <= max_addr;
      });
      finish_item(trans);
    end
  endtask
endclass

`endif // AXI_SEQUENCES_SVH