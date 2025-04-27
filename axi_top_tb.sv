`timescale 1ns/1ps
`include "uvm_macros.svh"

module axi_top_tb;
  import uvm_pkg::*;
  import pkg_Axi4Types::*;
  import pkg_Axi4Agent::*;
  import pkg_Axi4Driver::*;
  
  // Include UVM components
  `include "axi_sequence.svh"
  `include "axi_sequencer.svh"
  `include "axi_driver.svh"
  `include "axi_monitor.svh"
  `include "axi_scoreboard.svh"
  `include "axi_agent.svh"
  `include "axi_environment.svh"
  `include "axi_test.svh"
  
  // Clock and reset signals
  logic clk;
  logic rstn;

  // Clock generation - 100MHz clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Reset generation
  initial begin
    rstn = 0;
    #50;
    rstn = 1;
  end
  
  // AXI interface instantiation
  AXI4 #(.N(8), .I(8)) axi_if(.ACLK(clk), .ARESETn(rstn));
  
  // AXI internal signals declaration
  logic [7:0]     axi_awid;
  logic [31:0]    axi_awaddr;
  logic [3:0]     axi_awlen;
  logic [2:0]     axi_awsize;
  logic [1:0]     axi_awburst;
  logic [1:0]     axi_awlock;
  logic [3:0]     axi_awcache;
  logic [2:0]     axi_awprot;
  logic [3:0]     axi_awqos;  
  logic           axi_awvalid;
  logic           axi_awready;
  
  logic [7:0]     axi_wid;
  logic [63:0]    axi_wdata;
  logic [7:0]     axi_wstrb;
  logic           axi_wlast;
  logic           axi_wvalid;
  logic           axi_wready;
  
  logic [7:0]     axi_bid;
  logic [1:0]     axi_bresp;
  logic           axi_bvalid;
  logic           axi_bready;
  
  logic [7:0]     axi_arid;
  logic [31:0]    axi_araddr;
  logic [3:0]     axi_arlen;
  logic [2:0]     axi_arsize;
  logic [1:0]     axi_arburst;
  logic [1:0]     axi_arlock;
  logic [3:0]     axi_arcache;
  logic [2:0]     axi_arprot;
  logic [3:0]     axi_arqos;
  logic           axi_arvalid;
  logic           axi_arready;
  
  logic [7:0]     axi_rid;
  logic [63:0]    axi_rdata;
  logic [1:0]     axi_rresp;
  logic           axi_rlast;
  logic           axi_rvalid;
  logic           axi_rready;
  
  // System interface signals
  logic [31:0]    sys_addr;
  logic [63:0]    sys_wdata;
  logic [7:0]     sys_sel;
  logic           sys_wen;
  logic           sys_ren;
  
  // Memory model signals
  logic [63:0]    mem_rdata_internal;  // Internal memory model output
  logic           mem_ack_internal;    // Internal memory model output
  logic           mem_err_internal;    // Internal memory model output
  
  // BFM instantiation
  Axi4MasterBFM #(.N(8), .I(8)) master_bfm(axi_if);
  
  // Interface adapter instantiation
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
    .axi_awlen_i(axi_awlen),
    .axi_awsize_i(axi_awsize),
    .axi_awburst_i(axi_awburst),
    .axi_awlock_i(axi_awlock),
    .axi_awcache_i(axi_awcache),
    .axi_awprot_i(axi_awprot),
    .axi_awvalid_i(axi_awvalid),
    .axi_awready_o(axi_awready),
    
    .axi_wid_i(axi_wid),
    .axi_wdata_i(axi_wdata),
    .axi_wstrb_i(axi_wstrb),
    .axi_wlast_i(axi_wlast),
    .axi_wvalid_i(axi_wvalid),
    .axi_wready_o(axi_wready),
    
    .axi_bid_o(axi_bid),
    .axi_bresp_o(axi_bresp),
    .axi_bvalid_o(axi_bvalid),
    .axi_bready_i(axi_bready),
    
    .axi_arid_i(axi_arid),
    .axi_araddr_i(axi_araddr),
    .axi_arlen_i(axi_arlen),
    .axi_arsize_i(axi_arsize),
    .axi_arburst_i(axi_arburst),
    .axi_arlock_i(axi_arlock),
    .axi_arcache_i(axi_arcache),
    .axi_arprot_i(axi_arprot),
    .axi_arvalid_i(axi_arvalid),
    .axi_arready_o(axi_arready),
    
    .axi_rid_o(axi_rid),
    .axi_rdata_o(axi_rdata),
    .axi_rresp_o(axi_rresp),
    .axi_rlast_o(axi_rlast),
    .axi_rvalid_o(axi_rvalid),
    .axi_rready_i(axi_rready),
    
    // Connect system bus output ports but don't use them
    .sys_addr_o(),
    .sys_wdata_o(),
    .sys_sel_o(),
    .sys_wen_o(),
    .sys_ren_o(),
    // Fixed: Use direct memory signals instead of net variables
    .sys_rdata_i(mem_rdata_internal),
    .sys_err_i(mem_err_internal),
    .sys_ack_i(mem_ack_internal)
  );
  
  // DUT instantiation
  axi_slave #(
    .DATA_WIDTH(64),
    .ADDR_WIDTH(32),
    .ID_WIDTH(8),
    .STRB_WIDTH(8)
  ) dut (
    // global signals
    .clk(clk),
    .rst(~rstn),

    // AXI write address channel
    .s_axi_awid(axi_awid),
    .s_axi_awaddr(axi_awaddr),
    .s_axi_awlen(axi_awlen),
    .s_axi_awsize(axi_awsize),
    .s_axi_awburst(axi_awburst),
    .s_axi_awlock(axi_awlock),
    .s_axi_awcache(axi_awcache),
    .s_axi_awprot(axi_awprot),
    .s_axi_awvalid(axi_awvalid),
    .s_axi_awready(axi_awready),

    // AXI write data channel
    .s_axi_wdata(axi_wdata),
    .s_axi_wstrb(axi_wstrb),
    .s_axi_wlast(axi_wlast),
    .s_axi_wvalid(axi_wvalid),
    .s_axi_wready(axi_wready),

    // AXI write response channel
    .s_axi_bid(axi_bid),
    .s_axi_bresp(axi_bresp),
    .s_axi_bvalid(axi_bvalid),
    .s_axi_bready(axi_bready),

    // AXI read address channel
    .s_axi_arid(axi_arid),
    .s_axi_araddr(axi_araddr),
    .s_axi_arlen(axi_arlen),
    .s_axi_arsize(axi_arsize),
    .s_axi_arburst(axi_arburst),
    .s_axi_arlock(axi_arlock),
    .s_axi_arcache(axi_arcache),
    .s_axi_arprot(axi_arprot),
    .s_axi_arvalid(axi_arvalid),
    .s_axi_arready(axi_arready),

    // AXI read data channel
    .s_axi_rid(axi_rid),
    .s_axi_rdata(axi_rdata),
    .s_axi_rresp(axi_rresp),
    .s_axi_rlast(axi_rlast),
    .s_axi_rvalid(axi_rvalid),
    .s_axi_rready(axi_rready)
  );
  
  // Memory model - simplified memory model
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
      mem_rdata_internal <= 64'h0;
      mem_ack_internal <= 1'b0;
      mem_err_internal <= 1'b0;
    end
    else begin
      // Handle read operations
      if (sys_ren) begin
        mem_rdata_internal <= memory[sys_addr[11:3]];  // 8-byte aligned address
        mem_ack_internal <= 1'b1;
        mem_err_internal <= 1'b0;
      end
      // Handle write operations
      else if (sys_wen) begin
        // Selective write based on strobes
        for (int i = 0; i < 8; i++) begin
          if (sys_sel[i])
            memory[sys_addr[11:3]][i*8 +: 8] <= sys_wdata[i*8 +: 8];
        end
        mem_ack_internal <= 1'b1;
        mem_err_internal <= 1'b0;
      end
      else begin
        mem_ack_internal <= 1'b0;
        mem_err_internal <= 1'b0;
      end
    end
  end
  
  // Start UVM test
  initial begin
    // Register virtual interface - use explicit parameterization
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "*", "vif", axi_if);
    
    // Set for specific components explicitly (for added safety)
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env", "vif", axi_if);
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent", "vif", axi_if);
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent.driver", "vif", axi_if);
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent.monitor", "vif", axi_if);
    
    // Set mailboxes
    uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "ar_mbx", master_bfm.ARmbx);
    uvm_config_db#(mailbox #(RBeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "r_mbx", master_bfm.Rmbx);
    uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "aw_mbx", master_bfm.AWmbx);
    uvm_config_db#(mailbox #(WBeat #(.N(8))))::set(null, "uvm_test_top.env.agent.driver", "w_mbx", master_bfm.Wmbx);
    uvm_config_db#(mailbox #(BBeat #(.I(8))))::set(null, "uvm_test_top.env.agent.driver", "b_mbx", master_bfm.Bmbx);
    
    // Set master agent
    uvm_config_db#(Axi4MasterAgent #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent.driver", "agent", master_bfm.Agent);
    
    // Run test
    run_test("axi_single_rw_test");
  end
  
  // Simulation timeout limit
  initial begin
    #100000;
    `uvm_error("TB_TOP", "Simulation time limit exceeded")
    $finish;
  end
  
  // Waveform dump for additional debugging
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, axi_top_tb);
  end
  
endmodule