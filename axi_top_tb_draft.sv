module axi_top_tb_simple;
  // 클럭 및 리셋 신호
  bit clk;
  bit rstn;
  
  // 클럭 생성
  always #5 clk = ~clk;  // 100MHz 클럭
  
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
  
  // 시스템 인터페이스 신호
  logic [31:0]    sys_addr;
  logic [63:0]    sys_wdata;
  logic [7:0]     sys_sel;
  logic           sys_wen;
  logic           sys_ren;
  logic [63:0]    sys_rdata;
  logic           sys_err;
  logic           sys_ack;
  
  // BFM 인스턴스화
  Axi4MasterBFM #(.N(8), .I(8)) master_bfm(axi_if);
  
  // 인터페이스 어댑터 인스턴스화
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
    
    // AXI 신호 연결
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
    .sys_rdata_i(sys_rdata),
    .sys_err_i(sys_err),
    .sys_ack_i(sys_ack)
  );
  
  // DUT 인스턴스화
  axi_slave #(
    .AXI_DW(64),
    .AXI_AW(32),
    .AXI_IW(8),
    .AXI_SW(8)
  ) dut (
    // global signals
    .axi_clk_i(clk),
    .axi_rstn_i(rstn),
    
    // AXI 신호 연결
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
    .sys_rdata_i(sys_rdata),
    .sys_err_i(sys_err),
    .sys_ack_i(sys_ack)
  );
  
  // 시스템 버스 응답 생성 (메모리 모델)
  reg [63:0] memory [0:1023];  // 간단한 메모리 모델
  
  always @(posedge clk) begin
    if (rstn) begin
      // 읽기 작업 처리
      if (sys_ren) begin
        sys_rdata <= memory[sys_addr[11:3]];  // 8바이트 단위 주소
        sys_ack <= 1;
      end
      // 쓰기 작업 처리
      else if (sys_wen) begin
        // 스트로브에 따라 선택적으로 쓰기
        for (int i = 0; i < 8; i++) begin
          if (sys_sel[i])
            memory[sys_addr[11:3]][i*8 +: 8] <= sys_wdata[i*8 +: 8];
        end
        sys_ack <= 1;
      end
      else begin
        sys_ack <= 0;
      end
      
      // 오류 없음
      sys_err <= 0;
    end
  end
  
  // 기본 테스트 시퀀스
  initial begin
    // 기본 지연
    #100;
    
    // 메모리에 데이터 쓰기
    master_bfm.ARmbx.put(createARBeat(0, 32'h1000));
    #1000;
    
    // 간단한 쓰기 트랜잭션
    master_bfm.AWmbx.put(createAWBeat(0, 32'h2000));
    master_bfm.Wmbx.put(createWBeat(64'hDEADBEEF12345678, 8'hFF, 1));
    #1000;
    
    // 메모리에서 데이터 읽기
    master_bfm.ARmbx.put(createARBeat(1, 32'h2000));
    #1000;
    
    // 시뮬레이션 종료
    $display("시뮬레이션 완료");
    $finish;
  end
  
  // 파형 생성
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, axi_top_tb_simple);
  end
  
  // 헬퍼 함수: AR 비트 생성
  function ABeat #(.N(8), .I(8)) createARBeat(bit [7:0] id, bit [31:0] addr);
    ABeat #(.N(8), .I(8)) beat;
    beat = new();
    beat.id = id;
    beat.addr = addr;
    beat.len = 0;  // 단일 전송
    beat.size = 3; // 8바이트
    beat.burst = 1; // INCR 모드
    beat.lock = 0;
    beat.cache = 0;
    beat.prot = 0;
    beat.qos = 0;
    beat.region = 0;
    return beat;
  endfunction
  
  // 헬퍼 함수: AW 비트 생성
  function ABeat #(.N(8), .I(8)) createAWBeat(bit [7:0] id, bit [31:0] addr);
    ABeat #(.N(8), .I(8)) beat;
    beat = new();
    beat.id = id;
    beat.addr = addr;
    beat.len = 0;  // 단일 전송
    beat.size = 3; // 8바이트
    beat.burst = 1; // INCR 모드
    beat.lock = 0;
    beat.cache = 0;
    beat.prot = 0;
    beat.qos = 0;
    beat.region = 0;
    return beat;
  endfunction
  
  // 헬퍼 함수: W 비트 생성
  function WBeat #(.N(8)) createWBeat(bit [63:0] data, bit [7:0] strb, bit last);
    WBeat #(.N(8)) beat;
    beat = new();
    beat.data = data;
    beat.strb = strb;
    beat.last = last;
    return beat;
  endfunction
  
endmodule