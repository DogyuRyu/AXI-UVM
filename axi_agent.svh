`ifndef AXI_AGENT_SVH
`define AXI_AGENT_SVH

// AXI 에이전트 클래스
// AXI UVM 환경을 위한 드라이버, 시퀀서, 모니터 포함
class axi_agent extends uvm_agent;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_agent)
  
  // 설정 객체
  axi_config cfg;
  
  // 시퀀서, 드라이버, 모니터 선언
  axi_sequencer sequencer;
  axi_driver    driver;
  axi_monitor   monitor;
  
  // TLM 포트 - 스코어보드로 트랜잭션 전송
  uvm_analysis_port #(axi_seq_item) analysis_port;
  
  // 생성자
  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
    `uvm_info(get_type_name(), "AXI 에이전트 생성됨", UVM_HIGH)
  endfunction : new
  
  // 빌드 단계 - 컴포넌트 생성
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 설정 객체 가져오기
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "설정 객체를 찾을 수 없습니다. 기본 설정을 사용합니다.")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // 시퀀서, 드라이버, 모니터 생성
    sequencer = axi_sequencer::type_id::create("sequencer", this);
    driver = axi_driver::type_id::create("driver", this);
    monitor = axi_monitor::type_id::create("monitor", this);
    
    // 설정 객체 전달
    uvm_config_db#(axi_config)::set(this, "sequencer", "cfg", cfg);
    uvm_config_db#(axi_config)::set(this, "driver", "cfg", cfg);
    uvm_config_db#(axi_config)::set(this, "monitor", "cfg", cfg);
    
    `uvm_info(get_type_name(), "빌드 단계 완료", UVM_HIGH)
  endfunction : build_phase
  
  // 연결 단계 - 컴포넌트 연결
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // 드라이버와 시퀀서 연결
    driver.seq_item_port.connect(sequencer.seq_item_export);
    
    // 모니터를 분석 포트에 연결 (스코어보드용)
    monitor.item_collected_port.connect(analysis_port);
    
    `uvm_info(get_type_name(), "연결 단계 완료", UVM_HIGH)
  endfunction : connect_phase
  
  // 보고 단계 - 에이전트 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "보고: AXI 에이전트 완료", UVM_LOW)
  endfunction : report_phase
  
endclass : axi_agent

`endif // AXI_AGENT_SVH