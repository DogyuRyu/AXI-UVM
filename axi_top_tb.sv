`timescale 1ns/1ps
`include "uvm_macros.svh"

module axi_top_tb;
  import uvm_pkg::*;
  import pkg_Axi4Types::*;
  import pkg_Axi4Agent::*;
  import pkg_Axi4Driver::*;
  
  // UVM 컴포넌트 인클루드
  `include "axi_sequence.svh"
  `include "axi_sequencer.svh"
  `include "axi_driver.svh"
  `include "axi_monitor.svh"
  `include "axi_scoreboard.svh"
  `include "axi_agent.svh"
  `include "axi_environment.svh"
  `include "axi_test.svh"
  
  // 클럭 및 리셋 신호
  logic clk;
  logic rstn;

  // 클럭 생성 - 100MHz 클럭
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // 리셋 생성
  initial begin
    rstn = 0;
    #50;
    rstn = 1;
  end
  
  // AXI 인터페이스 인스턴스화
  AXI4 #(.N(8), .I(8)) axi_if(.ACLK(clk), .ARESETn(rstn));
  
  // AXI 내부 신호 선언
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
  
  // 시스템 인터페이스 신호
  logic [31:0]    sys_addr;
  logic [63:0]    sys_wdata;
  logic [7:0]     sys_sel;
  logic           sys_wen;
  logic           sys_ren;
  
  // 메모리 모델 신호
  logic [63:0]    mem_rdata_internal;  // 내부 메모리 모델 출력
  logic           mem_ack_internal;    // 내부 메모리 모델 출력
  logic           mem_err_internal;    // 내부 메모리 모델 출력
  
  // 인터페이스 어댑터 인스턴스화
  axi_interface_adapter #(
    .AXI_DW(64),
    .AXI_AW(32),
    .AXI_IW(8),
    .AXI_SW(8)
  ) adapter (
    .bfm_intf(axi_if),
    
    // 글로벌 신호
    .axi_clk_i(clk),
    .axi_rstn_i(rstn),
    
    // AXI 신호
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
    
    // 시스템 버스 출력 포트에 연결하지만 사용하지 않음
    .sys_addr_o(),
    .sys_wdata_o(),
    .sys_sel_o(),
    .sys_wen_o(),
    .sys_ren_o(),
    // 수정: 직접 메모리 신호를 사용
    .sys_rdata_i(mem_rdata_internal),
    .sys_err_i(mem_err_internal),
    .sys_ack_i(mem_ack_internal)
  );
  
  // DUT 인스턴스화
  axi_slave #(
    .AXI_DW(64),
    .AXI_AW(32),
    .AXI_IW(8),
    .AXI_SW(8)
  ) dut (
    // 글로벌 신호
    .axi_clk_i(clk),
    .axi_rstn_i(rstn),
    
    // AXI 신호
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
    
    // 시스템 버스 신호
    .sys_addr_o(sys_addr),
    .sys_wdata_o(sys_wdata),
    .sys_sel_o(sys_sel),
    .sys_wen_o(sys_wen),
    .sys_ren_o(sys_ren),
    // 수정: 직접 메모리 모델 신호에 연결
    .sys_rdata_i(mem_rdata_internal),
    .sys_err_i(mem_err_internal),
    .sys_ack_i(mem_ack_internal)
  );
  
  // 메모리 모델 - 간단한 메모리 모델
  reg [63:0] memory [0:1023];
  
  // 메모리 모델 초기화
  initial begin
    for (int i = 0; i < 1024; i++) begin
      memory[i] = 64'h0;
    end
  end
  
  // 메모리 액세스 로직
  always @(posedge clk) begin
    if (!rstn) begin
      mem_rdata_internal <= 64'h0;
      mem_ack_internal <= 1'b0;
      mem_err_internal <= 1'b0;
    end
    else begin
      // 읽기 작업 처리
      if (sys_ren) begin
        mem_rdata_internal <= memory[sys_addr[11:3]];  // 8바이트 정렬 주소
        mem_ack_internal <= 1'b1;
        mem_err_internal <= 1'b0;
      end
      // 쓰기 작업 처리
      else if (sys_wen) begin
        // 스트로브에 기반한 선택적 쓰기
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
  
  // UVM 테스트 시작
  initial begin
    // 가상 인터페이스 등록 - 명시적 매개변수화 사용
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "*", "vif", axi_if);
    
    // 특정 컴포넌트에 대해 명시적으로 설정 (추가 안전성을 위해)
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env", "vif", axi_if);
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent", "vif", axi_if);
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent.driver", "vif", axi_if);
    uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::set(null, "uvm_test_top.env.agent.monitor", "vif", axi_if);
    
    // 테스트 실행
    run_test("axi_single_rw_test");
  end
  
  // 시뮬레이션 타임아웃 제한
  initial begin
    #100000;
    `uvm_error("TB_TOP", "시뮬레이션 시간 제한 초과")
    $finish;
  end
  
  // 디버깅을 위한 웨이브폼 덤프
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, axi_top_tb);
  end
  
endmodule