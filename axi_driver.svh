//------------------------------------------------------------------------------
// File: axi_driver.svh
// Description: AXI Master Driver (BFM) for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_DRIVER_SVH
`define AXI_DRIVER_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_driver extends uvm_driver #(axi_transaction);
  `uvm_component_utils(axi_driver)
  
  // Virtual interface handle
  virtual axi_intf vif;
  
  // Transaction and control variables
  axi_transaction current_trans;
  bit reset_detected = 0;
  
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // Build phase - get interface handle
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface from config DB
    if(!uvm_config_db#(virtual axi_intf)::get(this, "", "vif", vif))
      `uvm_fatal("AXI_DRIVER", "Virtual interface must be set for driver!")
  endfunction
  
  // Run phase - main driver process
  virtual task run_phase(uvm_phase phase);
    `uvm_info("AXI_DRIVER", "Driver starting...", UVM_MEDIUM)
    
    // 신호 초기화
    initialize_signals();
    `uvm_info("AXI_DRIVER", "Signals initialized", UVM_MEDIUM)
    
    // 메인 드라이버 루프
    forever begin
      // 리셋 조건 처리
      @(posedge vif.clk);
      `uvm_info("AXI_DRIVER", $sformatf("Clock edge, reset = %0d", vif.rst), UVM_HIGH)
      
      if(!vif.rst) begin
        `uvm_info("AXI_DRIVER", "Reset detected, waiting for reset release", UVM_MEDIUM)
        reset_detected = 1;
        initialize_signals();
        @(posedge vif.rst);
        reset_detected = 0;
        `uvm_info("AXI_DRIVER", "Reset released", UVM_MEDIUM)
        continue;
      end
      
      // 시퀀서로부터 트랜잭션 가져오기
      `uvm_info("AXI_DRIVER", "Waiting for transaction from sequencer", UVM_HIGH)
      seq_item_port.get_next_item(current_trans);
      `uvm_info("AXI_DRIVER", $sformatf("Received transaction: %s", current_trans.convert2string()), UVM_MEDIUM)
      
      // 트랜잭션 처리
      case(current_trans.trans_type)
        axi_transaction::WRITE: begin
          `uvm_info("AXI_DRIVER", "Processing WRITE transaction", UVM_MEDIUM)
          drive_write_transaction(current_trans);
        end
        axi_transaction::READ: begin
          `uvm_info("AXI_DRIVER", "Processing READ transaction", UVM_MEDIUM)
          drive_read_transaction(current_trans);
        end
      endcase
      
      `uvm_info("AXI_DRIVER", "Transaction completed", UVM_MEDIUM)
      seq_item_port.item_done();
    end
  endtask
  
  // Initialize AXI interface signals
  virtual task initialize_signals();
    // Initialize address write channel
    vif.m_drv_cb.AWID     <= 0;
    vif.m_drv_cb.AWADDR   <= 0;
    vif.m_drv_cb.AWLEN    <= 0;
    vif.m_drv_cb.AWSIZE   <= 0;
    vif.m_drv_cb.AWBURST  <= 0;
    vif.m_drv_cb.AWLOCK   <= 0;
    vif.m_drv_cb.AWCACHE  <= 0;
    vif.m_drv_cb.AWPROT   <= 0;
    vif.m_drv_cb.AWVALID  <= 0;
    
    // Initialize write data channel
    vif.m_drv_cb.WDATA    <= 0;
    vif.m_drv_cb.WSTRB    <= 0;
    vif.m_drv_cb.WLAST    <= 0;
    vif.m_drv_cb.WVALID   <= 0;
    
    // Initialize write response channel
    vif.m_drv_cb.BREADY   <= 0;
    
    // Initialize address read channel
    vif.m_drv_cb.ARID     <= 0;
    vif.m_drv_cb.ARADDR   <= 0;
    vif.m_drv_cb.ARLEN    <= 0;
    vif.m_drv_cb.ARSIZE   <= 0;
    vif.m_drv_cb.ARBURST  <= 0;
    vif.m_drv_cb.ARLOCK   <= 0;
    vif.m_drv_cb.ARCACHE  <= 0;
    vif.m_drv_cb.ARPROT   <= 0;
    vif.m_drv_cb.ARVALID  <= 0;
    
    // Initialize read data channel
    vif.m_drv_cb.RREADY   <= 0;
  endtask
  
  // Drive write transaction
  virtual task drive_write_transaction(axi_transaction trans);
    // Phase 1: Drive write address channel
    drive_write_address(trans);
    
    // Phase 2: Drive write data channel (can overlap with address phase)
    drive_write_data(trans);
    
    // Phase 3: Receive write response
    receive_write_response(trans);
  endtask
  
  // Drive write address channel
  virtual task drive_write_address(axi_transaction trans);
    `uvm_info("AXI_DRIVER", "Setting up write address channel signals", UVM_HIGH)
    
    // 주소 채널 신호 설정
    vif.m_drv_cb.AWID     <= trans.id;
    vif.m_drv_cb.AWADDR   <= trans.addr;
    vif.m_drv_cb.AWLEN    <= trans.burst_len;
    vif.m_drv_cb.AWSIZE   <= trans.burst_size;
    vif.m_drv_cb.AWBURST  <= trans.burst_type;
    vif.m_drv_cb.AWLOCK   <= trans.lock;
    vif.m_drv_cb.AWCACHE  <= trans.cache;
    vif.m_drv_cb.AWPROT   <= trans.prot;
    vif.m_drv_cb.AWVALID  <= 1;
    
    `uvm_info("AXI_DRIVER", "Waiting for AWREADY", UVM_HIGH)
    
    // AWREADY 대기 with timeout
    fork
      begin: timeout_block
        repeat(1000) @(vif.m_drv_cb);
        `uvm_error("AXI_DRIVER", "Timeout waiting for AWREADY")
      end
      
      begin: wait_for_ready
        do begin
          @(vif.m_drv_cb);
          `uvm_info("AXI_DRIVER", $sformatf("AWREADY = %0d", vif.m_drv_cb.AWREADY), UVM_HIGH)
          if(!vif.rst) break;
        end while(!vif.m_drv_cb.AWREADY);
      end
    join_any
    disable fork;
    
    `uvm_info("AXI_DRIVER", "AWREADY received", UVM_HIGH)
    
    // 주소 채널 신호 클리어
    vif.m_drv_cb.AWVALID  <= 0;
    `uvm_info("AXI_DRIVER", "Write address phase completed", UVM_MEDIUM)
  endtask
  
  // Drive write data channel
  virtual task drive_write_data(axi_transaction trans);
    // Send burst data
    `uvm_info("AXI_DRIVER", $sformatf("Driving %0d data beats", trans.burst_len+1), UVM_MEDIUM)
    
    for(int i = 0; i <= trans.burst_len; i++) begin
      // Setup data channel signals
      vif.m_drv_cb.WDATA   <= trans.data[i];
      vif.m_drv_cb.WSTRB   <= trans.strb[i];
      vif.m_drv_cb.WLAST   <= (i == trans.burst_len);
      vif.m_drv_cb.WVALID  <= 1;
      
      // Wait for WREADY with proper error handling
      fork
        begin: timeout_block
          repeat(1000) begin // Increased timeout
            @(vif.m_drv_cb);
            if(vif.m_drv_cb.WREADY) disable timeout_block;
          end
          `uvm_error("AXI_DRIVER", $sformatf("Timeout waiting for WREADY on beat %0d", i+1))
          // Don't proceed to next beat on timeout, just exit the transaction
          return;
        end
        
        begin: wait_for_ready
          do begin
            @(vif.m_drv_cb);
            if(!vif.rst) begin
              `uvm_info("AXI_DRIVER", "Reset detected during data phase", UVM_MEDIUM)
              return; // Exit on reset
            end
          end while(!vif.m_drv_cb.WREADY);
          disable timeout_block;
        end
      join
    end
    
    // Clear data channel signals
    vif.m_drv_cb.WVALID  <= 0;
    vif.m_drv_cb.WLAST   <= 0;
    `uvm_info("AXI_DRIVER", "Write data phase completed", UVM_MEDIUM)
  endtask
  
  // Receive write response
  virtual task receive_write_response(axi_transaction trans);
    // Set BREADY
    vif.m_drv_cb.BREADY <= 1;
    
    // Wait for BVALID
    do begin
      @(vif.m_drv_cb);
      if(!vif.rst) break;
    end while(!vif.m_drv_cb.BVALID);
    
    // Capture response
    trans.resp = new[1];
    trans.resp[0] = vif.m_drv_cb.BRESP;
    
    // Clear BREADY
    vif.m_drv_cb.BREADY <= 0;
  endtask
  
  // Drive read transaction
  virtual task drive_read_transaction(axi_transaction trans);
    // Phase 1: Drive read address channel
    drive_read_address(trans);
    
    // Phase 2: Receive read data
    receive_read_data(trans);
  endtask
  
  // Drive read address channel
  virtual task drive_read_address(axi_transaction trans);
    // Set up address channel signals
    vif.m_drv_cb.ARID     <= trans.id;
    vif.m_drv_cb.ARADDR   <= trans.addr;
    vif.m_drv_cb.ARLEN    <= trans.burst_len;
    vif.m_drv_cb.ARSIZE   <= trans.burst_size;
    vif.m_drv_cb.ARBURST  <= trans.burst_type;
    vif.m_drv_cb.ARLOCK   <= trans.lock;
    vif.m_drv_cb.ARCACHE  <= trans.cache;
    vif.m_drv_cb.ARPROT   <= trans.prot;
    vif.m_drv_cb.ARVALID  <= 1;
    
    // Wait for ARREADY
    do begin
      @(vif.m_drv_cb);
      if(!vif.rst) break;
    end while(!vif.m_drv_cb.ARREADY);
    
    // Clear address channel signals
    vif.m_drv_cb.ARVALID  <= 0;
  endtask
  
  // Receive read data
  virtual task receive_read_data(axi_transaction trans);
    // Allocate data and response arrays
    trans.data = new[trans.burst_len + 1];
    trans.resp = new[trans.burst_len + 1];
    trans.last = new[trans.burst_len + 1];
    
    // Set RREADY
    vif.m_drv_cb.RREADY <= 1;
    
    // Receive data for each burst
    for(int i = 0; i <= trans.burst_len; i++) begin
      // Wait for RVALID
      do begin
        @(vif.m_drv_cb);
        if(!vif.rst) break;
      end while(!vif.m_drv_cb.RVALID);
      
      // Capture data and response
      trans.data[i] = vif.m_drv_cb.RDATA;
      trans.resp[i] = vif.m_drv_cb.RRESP;
      trans.last[i] = vif.m_drv_cb.RLAST;
      
      // Check if RLAST is set when expected
      if((i == trans.burst_len) && !vif.m_drv_cb.RLAST)
        `uvm_error("AXI_DRIVER", "RLAST not set on last transfer");
      
      if((i != trans.burst_len) && vif.m_drv_cb.RLAST)
        `uvm_error("AXI_DRIVER", "RLAST set before last transfer");
    end
    
    // Clear RREADY
    vif.m_drv_cb.RREADY <= 0;
  endtask
  
endclass

`endif // AXI_DRIVER_SVH