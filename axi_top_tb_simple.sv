`timescale 1ns/1ps

module axi_top_tb_simple;
  // 클럭 및 리셋 신호
  logic clk = 0;
  logic rstn = 0;
  
  // 클럭 생성
  always #5 clk <= ~clk;  // 100MHz 클럭
  
  // 리셋 생성
  initial begin
    rstn <= 0;
    #50;
    rstn <= 1;
  end
  
  // AXI 인터페이스 인스턴스화
  AXI4 #(.N(8), .I(8)) axi_if(.ACLK(clk), .ARESETn(rstn));
  
  // BFM 인스턴스화
  Axi4MasterBFM #(.N(8), .I(8)) master_bfm(axi_if);
  
  // 기본 테스트 시퀀스
  initial begin
    import pkg_Axi4Types::*;
    
    ABeat ar_beat;
    ABeat aw_beat;
    WBeat w_beat;
    
    // 기본 지연
    #100;
    
    // 메모리에서 데이터 읽기 - ID 0, 주소 0x1000
    ar_beat = new();
    ar_beat.id = 0;
    ar_beat.addr = 32'h1000;
    ar_beat.len = 0;  // 단일 전송
    ar_beat.size = 3; // 8바이트
    ar_beat.burst = 1; // INCR 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    master_bfm.ARmbx.put(ar_beat);
    #1000;
    
    // 간단한 쓰기 트랜잭션 - ID 0, 주소 0x2000
    aw_beat = new();
    aw_beat.id = 0;
    aw_beat.addr = 32'h2000;
    aw_beat.len = 0;  // 단일 전송
    aw_beat.size = 3; // 8바이트
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'hDEADBEEF12345678;
    w_beat.strb = 8'hFF;
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
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
  
endmodule