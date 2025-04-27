`ifndef AXI_DRIVER_SVH
`define AXI_DRIVER_SVH

// AXI 드라이버 클래스
// 시퀀서로부터 트랜잭션을 받아 AXI BFM으로 전송
class axi_driver extends uvm_driver #(axi_seq_item);
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_driver)
  
  // 설정 객체
  axi_config cfg;
  
  // 가상 인터페이스 - 명시적 매개변수화
  virtual AXI4 #(.N(8), .I(8)) vif;
  
  // 예상 트랜잭션을 위한 분석 포트
  uvm_analysis_port #(axi_seq_item) exp_port;
  
  // BFM과의 통신을 위한 메일박스
  mailbox #(ABeat #(.N(8), .I(8))) ar_mbx;
  mailbox #(RBeat #(.N(8), .I(8))) r_mbx;
  mailbox #(ABeat #(.N(8), .I(8))) aw_mbx;
  mailbox #(WBeat #(.N(8))) w_mbx;
  mailbox #(BBeat #(.I(8))) b_mbx;
  
  // 트랜잭션 카운터
  int num_sent;
  int num_read_sent;
  int num_write_sent;
  
  // 생성자
  function new(string name, uvm_component parent);
    super.new(name, parent);
    num_sent = 0;
    num_read_sent = 0;
    num_write_sent = 0;
    `uvm_info(get_type_name(), "AXI 드라이버 생성됨", UVM_HIGH)
  endfunction : new
  
  // 빌드 단계 - 설정 객체와 메일박스 가져오기
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 분석 포트 생성 - 여기서 생성해야 함
    exp_port = new("exp_port", this);
    
    // 설정 객체 가져오기
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "설정 객체를 찾을 수 없습니다. 기본 설정을 사용합니다.")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // 가상 인터페이스 가져오기
    if (!uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "가상 인터페이스를 찾을 수 없습니다.")
    end
    
    // 메일박스 생성 - 기존 메일박스를 가져오는 대신 새로 생성
    ar_mbx = new();
    r_mbx = new();
    aw_mbx = new();
    w_mbx = new();
    b_mbx = new();
    
    `uvm_info(get_type_name(), "빌드 단계 완료", UVM_HIGH)
  endfunction : build_phase
  
  // 연결 단계 - BFM과의 연결
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // 여기서 필요한 경우 메일박스를 BFM에 연결할 수 있음
    // 하지만 이 예제에서는 실제 BFM 연결 대신 내부 처리를 할 것임
    
    `uvm_info(get_type_name(), "연결 단계 완료", UVM_HIGH)
  endfunction : connect_phase
  
  // 실행 단계 - 트랜잭션 처리
  task run_phase(uvm_phase phase);
    axi_seq_item req, rsp;
    
    `uvm_info(get_type_name(), "실행 단계 시작", UVM_MEDIUM)
    
    forever begin
      // 시퀀서로부터 트랜잭션 가져오기
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(), $sformatf("트랜잭션 처리 중: %s", req.convert2string()), UVM_HIGH)
      
      // 예상 트랜잭션을 스코어보드로 보내기
      exp_port.write(req);
      
      // 트랜잭션 처리
      process_transaction(req);
      
      // 응답 생성
      rsp = axi_seq_item::type_id::create("rsp");
      rsp.set_id_info(req);
      
      // 주소와 ID 복사
      rsp.addr = req.addr;
      rsp.id = req.id;
      rsp.is_write = req.is_write;
      
      if (req.is_write) begin
        // 쓰기 응답 처리 - 응답 코드만 설정
        rsp.resp = 0;  // OKAY 응답
        num_write_sent++;
      end
      else begin
        // 읽기 응답 처리 - 간단한 메모리 모델에서 데이터 가져오기
        rsp.rdata = 64'hDEADBEEF_12345678;  // 테스트용 데이터
        rsp.resp = 0;  // OKAY 응답
        num_read_sent++;
      end
      
      // 응답 보내기
      seq_item_port.item_done(rsp);
      num_sent++;
      
      `uvm_info(get_type_name(), $sformatf("트랜잭션 처리 완료, 응답: %s", rsp.convert2string()), UVM_HIGH)
    end
  endtask : run_phase
  
  // 트랜잭션 처리
  task process_transaction(axi_seq_item req);
    // 실제 AXI 인터페이스 처리는 생략
    // 이 예제에서는 단순히 지연만 추가
    #10;
    
    if (req.is_write) begin
      `uvm_info(get_type_name(), $sformatf("쓰기 트랜잭션 전송: addr=0x%0h, data=0x%0h", 
                                         req.addr, req.data), UVM_HIGH)
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("읽기 트랜잭션 전송: addr=0x%0h", req.addr), UVM_HIGH)
    end
  endtask : process_transaction
  
  // 보고 단계 - 드라이버 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("보고: 드라이버가 %0d개의 트랜잭션 처리 (%0d 읽기, %0d 쓰기)", 
                                       num_sent, num_read_sent, num_write_sent), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_driver

`endif // AXI_DRIVER_SVH