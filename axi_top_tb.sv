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
  
  // Clock and reset signals - Fix initial values
  logic clk;
  logic rstn;

  // Create clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
  end
  
  // Create reset
  initial begin
    rstn = 0;
    #50;
    rstn = 1;
  end
  
  // AXI interface instantiation
  AXI4 #(.N(8), .I(8)) axi_if(.ACLK(clk), .ARESETn(rstn));
  
  // AXI internal signals 
  logic [7:0]     axi_awid;
  logic [31:0]    axi_awaddr;
  logic [3:0]     axi_awlen;
  logic [2:0]     axi_awsize;
  logic [1:0]     axi_awburst;
  logic [1:0]     axi_awlock;
  logic [3:0]     axi_awcache;
  logic [2:0]     axi_awprot;
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
  logic           axi_arvalid;
  logic           axi_arready;
  
  logic [7:0]     axi_rid;
  logic [63:0]    axi_rdata;
  logic [1:0]     axi_rresp;
  logic           axi_rlast;
  logic           axi_rvalid;
  logic           axi_rready;
  
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
  
  // Fix: Use interface adapter to connect BFM to DUT without conflicts
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
    
    // AXI signals connection
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
    
    // Fix: Don't drive system bus signals directly
    // Just passthrough memory model signals
    .sys_rdata_i(mem_rdata),
    .sys_err_i(mem_err),
    .sys_ack_i(mem_ack)
  );
  
  // Keep DUT - it's the whole point of testing!
  axi_slave #(
    .AXI_DW(64),
    .AXI_AW(32),
    .AXI_IW(8),
    .AXI_SW(8)
  ) dut (
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
  
  // UVM 테스트 시작
  initial begin
    // 가상 인터페이스 등록
    uvm_config_db#(virtual AXI4)::set(null, "uvm_test_top.env.agent.*", "vif", axi_if);
    
    // 메일박스 설정
    uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "ar_mbx", master_bfm.ARmbx);
    uvm_config_db#(mailbox #(RBeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "r_mbx", master_bfm.Rmbx);
    uvm_config_db#(mailbox #(ABeat #(.N(8), .I(8))))::set(null, "uvm_test_top.env.agent.driver", "aw_mbx", master_bfm.AWmbx);
    uvm_config_db#(mailbox #(WBeat #(.N(8))))::set(null, "uvm_test_top.env.agent.driver", "w_mbx", master_bfm.Wmbx);
    uvm_config_db#(mailbox #(BBeat #(.I(8))))::set(null, "uvm_test_top.env.agent.driver", "b_mbx", master_bfm.Bmbx);
    
    // 기준 에이전트 설정
    uvm_config_db#(Axi4MasterAgent #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent.driver", "agent", master_bfm.Agent);
    
    // 테스트 실행
    run_test("axi_single_rw_test");  // 기본 테스트 선택
  end
  
  // 시뮬레이션 완료 시간 제한
  initial begin
    #100000;  // 100us 제한
    `uvm_error("TB_TOP", "Simulation time limit exceeded")
    $finish;
  end
  
  // 추가 디버깅을 위한 파형 덤프
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, axi_top_tb);
  end
  
endmodule