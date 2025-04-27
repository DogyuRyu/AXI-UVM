// Modified version of axi_top_tb.sv to fix multiple driver issues

`timescale 1ns/1ps
`include "uvm_macros.svh"

module axi_top_tb;
  import uvm_pkg::*;
  import pkg_Axi4Types::*;
  import pkg_Axi4Agent::*;
  import pkg_Axi4Driver::*;
  
  // UVM component includes
  `include "axi_sequence.svh"
  `include "axi_sequencer.svh"
  `include "axi_driver.svh"
  `include "axi_monitor.svh"
  `include "axi_scoreboard.svh"
  `include "axi_agent.svh"
  `include "axi_environment.svh"
  `include "axi_test.svh"
  
  // Clock and reset signals - FIX: Remove initial values here
  logic clk;
  logic rstn;

  // Create clock
  initial begin
    clk = 0;         // Initialize here instead
    forever #5 clk = ~clk;  // 100MHz clock
  end
  
  // Create reset
  initial begin
    rstn = 0;        // Initialize here
    #50;
    rstn = 1;
  end
  
  // AXI interface instantiation
  AXI4 #(.N(8), .I(8)) axi_if(.ACLK(clk), .ARESETn(rstn));
  
  // AXI internal signals
  logic [7:0]     axi_awid;
  logic [31:0]    axi_awaddr;
  // ... other AXI signals...
  
  // System interface signals - for memory model
  logic [31:0]    sys_addr;
  logic [63:0]    sys_wdata;
  logic [7:0]     sys_sel;
  logic           sys_wen;
  logic           sys_ren;
  logic [63:0]    mem_rdata;  // Memory model output
  logic           mem_ack;    // Memory model output
  logic           mem_err;    // Memory model output
  
  // BFM instantiation
  Axi4MasterBFM #(.N(8), .I(8)) master_bfm(axi_if);
  
  // FIX: Use only one of these modules to avoid signal conflicts
  // Option 1: Keep interface adapter, comment out direct DUT
  axi_interface_adapter #(
    .AXI_DW(64),
    .AXI_AW(32),
    .AXI_IW(8),
    .AXI_SW(8)
  ) adapter (
    .bfm_intf(axi_if),
    
    // global signals
    .axi_clk_i(clk),
    .axi_rstn_i(rstn),
    
    // AXI signals
    .axi_awid_i(axi_awid),
    .axi_awaddr_i(axi_awaddr),
    // ... other AXI signals...
    
    // System bus signals
    .sys_addr_o(sys_addr),
    .sys_wdata_o(sys_wdata),
    .sys_sel_o(sys_sel),
    .sys_wen_o(sys_wen),
    .sys_ren_o(sys_ren),
    .sys_rdata_i(mem_rdata),
    .sys_err_i(mem_err),
    .sys_ack_i(mem_ack)
  );
  
  // FIX: Comment out DUT or use it through adapter
  /*
  axi_slave #(
    .AXI_DW(64),
    .AXI_AW(32),
    .AXI_IW(8),
    .AXI_SW(8)
  ) dut (
    // ... connections ...
  );
  */
  
  // Memory model (simple RAM)
  reg [63:0] memory [0:1023];  
  
  // Memory model initialization
  initial begin
    for (int i = 0; i < 1024; i++) begin
      memory[i] = 64'h0;
    end
  end
  
  // Memory access logic
  always @(posedge clk) begin
    if (!rstn) begin
      mem_rdata <= 64'h0;
      mem_ack <= 1'b0;
      mem_err <= 1'b0;
    end
    else begin
      // Handle read operations
      if (sys_ren) begin
        mem_rdata <= memory[sys_addr[11:3]];  // 8-byte addressing
        mem_ack <= 1'b1;
      end
      // Handle write operations
      else if (sys_wen) begin
        // Selective write based on strobes
        for (int i = 0; i < 8; i++) begin
          if (sys_sel[i])
            memory[sys_addr[11:3]][i*8 +: 8] <= sys_wdata[i*8 +: 8];
        end
        mem_ack <= 1'b1;
      end
      else begin
        mem_ack <= 1'b0;
      end
    end
  end
  
  // UVM test start
  initial begin
    // Register virtual interface
    uvm_config_db#(virtual AXI4)::set(null, "uvm_test_top.env.agent.*", "vif", axi_if);
    
    // Set up mailboxes
    uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "ar_mbx", master_bfm.ARmbx);
    uvm_config_db#(mailbox #(RBeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "r_mbx", master_bfm.Rmbx);
    uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "aw_mbx", master_bfm.AWmbx);
    uvm_config_db#(mailbox #(WBeat #(.N(8))))::set(null, "uvm_test_top.env.agent.driver", "w_mbx", master_bfm.Wmbx);
    uvm_config_db#(mailbox #(BBeat #(.I(8))))::set(null, "uvm_test_top.env.agent.driver", "b_mbx", master_bfm.Bmbx);
    
    // Set reference agent
    uvm_config_db#(Axi4MasterAgent #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent.driver", "agent", master_bfm.Agent);
    
    // Run test
    run_test("axi_single_rw_test");
  end
  
  // Simulation time limit
  initial begin
    #100000;
    `uvm_error("TB_TOP", "Simulation time limit exceeded")
    $finish;
  end
  
  // Waveform dump for debugging
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, axi_top_tb);
  end
  
endmodule