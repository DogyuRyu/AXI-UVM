`ifndef AXI_ENVIRONMENT_SVH
`define AXI_ENVIRONMENT_SVH

// AXI 환경 클래스
// 에이전트와 스코어보드를 포함하는 UVM 환경
class axi_environment extends uvm_env;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_environment)
  
  // 구성 객체
  axi_config cfg;
  
  // 에이전트와 스코어보드 선언
  axi_agent      agent;
  axi_scoreboard scoreboard;
  
  // 생성자
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Environment created", UVM_HIGH)
  endfunction : new
  
  // 빌드 페이즈 - 컴포넌트 생성
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 구성 객체 생성 또는 획득
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "Creating default configuration", UVM_MEDIUM)
      cfg = axi_config::type_id::create("cfg");
    end
    
    // 에이전트 생성
    agent = axi_agent::type_id::create("agent", this);
    
    // 스코어보드 생성
    scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
    
    // 구성 객체 전달
    uvm_config_db#(axi_config)::set(this, "agent", "cfg", cfg);
    uvm_config_db#(axi_config)::set(this, "scoreboard", "cfg", cfg);
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // 연결 페이즈 - 컴포넌트 연결
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // 에이전트의 분석 포트를 스코어보드에 연결
    agent.analysis_port.connect(scoreboard.item_from_monitor);
    
    // 드라이버에서 스코어보드로 직접 예상 트랜잭션 연결
    agent.driver.seq_item_port.connect(scoreboard.item_from_driver);
    
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // 종료 페이즈 - 환경 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "Report: AXI Environment completed", UVM_LOW)
  endfunction : report_phase
  
endclass : axi_environment

`endif // AXI_ENVIRONMENT_SVH