`ifndef AXI_DRIVER_SVH
`define AXI_DRIVER_SVH

// AXI 드라이버 클래스
// axi_seq_item 타입의 트랜잭션을 받아 AXI BFM으로 전달하는 UVM 드라이버
class axi_driver extends uvm_driver #(axi_seq_item);
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_driver)
  
  // 구성 객체
  axi_config cfg;
  
  // 가상 인터페이스
  virtual AXI4 vif;
  
  // BFM과 통신하기 위한 메일박스
  mailbox #(ABeat #(.N(8), .I(8))) ar_mbx;
  mailbox #(RBeat #(.N(8), .I(8))) r_mbx;
  mailbox #(ABeat #(.N(8), .I(8))) aw_mbx;
  mailbox #(WBeat #(.N(8))) w_mbx;
  mailbox #(BBeat #(.I(8))) b_mbx;
  
  // BFM Agent 참조
  Axi4MasterAgent #(.N(8), .I(8)) agent;
  
  // 트랜잭션 수 카운터
  int num_sent;
  int num_read_sent;
  int num_write_sent;
  
  // 생성자
  function new(string name, uvm_component parent);
    super.new(name, parent);
    num_sent = 0;
    num_read_sent = 0;
    num_write_sent = 0;
    `uvm_info(get_type_name(), "AXI Driver created", UVM_HIGH)
  endfunction : new
  
  // 빌드 페이즈 - 구성 객체 획득 및 메일박스 생성
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 구성 객체 가져오기
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // 가상 인터페이스 가져오기
    if (!uvm_config_db#(virtual AXI4)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "No virtual interface found")
    end
    
    // 메일박스 생성
    ar_mbx = new();
    r_mbx = new();
    aw_mbx = new();
    w_mbx = new();
    b_mbx = new();
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // 연결 페이즈 - BFM Agent에 메일박스 연결
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // BFM Agent 생성 및 연결
    agent = new(ar_mbx, r_mbx, aw_mbx, w_mbx, b_mbx);
    
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // 실행 페이즈 - 트랜잭션 처리 루프
  task run_phase(uvm_phase phase);
    axi_seq_item req, rsp;
    
    `uvm_info(get_type_name(), "Run phase started", UVM_MEDIUM)
    
    forever begin
      // 시퀀서로부터 트랜잭션 가져오기
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(), $sformatf("Processing transaction: %s", req.convert2string()), UVM_HIGH)
      
      // 트랜잭션 처리
      process_transaction(req);
      
      // 트랜잭션 응답 처리
      rsp = axi_seq_item::type_id::create("rsp");
      rsp.set_id_info(req);
      
      if (req.is_write) begin
        // 쓰기 응답 처리
        BBeat #(.I(8)) bb;
        b_mbx.get(bb);
        
        rsp.resp = bb.resp;
        rsp.id = bb.id;
        
        num_write_sent++;
      end
      else begin
        // 읽기 응답 처리
        RBeat #(.N(8), .I(8)) rb;
        r_mbx.get(rb);
        
        rsp.rdata = rb.data;
        rsp.resp = rb.resp;
        rsp.id = rb.id;
        
        num_read_sent++;
      end
      
      // 응답 전송
      seq_item_port.item_done(rsp);
      num_sent++;
      
      `uvm_info(get_type_name(), $sformatf("Transaction processed, response: %s", rsp.convert2string()), UVM_HIGH)
    end
  endtask : run_phase
  
  // 트랜잭션 처리 함수
  task process_transaction(axi_seq_item req);
    if (req.is_write) begin
      // 쓰기 트랜잭션 처리
      ABeat #(.N(8), .I(8)) awbeat = new();
      WBeat #(.N(8)) wbeat = new();
      
      // 어드레스 채널 데이터 설정
      awbeat.id = req.id;
      awbeat.addr = req.addr;
      awbeat.len = 0;  // 단일 트랜젝션 (버스트 미지원)
      awbeat.size = 3; // 8바이트 (64비트) 데이터
      awbeat.burst = 1; // INCR 버스트 타입
      awbeat.lock = 0;
      awbeat.cache = 0;
      awbeat.prot = 0;
      awbeat.qos = 0;
      awbeat.region = 0;
      
      // 데이터 채널 데이터 설정
      wbeat.data = req.data;
      wbeat.strb = req.strb;
      wbeat.last = 1; // 마지막 데이터 (단일 트랜젝션)
      
      // BFM으로 데이터 전송
      `uvm_info(get_type_name(), $sformatf("Sending write transaction: addr=0x%0h, data=0x%0h", 
                                         req.addr, req.data), UVM_HIGH)
      aw_mbx.put(awbeat);
      w_mbx.put(wbeat);
    end
    else begin
      // 읽기 트랜잭션 처리
      ABeat #(.N(8), .I(8)) arbeat = new();
      
      // 어드레스 채널 데이터 설정
      arbeat.id = req.id;
      arbeat.addr = req.addr;
      arbeat.len = 0;  // 단일 트랜젝션 (버스트 미지원)
      arbeat.size = 3; // 8바이트 (64비트) 데이터
      arbeat.burst = 1; // INCR 버스트 타입
      arbeat.lock = 0;
      arbeat.cache = 0;
      arbeat.prot = 0;
      arbeat.qos = 0;
      arbeat.region = 0;
      
      // BFM으로 데이터 전송
      `uvm_info(get_type_name(), $sformatf("Sending read transaction: addr=0x%0h", req.addr), UVM_HIGH)
      ar_mbx.put(arbeat);
    end
  endtask : process_transaction
  
  // 종료 페이즈 - 드라이버 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Report: Driver processed %0d transactions (%0d reads, %0d writes)", 
                                       num_sent, num_read_sent, num_write_sent), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_driver

`endif // AXI_DRIVER_SVH