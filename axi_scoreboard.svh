`ifndef AXI_SCOREBOARD_SVH
`define AXI_SCOREBOARD_SVH

// AXI 스코어보드 클래스
// 예상 트랜잭션과 실제 트랜잭션을 비교하는 UVM 스코어보드
class axi_scoreboard extends uvm_scoreboard;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_scoreboard)
  
  // 구성 객체
  axi_config cfg;
  
  // TLM 포트 - 드라이버와 모니터로부터 트랜잭션 수신
  uvm_analysis_imp #(axi_seq_item, axi_scoreboard) item_from_driver;
  uvm_analysis_imp #(axi_seq_item, axi_scoreboard) item_from_monitor;
  
  // 예상 트랜잭션과 실제 트랜잭션 저장 큐
  axi_seq_item exp_queue[$];
  
  // 메모리 모델
  bit [7:0] mem[*];  // 스파스 배열 - 실제 액세스된 주소만 저장
  
  // 통계 카운터
  int num_transactions;
  int num_matches;
  int num_mismatches;
  
  // UVM verbosity 설정
  int unsigned verbosity_level = UVM_MEDIUM;
  
  // 생성자
  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_from_driver = new("item_from_driver", this);
    item_from_monitor = new("item_from_monitor", this);
    num_transactions = 0;
    num_matches = 0;
    num_mismatches = 0;
    `uvm_info(get_type_name(), "AXI Scoreboard created", UVM_HIGH)
  endfunction : new
  
  // 빌드 페이즈 - 구성 객체 획득
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 구성 객체 가져오기
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // 드라이버로부터 트랜잭션 수신
  function void write_driver(axi_seq_item item);
    axi_seq_item exp_item;
    
    // 로그 메시지
    `uvm_info(get_type_name(), $sformatf("Received expected transaction from driver: %s", item.convert2string()), verbosity_level)
    
    // 예상 트랜잭션 복사
    exp_item = axi_seq_item::type_id::create("exp_item");
    exp_item.copy(item);
    
    // 쓰기 트랜잭션인 경우 메모리 업데이트
    if (item.is_write) begin
      bit [63:0] data = item.data;
      bit [7:0] strb = item.strb;
      
      // 쓰기 스트로브에 따라 메모리 업데이트
      for (int i = 0; i < 8; i++) begin
        if (strb[i]) begin
          mem[item.addr + i] = data[i*8 +: 8];
          `uvm_info(get_type_name(), $sformatf("Memory write: addr=0x%0h, data[%0d]=0x%0h", 
                                             item.addr+i, i, data[i*8 +: 8]), UVM_HIGH)
        end
      end
    end
    // 읽기 트랜잭션인 경우 메모리에서 데이터 읽기
    else begin
      bit [63:0] data = 0;
      
      // 8바이트 읽기
      for (int i = 0; i < 8; i++) begin
        if (mem.exists(item.addr + i))
          data[i*8 +: 8] = mem[item.addr + i];
        else
          data[i*8 +: 8] = 0; // 초기화되지 않은 메모리는 0으로 간주
      end
      
      exp_item.rdata = data;
      `uvm_info(get_type_name(), $sformatf("Memory read: addr=0x%0h, expected data=0x%0h", 
                                         item.addr, data), UVM_HIGH)
    end
    
    // 예상 트랜잭션 큐에 저장
    exp_queue.push_back(exp_item);
  endfunction : write_driver
  
  // 모니터로부터 트랜잭션 수신
  function void write_monitor(axi_seq_item item);
    axi_seq_item exp_item;
    bit found = 0;
    
    // 로그 메시지
    `uvm_info(get_type_name(), $sformatf("Received actual transaction from monitor: %s", item.convert2string()), verbosity_level)
    
    // 실제 트랜잭션과 일치하는 예상 트랜잭션 찾기
    foreach (exp_queue[i]) begin
      if ((exp_queue[i].addr == item.addr) && (exp_queue[i].id == item.id) && 
          (exp_queue[i].is_write == item.is_write)) begin
        exp_item = exp_queue[i];
        exp_queue.delete(i);
        found = 1;
        break;
      end
    end
    
    // 일치하는 예상 트랜잭션을 찾지 못한 경우
    if (!found) begin
      `uvm_error(get_type_name(), $sformatf("Unexpected transaction detected: %s", item.convert2string()))
      num_mismatches++;
      return;
    end
    
    // 트랜잭션 비교
    num_transactions++;
    
    // 쓰기 트랜잭션인 경우 응답 코드만 확인
    if (item.is_write) begin
      if (exp_item.resp == item.resp) begin
        `uvm_info(get_type_name(), $sformatf("Write transaction match - addr=0x%0h, resp=0x%0h", 
                                          item.addr, item.resp), verbosity_level)
        num_matches++;
      end
      else begin
        `uvm_error(get_type_name(), $sformatf("Write transaction mismatch - addr=0x%0h\nExpected resp=0x%0h\nActual resp=0x%0h", 
                                          item.addr, exp_item.resp, item.resp))
        num_mismatches++;
      end
    end
    // 읽기 트랜잭션인 경우 데이터와 응답 코드 모두 확인
    else begin
      if ((exp_item.rdata == item.rdata) && (exp_item.resp == item.resp)) begin
        `uvm_info(get_type_name(), $sformatf("Read transaction match - addr=0x%0h, data=0x%0h, resp=0x%0h", 
                                          item.addr, item.rdata, item.resp), verbosity_level)
        num_matches++;
      end
      else begin
        `uvm_error(get_type_name(), $sformatf("Read transaction mismatch - addr=0x%0h\nExpected data=0x%0h, resp=0x%0h\nActual data=0x%0h, resp=0x%0h", 
                                          item.addr, exp_item.rdata, exp_item.resp, item.rdata, item.resp))
        num_mismatches++;
      end
    end
  endfunction : write_monitor
  
  // 분석 포트로부터 트랜잭션 수신 (오버로딩)
  function void write(axi_seq_item item);
    // 소스 확인을 위해 item_from_driver와 item_from_monitor를 사용해야 함
    // 이 함수는 직접 호출되면 안됨
    `uvm_error(get_type_name(), "Direct write() call is not supported, use analysis port")
  endfunction : write
  
  // 검사 페이즈 - 미처리 트랜잭션 확인
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    
    // 미처리 예상 트랜잭션 확인
    if (exp_queue.size() > 0) begin
      `uvm_error(get_type_name(), $sformatf("%0d expected transactions not received", exp_queue.size()))
      
      foreach (exp_queue[i]) begin
        `uvm_info(get_type_name(), $sformatf("Pending expected transaction: %s", exp_queue[i].convert2string()), UVM_LOW)
      end
    end
  endfunction : check_phase
  
  // 종료 페이즈 - 스코어보드 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), $sformatf("Report: Scoreboard checked %0d transactions", num_transactions), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("       %0d transactions matched", num_matches), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("       %0d transactions mismatched", num_mismatches), UVM_LOW)
    
    if (num_mismatches == 0)
      `uvm_info(get_type_name(), "TEST PASSED", UVM_NONE)
    else
      `uvm_error(get_type_name(), "TEST FAILED")
  endfunction : report_phase
  
endclass : axi_scoreboard

`endif // AXI_SCOREBOARD_SVH