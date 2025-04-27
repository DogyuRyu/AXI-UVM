`ifndef AXI_SEQUENCE_SVH
`define AXI_SEQUENCE_SVH

// AXI 시퀀스 아이템 (트랜잭션) 정의
class axi_seq_item extends uvm_sequence_item;
  // AXI 트랜잭션 파라미터
  parameter AXI_DW = 64;  // 데이터 폭 (DUT에서 사용)
  parameter AXI_AW = 32;  // 주소 폭
  parameter AXI_IW = 8;   // ID 폭
  parameter AXI_SW = AXI_DW >> 3;  // 스트로브 폭

  // 공통 필드
  rand bit [AXI_AW-1:0] addr;      // 주소
  rand bit [AXI_DW-1:0] data;      // 데이터
  rand bit [AXI_IW-1:0] id;        // ID
  rand bit [AXI_SW-1:0] strb;      // 바이트 스트로브 (쓰기 용)
  rand bit              is_write;  // 쓰기(1) 또는 읽기(0) 트랜잭션
  
  // 응답 필드 (모니터링용)
  bit [AXI_DW-1:0] rdata;          // 읽기 데이터 (DUT에서 수신)
  bit [1:0]        resp;           // AXI 응답 코드

  // 제약 조건
  constraint addr_aligned {
    // 주소는 데이터 폭에 따라 정렬되어야 함
    if (AXI_DW == 32) addr[1:0] == 2'b00;
    if (AXI_DW == 64) addr[2:0] == 3'b000;
  }
  
  constraint id_range {
    id inside {[0:2**AXI_IW-1]};
  }
  
  constraint strb_valid {
    if (is_write) {
      strb != 0;  // 최소한 하나의 바이트는 유효해야 함
    }
  }

  // UVM 매크로
  `uvm_object_utils_begin(axi_seq_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(id, UVM_ALL_ON)
    `uvm_field_int(strb, UVM_ALL_ON)
    `uvm_field_int(is_write, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(resp, UVM_ALL_ON)
  `uvm_object_utils_end
  
  // 생성자
  function new(string name = "axi_seq_item");
    super.new(name);
  endfunction
  
  // 문자열 출력 함수 (디버깅용)
  virtual function string convert2string();
    string s;
    s = super.convert2string();
    s = {s, $sformatf("\n addr=0x%0h", addr)};
    s = {s, $sformatf("\n data=0x%0h", data)};
    s = {s, $sformatf("\n id=0x%0h", id)};
    s = {s, $sformatf("\n strb=0x%0h", strb)};
    s = {s, $sformatf("\n is_write=%0d", is_write)};
    if (!is_write) 
      s = {s, $sformatf("\n rdata=0x%0h", rdata)};
    s = {s, $sformatf("\n resp=0x%0h", resp)};
    return s;
  endfunction
endclass: axi_seq_item

// 기본 AXI 시퀀스
class axi_base_sequence extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(axi_base_sequence)
  
  function new(string name = "axi_base_sequence");
    super.new(name);
  endfunction
  
  // 시퀀스 본문 - 구현은 자식 클래스에서
  virtual task body();
    `uvm_info(get_type_name(), "Base sequence - Not expected to be called directly", UVM_HIGH)
  endtask
endclass: axi_base_sequence

// 단일 쓰기 트랜잭션 시퀀스
class axi_single_write_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_single_write_sequence)
  
  rand bit [31:0] start_addr;
  rand bit [63:0] write_data;
  rand bit [7:0]  write_id;
  
  function new(string name = "axi_single_write_sequence");
    super.new(name);
  endfunction
  
  // For the single_write_sequence task body() method:
  task body();
    axi_seq_item req, rsp;
    
    req = axi_seq_item::type_id::create("req");
    start_item(req);
    
    req.addr = start_addr;
    req.data = write_data;
    req.id = write_id;
    req.is_write = 1;
    req.strb = {8{1'b1}}; // All bytes active
    
    `uvm_info(get_type_name(), $sformatf("Starting single write sequence to addr=0x%0h, data=0x%0h", 
                                      req.addr, req.data), UVM_MEDIUM)
    
    finish_item(req);
    
    // Wait for response - crucial for synchronization
    get_response(rsp);
    
    `uvm_info(get_type_name(), $sformatf("Completed single write sequence, response=0x%0h", 
                                        rsp.resp), UVM_MEDIUM)
  endtask
endclass: axi_single_write_sequence

// 단일 읽기 트랜잭션 시퀀스
class axi_single_read_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_single_read_sequence)
  
  rand bit [31:0] start_addr;
  rand bit [7:0]  read_id;
  
  function new(string name = "axi_single_read_sequence");
    super.new(name);
  endfunction
  
  // For the single_read_sequence task body() method:
  task body();
    axi_seq_item req, rsp;
    
    req = axi_seq_item::type_id::create("req");
    start_item(req);
    
    req.addr = start_addr;
    req.id = read_id;
    req.is_write = 0;
    
    `uvm_info(get_type_name(), $sformatf("Starting single read sequence from addr=0x%0h", 
                                      req.addr), UVM_MEDIUM)
    
    finish_item(req);
    
    // Wait for response - crucial for synchronization
    get_response(rsp);
    
    `uvm_info(get_type_name(), $sformatf("Completed single read sequence, data=0x%0h, response=0x%0h", 
                                        rsp.rdata, rsp.resp), UVM_MEDIUM)
  endtask
endclass: axi_single_read_sequence

// 다중 쓰기 트랜잭션 시퀀스
class axi_multiple_write_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_multiple_write_sequence)
  
  rand bit [31:0] start_addr;
  rand int        num_transactions;
  rand bit [7:0]  write_id;
  
  constraint num_txn_c {
    num_transactions inside {[1:20]};  // 1에서 20 사이의 트랜잭션
  }
  
  function new(string name = "axi_multiple_write_sequence");
    super.new(name);
  endfunction
  
  task body();
    axi_seq_item req;
    bit [31:0] curr_addr;
    
    curr_addr = start_addr;
    
    `uvm_info(get_type_name(), $sformatf("Starting multiple write sequence, %0d transactions starting at addr=0x%0h", 
                                        num_transactions, start_addr), UVM_MEDIUM)
    
    for (int i = 0; i < num_transactions; i++) begin
      req = axi_seq_item::type_id::create("req");
      start_item(req);
      
      req.addr = curr_addr;
      if (!req.randomize() with {
        id == write_id;
        is_write == 1;
        strb == {8{1'b1}};
      }) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      
      `uvm_info(get_type_name(), $sformatf("Writing data=0x%0h to addr=0x%0h", 
                                          req.data, req.addr), UVM_HIGH)
      
      finish_item(req);
      curr_addr += 8;  // 64비트(8바이트) 단위로 증가
    end
    
    `uvm_info(get_type_name(), "Completed multiple write sequence", UVM_MEDIUM)
  endtask
endclass: axi_multiple_write_sequence

// 다중 읽기 트랜잭션 시퀀스
class axi_multiple_read_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_multiple_read_sequence)
  
  rand bit [31:0] start_addr;
  rand int        num_transactions;
  rand bit [7:0]  read_id;
  
  constraint num_txn_c {
    num_transactions inside {[1:20]};  // 1에서 20 사이의 트랜잭션
  }
  
  function new(string name = "axi_multiple_read_sequence");
    super.new(name);
  endfunction
  
  task body();
    axi_seq_item req;
    bit [31:0] curr_addr;
    
    curr_addr = start_addr;
    
    `uvm_info(get_type_name(), $sformatf("Starting multiple read sequence, %0d transactions starting at addr=0x%0h", 
                                        num_transactions, start_addr), UVM_MEDIUM)
    
    for (int i = 0; i < num_transactions; i++) begin
      req = axi_seq_item::type_id::create("req");
      start_item(req);
      
      req.addr = curr_addr;
      if (!req.randomize() with {
        id == read_id;
        is_write == 0;
      }) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      
      `uvm_info(get_type_name(), $sformatf("Reading from addr=0x%0h", req.addr), UVM_HIGH)
      
      finish_item(req);
      get_response(rsp);
      
      `uvm_info(get_type_name(), $sformatf("Read data=0x%0h from addr=0x%0h", 
                                         rsp.rdata, curr_addr), UVM_HIGH)
      
      curr_addr += 8;  // 64비트(8바이트) 단위로 증가
    end
    
    `uvm_info(get_type_name(), "Completed multiple read sequence", UVM_MEDIUM)
  endtask
endclass: axi_multiple_read_sequence

// 메모리 테스트 시퀀스 (쓰기 후 읽기)
class axi_memory_test_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_memory_test_sequence)
  
  rand bit [31:0] start_addr;
  rand int        num_transactions;
  
  constraint num_txn_c {
    num_transactions inside {[1:10]};  // 1에서 10 사이의 트랜잭션
  }
  
  function new(string name = "axi_memory_test_sequence");
    super.new(name);
  endfunction
  
  task body();
    axi_multiple_write_sequence write_seq;
    axi_multiple_read_sequence read_seq;
    
    write_seq = axi_multiple_write_sequence::type_id::create("write_seq");
    read_seq = axi_multiple_read_sequence::type_id::create("read_seq");
    
    // 쓰기 시퀀스 설정 및 실행
    if (!write_seq.randomize() with {
      start_addr == local::start_addr;
      num_transactions == local::num_transactions;
    }) begin
      `uvm_error(get_type_name(), "Write sequence randomization failed")
    end
    
    `uvm_info(get_type_name(), "Starting memory test - write phase", UVM_MEDIUM)
    write_seq.start(m_sequencer);
    
    // 읽기 시퀀스 설정 및 실행
    if (!read_seq.randomize() with {
      start_addr == local::start_addr;
      num_transactions == local::num_transactions;
    }) begin
      `uvm_error(get_type_name(), "Read sequence randomization failed")
    end
    
    `uvm_info(get_type_name(), "Starting memory test - read phase", UVM_MEDIUM)
    read_seq.start(m_sequencer);
    
    `uvm_info(get_type_name(), "Memory test sequence completed", UVM_MEDIUM)
  endtask
endclass: axi_memory_test_sequence

// 랜덤 AXI 트랜잭션 시퀀스
class axi_random_sequence extends axi_base_sequence;
  `uvm_object_utils(axi_random_sequence)
  
  rand int num_transactions;
  
  constraint num_txn_c {
    num_transactions inside {[10:50]};  // 10에서 50 사이의 트랜잭션
  }
  
  function new(string name = "axi_random_sequence");
    super.new(name);
  endfunction
  
  task body();
    axi_seq_item req;
    
    `uvm_info(get_type_name(), $sformatf("Starting random sequence with %0d transactions", 
                                        num_transactions), UVM_MEDIUM)
    
    repeat(num_transactions) begin
      req = axi_seq_item::type_id::create("req");
      start_item(req);
      
      if (!req.randomize()) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      
      if (req.is_write)
        `uvm_info(get_type_name(), $sformatf("Random write: addr=0x%0h, data=0x%0h", 
                                           req.addr, req.data), UVM_HIGH)
      else
        `uvm_info(get_type_name(), $sformatf("Random read: addr=0x%0h", req.addr), UVM_HIGH)
      
      finish_item(req);
      
      if (!req.is_write) begin
        get_response(rsp);
        `uvm_info(get_type_name(), $sformatf("Read response: data=0x%0h", rsp.rdata), UVM_HIGH)
      end
    end
    
    `uvm_info(get_type_name(), "Random sequence completed", UVM_MEDIUM)
  endtask
endclass: axi_random_sequence

`endif // AXI_SEQUENCE_SVH