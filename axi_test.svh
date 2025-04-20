`ifndef AXI_TEST_SVH
`define AXI_TEST_SVH

// AXI 기본 테스트 클래스
class axi_base_test extends uvm_test;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_base_test)
  
  // 환경 및 구성 객체
  axi_environment env;
  axi_config cfg;
  
  // 생성자
  function new(string name = "axi_base_test", uvm_component parent = null);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Base Test created", UVM_HIGH)
  endfunction : new
  
  // 빌드 페이즈 - 컴포넌트 생성
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 구성 객체 생성
    cfg = axi_config::type_id::create("cfg");
    
    // 환경 생성
    env = axi_environment::type_id::create("env", this);
    
    // 구성 객체 설정
    cfg.AXI_DW = 64;  // 64비트 데이터 폭
    cfg.AXI_AW = 32;  // 32비트 주소 폭
    cfg.AXI_IW = 8;   // 8비트 ID 폭
    cfg.AXI_SW = cfg.AXI_DW >> 3;  // 8바이트 스트로브 폭
    
    // 구성 객체 전달
    uvm_config_db#(axi_config)::set(this, "env", "cfg", cfg);
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // 종료 페이즈 - 테스트 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "Report: AXI Base Test completed", UVM_LOW)
  endfunction : report_phase
  
endclass : axi_base_test

// 싱글 읽기/쓰기 테스트
class axi_single_rw_test extends axi_base_test;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_single_rw_test)
  
  // 생성자
  function new(string name = "axi_single_rw_test", uvm_component parent = null);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Single Read/Write Test created", UVM_HIGH)
  endfunction : new
  
  // 런 페이즈 - 시퀀스 실행
  task run_phase(uvm_phase phase);
    axi_single_write_sequence write_seq;
    axi_single_read_sequence read_seq;
    
    // 페이즈 타임아웃 설정
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Single Read/Write Test", UVM_MEDIUM)
    
    // 시퀀스 생성
    write_seq = axi_single_write_sequence::type_id::create("write_seq");
    read_seq = axi_single_read_sequence::type_id::create("read_seq");
    
    // 쓰기 시퀀스 실행
    `uvm_info(get_type_name(), "Starting write sequence", UVM_MEDIUM)
    write_seq.start(env.agent.sequencer);
    #100;  // 안정화를 위한 지연
    
    // 읽기 시퀀스 실행
    `uvm_info(get_type_name(), "Starting read sequence", UVM_MEDIUM)
    read_seq.start(env.agent.sequencer);
    #100;  // 안정화를 위한 지연
    
    `uvm_info(get_type_name(), "Completing Single Read/Write Test", UVM_MEDIUM)
    
    // 페이즈 타임아웃 해제
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : axi_single_rw_test

// 다중 읽기/쓰기 테스트
class axi_multiple_rw_test extends axi_base_test;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_multiple_rw_test)
  
  // 생성자
  function new(string name = "axi_multiple_rw_test", uvm_component parent = null);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Multiple Read/Write Test created", UVM_HIGH)
  endfunction : new
  
  // 런 페이즈 - 시퀀스 실행
  task run_phase(uvm_phase phase);
    axi_multiple_write_sequence write_seq;
    axi_multiple_read_sequence read_seq;
    
    // 페이즈 타임아웃 설정
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Multiple Read/Write Test", UVM_MEDIUM)
    
    // 시퀀스 생성
    write_seq = axi_multiple_write_sequence::type_id::create("write_seq");
    read_seq = axi_multiple_read_sequence::type_id::create("read_seq");
    
    // 시퀀스 설정
    write_seq.num_transactions = 10;
    read_seq.num_transactions = 10;
    
    // 쓰기 시퀀스 실행
    `uvm_info(get_type_name(), "Starting write sequence", UVM_MEDIUM)
    write_seq.start(env.agent.sequencer);
    #200;  // 안정화를 위한 지연
    
    // 읽기 시퀀스 실행
    `uvm_info(get_type_name(), "Starting read sequence", UVM_MEDIUM)
    read_seq.start(env.agent.sequencer);
    #200;  // 안정화를 위한 지연
    
    `uvm_info(get_type_name(), "Completing Multiple Read/Write Test", UVM_MEDIUM)
    
    // 페이즈 타임아웃 해제
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : axi_multiple_rw_test

// 메모리 테스트
class axi_memory_test extends axi_base_test;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_memory_test)
  
  // 생성자
  function new(string name = "axi_memory_test", uvm_component parent = null);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Memory Test created", UVM_HIGH)
  endfunction : new
  
  // 런 페이즈 - 시퀀스 실행
  task run_phase(uvm_phase phase);
    axi_memory_test_sequence mem_seq;
    
    // 페이즈 타임아웃 설정
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Memory Test", UVM_MEDIUM)
    
    // 시퀀스 생성
    mem_seq = axi_memory_test_sequence::type_id::create("mem_seq");
    
    // 시퀀스 설정
    mem_seq.num_transactions = 5;
    
    // 메모리 테스트 시퀀스 실행
    `uvm_info(get_type_name(), "Starting memory test sequence", UVM_MEDIUM)
    mem_seq.start(env.agent.sequencer);
    #300;  // 안정화를 위한 지연
    
    `uvm_info(get_type_name(), "Completing Memory Test", UVM_MEDIUM)
    
    // 페이즈 타임아웃 해제
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : axi_memory_test

// 랜덤 테스트
class axi_random_test extends axi_base_test;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_random_test)
  
  // 생성자
  function new(string name = "axi_random_test", uvm_component parent = null);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Random Test created", UVM_HIGH)
  endfunction : new
  
  // 런 페이즈 - 시퀀스 실행
  task run_phase(uvm_phase phase);
    axi_random_sequence rand_seq;
    
    // 페이즈 타임아웃 설정
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Random Test", UVM_MEDIUM)
    
    // 시퀀스 생성
    rand_seq = axi_random_sequence::type_id::create("rand_seq");
    
    // 시퀀스 설정
    rand_seq.num_transactions = 20;
    
    // 랜덤 시퀀스 실행
    `uvm_info(get_type_name(), "Starting random sequence", UVM_MEDIUM)
    rand_seq.start(env.agent.sequencer);
    #500;  // 안정화를 위한 지연
    
    `uvm_info(get_type_name(), "Completing Random Test", UVM_MEDIUM)
    
    // 페이즈 타임아웃 해제
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : axi_random_test

`endif // AXI_TEST_SVH