`timescale 1ns/1ps

module axi_top_tb_simple;
  // 클럭 및 리셋 신호
  bit clk;  // 'bit' 타입 사용하여 초기값을 0으로 설정
  bit rstn; // 'bit' 타입 사용하여 초기값을 0으로 설정
  
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
  
  // BFM 인스턴스화
  Axi4MasterBFM #(.N(8), .I(8)) master_bfm(axi_if);
  Axi4SlaveBFM #(.N(8), .I(8)) slave_bfm(axi_if);
  
  // 테스트 단계를 추적하기 위한 열거형
  typedef enum {
    SINGLE_WRITE,
    SINGLE_READ,
    INCR_BURST_WRITE,
    INCR_BURST_READ,
    WRAP_BURST_WRITE,
    WRAP_BURST_READ,
    FIXED_BURST_WRITE,
    FIXED_BURST_READ,
    UNALIGNED_WRITE,
    UNALIGNED_READ,
    NARROW_WRITE,
    NARROW_READ,
    DIFFERENT_ID_WRITE,
    DIFFERENT_ID_READ,
    TEST_DONE
  } test_stage_t;
  
  // 기본 테스트 시퀀스
  initial begin
    import pkg_Axi4Types::*;
    
    // 테스트 단계 변수
    test_stage_t current_test;
    
    // 정확한 파라미터화된 타입으로 객체 선언
    ABeat #(.N(8), .I(8)) ar_beat;
    ABeat #(.N(8), .I(8)) aw_beat;
    WBeat #(.N(8)) w_beat;
    BBeat #(.I(8)) b_beat;
    RBeat #(.N(8), .I(8)) r_beat;
    
    // 테스트용 데이터
    bit [63:0] test_data [16];
    bit [63:0] read_data [16];
    bit [63:0] expected_data; // 미리 선언
    
    // 테스트 초기화
    current_test = SINGLE_WRITE;
    
    // 테스트 데이터 초기화
    for(int i=0; i<16; i++) begin
      test_data[i] = 64'hDEAD_BEEF_0000_0000 + i;
    end
    
    // 기본 지연
    #100;
    $display("\n=== AXI4 테스트 시작 - 시간: %0t ===", $time);
    
    //--------------------------------------------------------------------------
    // 테스트 1: 단일 쓰기/읽기 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 1: 단일 쓰기/읽기 트랜잭션 ---");
    
    // 메모리에 데이터 쓰기 - ID 0, 주소 0x1000
    aw_beat = new();
    aw_beat.id = 0;
    aw_beat.addr = 32'h1000;
    aw_beat.len = 0;  // 단일 전송
    aw_beat.size = 3; // 8바이트
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: 단일 쓰기 요청 전송 - 주소=0x%h, 데이터=0x%h", $time, aw_beat.addr, test_data[0]);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = test_data[0];
    w_beat.strb = 8'hFF;
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: 단일 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
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
    
    $display("시간 %0t: 단일 읽기 요청 전송 - 주소=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // 읽기 응답 수신 대기
    master_bfm.Rmbx.get(r_beat);
    read_data[0] = r_beat.data;
    $display("시간 %0t: 단일 읽기 응답 수신 - ID=%0d, 데이터=0x%h, 응답코드=%0d, Last=%0d", 
             $time, r_beat.id, r_beat.data, r_beat.resp, r_beat.last);
    
    // 데이터 검증
    if(read_data[0] == test_data[0])
      $display("데이터 검증 성공: 0x%h == 0x%h", read_data[0], test_data[0]);
    else
      $display("데이터 검증 실패: 0x%h != 0x%h", read_data[0], test_data[0]);
    
    //--------------------------------------------------------------------------
    // 테스트 2: INCR 버스트 쓰기/읽기 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 2: INCR 버스트 쓰기/읽기 트랜잭션 ---");
    
    // 메모리에 데이터 쓰기 - ID 1, 주소 0x2000, 버스트 길이 7 (8 전송)
    aw_beat = new();
    aw_beat.id = 1;
    aw_beat.addr = 32'h2000;
    aw_beat.len = 7;  // 8 전송
    aw_beat.size = 3; // 8바이트
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: INCR 버스트 쓰기 요청 전송 - 주소=0x%h, 길이=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 8개의 데이터 전송
    for(int i=0; i<8; i++) begin
      w_beat = new();
      w_beat.data = test_data[i];
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 7); // 마지막 전송에만 last 설정
      
      $display("시간 %0t: INCR 버스트 쓰기 데이터 전송 #%0d - 데이터=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: INCR 버스트 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
    #100;
    
    // 메모리에서 데이터 읽기 - ID 1, 주소 0x2000, 버스트 길이 7 (8 전송)
    ar_beat = new();
    ar_beat.id = 1;
    ar_beat.addr = 32'h2000;
    ar_beat.len = 7;  // 8 전송
    ar_beat.size = 3; // 8바이트
    ar_beat.burst = 1; // INCR 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: INCR 버스트 읽기 요청 전송 - 주소=0x%h, 길이=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // 8개의 데이터 수신
    for(int i=0; i<8; i++) begin
      master_bfm.Rmbx.get(r_beat);
      read_data[i] = r_beat.data;
      $display("시간 %0t: INCR 버스트 읽기 응답 수신 #%0d - 데이터=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // 데이터 검증
      if(read_data[i] == test_data[i])
        $display("데이터 검증 성공: 0x%h == 0x%h", read_data[i], test_data[i]);
      else
        $display("데이터 검증 실패: 0x%h != 0x%h", read_data[i], test_data[i]);
    end
    
    //--------------------------------------------------------------------------
    // 테스트 3: WRAP 버스트 쓰기/읽기 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 3: WRAP 버스트 쓰기/읽기 트랜잭션 ---");
    
    // 메모리에 데이터 쓰기 - ID 2, 주소 0x3010, 버스트 길이 3 (4 전송), WRAP 타입
    aw_beat = new();
    aw_beat.id = 2;
    aw_beat.addr = 32'h3010;  // 0x3010 ~ 0x3020 범위 사용
    aw_beat.len = 3;          // 4 전송
    aw_beat.size = 3;         // 8바이트
    aw_beat.burst = 2;        // WRAP 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: WRAP 버스트 쓰기 요청 전송 - 주소=0x%h, 길이=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 4개의 데이터 전송
    for(int i=0; i<4; i++) begin
      w_beat = new();
      w_beat.data = test_data[i+8];  // 다른 데이터 사용
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 3); // 마지막 전송에만 last 설정
      
      $display("시간 %0t: WRAP 버스트 쓰기 데이터 전송 #%0d - 데이터=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: WRAP 버스트 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
    #100;
    
    // 메모리에서 데이터 읽기 - ID 2, 주소 0x3010, 버스트 길이 3 (4 전송), WRAP 타입
    ar_beat = new();
    ar_beat.id = 2;
    ar_beat.addr = 32'h3010;
    ar_beat.len = 3;  // 4 전송
    ar_beat.size = 3; // 8바이트
    ar_beat.burst = 2; // WRAP 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: WRAP 버스트 읽기 요청 전송 - 주소=0x%h, 길이=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // 4개의 데이터 수신
    for(int i=0; i<4; i++) begin
      master_bfm.Rmbx.get(r_beat);
      read_data[i+8] = r_beat.data;
      $display("시간 %0t: WRAP 버스트 읽기 응답 수신 #%0d - 데이터=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // 데이터 검증
      if(read_data[i+8] == test_data[i+8])
        $display("데이터 검증 성공: 0x%h == 0x%h", read_data[i+8], test_data[i+8]);
      else
        $display("데이터 검증 실패: 0x%h != 0x%h", read_data[i+8], test_data[i+8]);
    end
    
    //--------------------------------------------------------------------------
    // 테스트 4: FIXED 버스트 쓰기/읽기 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 4: FIXED 버스트 쓰기/읽기 트랜잭션 ---");
    
    // 메모리에 데이터 쓰기 - ID 3, 주소 0x4000, 버스트 길이 3 (4 전송), FIXED 타입
    aw_beat = new();
    aw_beat.id = 3;
    aw_beat.addr = 32'h4000;
    aw_beat.len = 3;  // 4 전송
    aw_beat.size = 3; // 8바이트
    aw_beat.burst = 0; // FIXED 모드 - 같은 주소에 반복 접근
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: FIXED 버스트 쓰기 요청 전송 - 주소=0x%h, 길이=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 4개의 데이터 전송 (같은 주소에 쓰기 때문에 마지막 값만 유효)
    for(int i=0; i<4; i++) begin
      w_beat = new();
      w_beat.data = test_data[i+12];  // 다른 데이터 사용
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 3); // 마지막 전송에만 last 설정
      
      $display("시간 %0t: FIXED 버스트 쓰기 데이터 전송 #%0d - 데이터=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: FIXED 버스트 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
    #100;
    
    // 메모리에서 데이터 읽기 - ID 3, 주소 0x4000, 버스트 길이 3 (4 전송), FIXED 타입
    ar_beat = new();
    ar_beat.id = 3;
    ar_beat.addr = 32'h4000;
    ar_beat.len = 3;  // 4 전송
    ar_beat.size = 3; // 8바이트
    ar_beat.burst = 0; // FIXED 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: FIXED 버스트 읽기 요청 전송 - 주소=0x%h, 길이=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // 4개의 데이터 수신 (같은 데이터 4번 읽기)
    for(int i=0; i<4; i++) begin
      master_bfm.Rmbx.get(r_beat);
      read_data[i+12] = r_beat.data;
      $display("시간 %0t: FIXED 버스트 읽기 응답 수신 #%0d - 데이터=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // 데이터 검증 (모든 응답이 마지막으로 쓴 데이터와 같아야 함)
      if(read_data[i+12] == test_data[15])
        $display("데이터 검증 성공: 0x%h == 0x%h", read_data[i+12], test_data[15]);
      else
        $display("데이터 검증 실패: 0x%h != 0x%h", read_data[i+12], test_data[15]);
    end
    
    //--------------------------------------------------------------------------
    // 테스트 5: 다양한 사이즈의 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 5: 다양한 사이즈의 트랜잭션 ---");
    
    // 1바이트 쓰기/읽기
    aw_beat = new();
    aw_beat.id = 4;
    aw_beat.addr = 32'h5000;
    aw_beat.len = 0;  // 단일 전송
    aw_beat.size = 0; // 1바이트 (2^0)
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: 1바이트 쓰기 요청 전송 - 주소=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h12; // 첫 바이트만 유효
    w_beat.strb = 8'h01;  // 첫 바이트만 활성화
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: 1바이트 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
    #100;
    
    // 1바이트 읽기
    ar_beat = new();
    ar_beat.id = 4;
    ar_beat.addr = 32'h5000;
    ar_beat.len = 0;  // 단일 전송
    ar_beat.size = 0; // 1바이트
    ar_beat.burst = 1; // INCR 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: 1바이트 읽기 요청 전송 - 주소=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // 읽기 응답 수신 대기
    master_bfm.Rmbx.get(r_beat);
    $display("시간 %0t: 1바이트 읽기 응답 수신 - 데이터=0x%h", $time, r_beat.data & 8'hFF);
    
    // 데이터 검증 (첫 바이트만)
    if((r_beat.data & 8'hFF) == 8'h12)
      $display("데이터 검증 성공: 0x%h == 0x%h", r_beat.data & 8'hFF, 8'h12);
    else
      $display("데이터 검증 실패: 0x%h != 0x%h", r_beat.data & 8'hFF, 8'h12);
    
    //--------------------------------------------------------------------------
    // 테스트 6: 2바이트 쓰기/읽기
    //--------------------------------------------------------------------------
    
    // 2바이트 쓰기
    aw_beat = new();
    aw_beat.id = 5;
    aw_beat.addr = 32'h5010;
    aw_beat.len = 0;  // 단일 전송
    aw_beat.size = 1; // 2바이트 (2^1)
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: 2바이트 쓰기 요청 전송 - 주소=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h1234; // 첫 두 바이트만 유효
    w_beat.strb = 8'h03;    // 첫 두 바이트만 활성화
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: 2바이트 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
    #100;
    
    // 2바이트 읽기
    ar_beat = new();
    ar_beat.id = 5;
    ar_beat.addr = 32'h5010;
    ar_beat.len = 0;  // 단일 전송
    ar_beat.size = 1; // 2바이트
    ar_beat.burst = 1; // INCR 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: 2바이트 읽기 요청 전송 - 주소=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // 읽기 응답 수신 대기
    master_bfm.Rmbx.get(r_beat);
    $display("시간 %0t: 2바이트 읽기 응답 수신 - 데이터=0x%h", $time, r_beat.data & 16'hFFFF);
    
    // 데이터 검증 (첫 2바이트만)
    if((r_beat.data & 16'hFFFF) == 16'h1234)
      $display("데이터 검증 성공: 0x%h == 0x%h", r_beat.data & 16'hFFFF, 16'h1234);
    else
      $display("데이터 검증 실패: 0x%h != 0x%h", r_beat.data & 16'hFFFF, 16'h1234);
    
    //--------------------------------------------------------------------------
    // 테스트 7: 4바이트 쓰기/읽기
    //--------------------------------------------------------------------------
    
    // 4바이트 쓰기
    aw_beat = new();
    aw_beat.id = 6;
    aw_beat.addr = 32'h5020;
    aw_beat.len = 0;  // 단일 전송
    aw_beat.size = 2; // 4바이트 (2^2)
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: 4바이트 쓰기 요청 전송 - 주소=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h12345678; // 첫 4바이트만 유효
    w_beat.strb = 8'h0F;        // 첫 4바이트만 활성화
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: 4바이트 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    // 4바이트 읽기
    ar_beat = new();
    ar_beat.id = 6;
    ar_beat.addr = 32'h5020;
    ar_beat.len = 0;  // 단일 전송
    ar_beat.size = 2; // 4바이트
    ar_beat.burst = 1; // INCR 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: 4바이트 읽기 요청 전송 - 주소=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // 읽기 응답 수신 대기
    master_bfm.Rmbx.get(r_beat);
    $display("시간 %0t: 4바이트 읽기 응답 수신 - 데이터=0x%h", $time, r_beat.data & 32'hFFFFFFFF);
    
    // 데이터 검증 (첫 4바이트만)
    if((r_beat.data & 32'hFFFFFFFF) == 32'h12345678)
      $display("데이터 검증 성공: 0x%h == 0x%h", r_beat.data & 32'hFFFFFFFF, 32'h12345678);
    else
      $display("데이터 검증 실패: 0x%h != 0x%h", r_beat.data & 32'hFFFFFFFF, 32'h12345678);
    
    //--------------------------------------------------------------------------
    // 테스트 8: 정렬되지 않은 주소 (Unaligned) 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 8: 정렬되지 않은 주소 트랜잭션 ---");
    
    // 정렬되지 않은 주소에 4바이트 쓰기
    aw_beat = new();
    aw_beat.id = 7;
    aw_beat.addr = 32'h5021;  // 바이트 정렬되지 않음
    aw_beat.len = 0;  // 단일 전송
    aw_beat.size = 2; // 4바이트 (2^2)
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: 정렬되지 않은 주소 쓰기 요청 전송 - 주소=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h87654321; // 4바이트 데이터
    w_beat.strb = 8'h1E;        // 1-4번 바이트 활성화
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: 정렬되지 않은 주소 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
    #100;
    
    // 정렬되지 않은 주소에서 4바이트 읽기
    ar_beat = new();
    ar_beat.id = 7;
    ar_beat.addr = 32'h5021;  // 바이트 정렬되지 않음
    ar_beat.len = 0;  // 단일 전송
    ar_beat.size = 2; // 4바이트
    ar_beat.burst = 1; // INCR 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: 정렬되지 않은 주소 읽기 요청 전송 - 주소=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // 읽기 응답 수신 대기
    master_bfm.Rmbx.get(r_beat);
    $display("시간 %0t: 정렬되지 않은 주소 읽기 응답 수신 - 데이터=0x%h", $time, r_beat.data & 32'hFFFFFFFF);
    
    // 데이터 검증 (바이트 1-4)
    expected_data = ((64'h87654321 & 32'h00FFFFFF) << 8);
    if(((r_beat.data) & 32'hFFFFFF00) == expected_data)
      $display("데이터 검증 성공: 0x%h == 0x%h", (r_beat.data) & 32'hFFFFFF00, expected_data);
    else
      $display("데이터 검증 실패: 0x%h != 0x%h", (r_beat.data) & 32'hFFFFFF00, expected_data);
    
    //--------------------------------------------------------------------------
    // 테스트 9: 다양한 ID 사용 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 9: 다양한 ID 사용 트랜잭션 ---");
    
    // 3개의 다른 ID로 동시에 읽기 요청
    for(int i=0; i<3; i++) begin
      ar_beat = new();
      ar_beat.id = i + 10;  // ID 10, 11, 12
      ar_beat.addr = 32'h6000 + (i * 8); // 주소 0x6000, 0x6008, 0x6010
      ar_beat.len = 0;  // 단일 전송
      ar_beat.size = 3; // 8바이트
      ar_beat.burst = 1; // INCR 모드
      ar_beat.lock = 0;
      ar_beat.cache = 0;
      ar_beat.prot = 0;
      ar_beat.qos = 0;
      ar_beat.region = 0;
      
      // 먼저 데이터 쓰기
      aw_beat = new();
      aw_beat.id = i + 10;  // 동일한 ID 사용
      aw_beat.addr = ar_beat.addr;
      aw_beat.len = 0;
      aw_beat.size = 3;
      aw_beat.burst = 1;
      aw_beat.lock = 0;
      aw_beat.cache = 0;
      aw_beat.prot = 0;
      aw_beat.qos = 0;
      aw_beat.region = 0;
      
      $display("시간 %0t: ID %0d로 주소 0x%h에 데이터 쓰기", $time, aw_beat.id, aw_beat.addr);
      master_bfm.AWmbx.put(aw_beat);
      
      w_beat = new();
      w_beat.data = 64'hA000_0000_0000_0000 | aw_beat.id; // ID 포함 데이터
      w_beat.strb = 8'hFF;
      w_beat.last = 1;
      master_bfm.Wmbx.put(w_beat);
    end
    
    // 3개 응답 수신
    for(int i=0; i<3; i++) begin
      master_bfm.Bmbx.get(b_beat);
      $display("시간 %0t: ID %0d 쓰기 응답 수신 - 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    end
    
    // 지연
    #100;
    
    // 3개의 다른 ID로 동시에 읽기 요청
    for(int i=0; i<3; i++) begin
      ar_beat = new();
      ar_beat.id = i + 10;  // ID 10, 11, 12
      ar_beat.addr = 32'h6000 + (i * 8); // 주소 0x6000, 0x6008, 0x6010
      ar_beat.len = 0;  // 단일 전송
      ar_beat.size = 3; // 8바이트
      ar_beat.burst = 1; // INCR 모드
      ar_beat.lock = 0;
      ar_beat.cache = 0;
      ar_beat.prot = 0;
      ar_beat.qos = 0;
      ar_beat.region = 0;
      
      $display("시간 %0t: ID %0d로 주소 0x%h에서 데이터 읽기", $time, ar_beat.id, ar_beat.addr);
      master_bfm.ARmbx.put(ar_beat);
    end
    
    // 3개의 응답 (순서는 ID에 따라 다를 수 있음)
    for(int i=0; i<3; i++) begin
      master_bfm.Rmbx.get(r_beat);
      $display("시간 %0t: ID %0d 읽기 응답 수신 - 데이터=0x%h", $time, r_beat.id, r_beat.data);
      
      // 데이터 검증 (ID가 포함된 데이터)
      expected_data = 64'hA000_0000_0000_0000 | r_beat.id;
      if(r_beat.data == expected_data)
        $display("데이터 검증 성공: 0x%h == 0x%h", r_beat.data, expected_data);
      else
        $display("데이터 검증 실패: 0x%h != 0x%h", r_beat.data, expected_data);
    end
    
    //--------------------------------------------------------------------------
    // 테스트 10: 긴 버스트 길이 트랜잭션
    //--------------------------------------------------------------------------
    $display("\n--- 테스트 10: 긴 버스트 길이 트랜잭션 ---");
    
    // 최대 길이(255) 버스트 쓰기
    aw_beat = new();
    aw_beat.id = 15;
    aw_beat.addr = 32'h8000;
    aw_beat.len = 15;  // 16 전송 (AXI4는 최대 256 이지만 테스트를 위해 16으로 제한)
    aw_beat.size = 3;  // 8바이트
    aw_beat.burst = 1; // INCR 모드
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("시간 %0t: 긴 버스트 쓰기 요청 전송 - 주소=0x%h, 길이=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 16개의 데이터 전송
    for(int i=0; i<16; i++) begin
      w_beat = new();
      w_beat.data = 64'hB000_0000_0000_0000 | i; // 인덱스 포함 데이터
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 15); // 마지막 전송에만 last 설정
      
      $display("시간 %0t: 긴 버스트 쓰기 데이터 전송 #%0d - 데이터=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // 쓰기 응답 수신 대기
    master_bfm.Bmbx.get(b_beat);
    $display("시간 %0t: 긴 버스트 쓰기 응답 수신 - ID=%0d, 응답코드=%0d", $time, b_beat.id, b_beat.resp);
    
    // 지연
    #200;
    
    // 최대 길이 버스트 읽기
    ar_beat = new();
    ar_beat.id = 15;
    ar_beat.addr = 32'h8000;
    ar_beat.len = 15;  // 16 전송
    ar_beat.size = 3;  // 8바이트
    ar_beat.burst = 1; // INCR 모드
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("시간 %0t: 긴 버스트 읽기 요청 전송 - 주소=0x%h, 길이=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // 16개의 데이터 수신
    for(int i=0; i<16; i++) begin
      master_bfm.Rmbx.get(r_beat);
      $display("시간 %0t: 긴 버스트 읽기 응답 수신 #%0d - 데이터=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // 데이터 검증
      expected_data = 64'hB000_0000_0000_0000 | i;
      if(r_beat.data == expected_data)
        $display("데이터 검증 성공: 0x%h == 0x%h", r_beat.data, expected_data);
      else
        $display("데이터 검증 실패: 0x%h != 0x%h", r_beat.data, expected_data);
    end
    
    //--------------------------------------------------------------------------
    // 테스트 완료
    //--------------------------------------------------------------------------
    $display("\n=== 모든 테스트 완료 - 시간: %0t ===", $time);
    
    // 시뮬레이션 종료
    #1000;
    $display("시뮬레이션 완료");
    $finish;
  end
  
  // 파형 생성
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, axi_top_tb_simple);
  end
  
endmodule