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
  rand int unsigned num_transactions = 1; // Default to 1 transaction
  rand bit [7:0] min_addr = 0;
  rand bit [7:0] max_addr = 255;
  
  function new(string name = "axi_write_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("AXI_WRITE_SEQ", $sformatf("Starting write sequence with %0d transactions", num_transactions), UVM_MEDIUM)
    
    // Force to max 2 transactions for better stability
    if (num_transactions > 2) begin
      num_transactions = 2;
      `uvm_info("AXI_WRITE_SEQ", "Limiting to 2 transactions for stability", UVM_MEDIUM)
    end
    
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
        burst_len <= 3;  // Max 4 data beats
      });
      
      `uvm_info("AXI_WRITE_SEQ", $sformatf("Randomized transaction: %s", trans.convert2string()), UVM_MEDIUM)
      finish_item(trans);
      
      // Add delay between transactions
      #5000;
      
      `uvm_info("AXI_WRITE_SEQ", "Transaction completed", UVM_HIGH)
    end
    
    `uvm_info("AXI_WRITE_SEQ", "Write sequence completed", UVM_MEDIUM)
  endtask
endclass

// Read sequence - generates read transactions
class axi_read_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_read_sequence)
  
  // Sequence parameters
  rand int unsigned num_transactions = 2;  // Default to 2 transactions
  rand bit [7:0] min_addr = 0;
  rand bit [7:0] max_addr = 255;
  
  function new(string name = "axi_read_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    `uvm_info("AXI_READ_SEQ", $sformatf("Starting read sequence with %0d transactions", num_transactions), UVM_MEDIUM)
    
    // Force to max 2 transactions for better stability
    if (num_transactions > 2) begin
      num_transactions = 2;
      `uvm_info("AXI_READ_SEQ", "Limiting to 2 transactions for stability", UVM_MEDIUM)
    }
    
    repeat(num_transactions) begin
      // Create and randomize a transaction
      trans = axi_transaction::type_id::create("trans");
      
      start_item(trans);
      assert(trans.randomize() with {
        trans_type == axi_transaction::READ;
        addr >= min_addr;
        addr <= max_addr;
        burst_len <= 2;  // Max 3 data beats for reads
      });
      
      `uvm_info("AXI_READ_SEQ", $sformatf("Randomized read transaction: %s", trans.convert2string()), UVM_MEDIUM)
      finish_item(trans);
      
      // Add delay between transactions
      #5000;
    end
    
    `uvm_info("AXI_READ_SEQ", "Read sequence completed", UVM_MEDIUM)
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
    `uvm_info("AXI_BURST_WRITE_SEQ", $sformatf("Starting burst write sequence with %0d transactions", num_transactions), UVM_MEDIUM)
    
    // Force to max 2 transactions for better stability
    if (num_transactions > 2) begin
      num_transactions = 2;
      `uvm_info("AXI_BURST_WRITE_SEQ", "Limiting to 2 transactions for stability", UVM_MEDIUM)
    end
    repeat(num_transactions) begin
            // Create and randomize a transaction with specific burst type
            trans = axi_transaction::type_id::create("trans");
            
            start_item(trans);
            assert(trans.randomize() with {
                trans_type == axi_transaction::WRITE;
                addr >= min_addr;
                addr <= max_addr;
                burst_type == burst_type_to_test;
                
                // Special handling for FIXED bursts
                if (burst_type_to_test == FIXED) {
                    burst_len == 0;  // Only one data beat for FIXED
                } else {
                    burst_len <= 2;  // Max 3 beats for other types
                }
            });
            
            `uvm_info("AXI_BURST_WRITE_SEQ", $sformatf("Randomized burst write transaction: %s", trans.convert2string()), UVM_MEDIUM)
            finish_item(trans);
            
            // Add delay between transactions
            #5000;
        end
        
        `uvm_info("AXI_BURST_WRITE_SEQ", "Burst write sequence completed", UVM_MEDIUM)
    endtask
endclass

