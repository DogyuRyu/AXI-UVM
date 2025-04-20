`ifndef AXI_SEQUENCER_SVH
`define AXI_SEQUENCER_SVH

// AXI 구성 클래스 (시퀀서 및 기타 컴포넌트에서 사용)
class axi_config extends uvm_object;

  // UVM 매크로 선언
  `uvm_object_utils(axi_config)
  
  // AXI 구성 파라미터
  int AXI_DW = 64;  // 데이터 폭
  int AXI_AW = 32;  // 주소 폭
  int AXI_IW = 8;   // ID 폭
  int AXI_SW;       // 스트로브 폭 (자동 계산)
  
  // 기타 설정
  bit has_coverage = 1;             // 커버리지 활성화 여부
  bit has_checks = 1;               // 체크 활성화 여부
  int unsigned outstanding_req = 8; // 최대 동시 요청 수
  int unsigned max_transaction_time_ns = 1000; // 최대 트랜잭션 시간 (ns)
  
  // 생성자
  function new(string name = "axi_config");
    super.new(name);
    // 스트로브 폭은 데이터 폭의 1/8
    AXI_SW = AXI_DW >> 3;
    `uvm_info(get_type_name(), "AXI configuration created", UVM_HIGH)
  endfunction : new
  
  // 구성 정보 출력 함수
  virtual function string convert2string();
    string s;
    s = super.convert2string();
    s = {s, $sformatf("\n AXI_DW = %0d", AXI_DW)};
    s = {s, $sformatf("\n AXI_AW = %0d", AXI_AW)};
    s = {s, $sformatf("\n AXI_IW = %0d", AXI_IW)};
    s = {s, $sformatf("\n AXI_SW = %0d", AXI_SW)};
    s = {s, $sformatf("\n has_coverage = %0d", has_coverage)};
    s = {s, $sformatf("\n has_checks = %0d", has_checks)};
    s = {s, $sformatf("\n outstanding_req = %0d", outstanding_req)};
    s = {s, $sformatf("\n max_transaction_time_ns = %0d", max_transaction_time_ns)};
    return s;
  endfunction : convert2string
  
  // 구성 설정 복사 함수
  virtual function void copy_config(axi_config cfg);
    this.AXI_DW = cfg.AXI_DW;
    this.AXI_AW = cfg.AXI_AW;
    this.AXI_IW = cfg.AXI_IW;
    this.AXI_SW = cfg.AXI_SW;
    this.has_coverage = cfg.has_coverage;
    this.has_checks = cfg.has_checks;
    this.outstanding_req = cfg.outstanding_req;
    this.max_transaction_time_ns = cfg.max_transaction_time_ns;
    `uvm_info(get_type_name(), "Configuration copied", UVM_HIGH)
  endfunction : copy_config
  
endclass : axi_config

// AXI Sequencer 클래스
// axi_seq_item 타입의 트랜잭션을 처리하는 UVM sequencer
class axi_sequencer extends uvm_sequencer #(axi_seq_item);
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_sequencer)
  
  // 구성 객체 (설정 가능한 파라미터)
  axi_config cfg;
  
  // 시퀀서 생성자
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "AXI Sequencer created", UVM_HIGH)
  endfunction : new
  
  // 빌드 페이즈 - 구성 객체 획득
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 구성 객체 가져오기 (있는 경우)
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
  endfunction : build_phase
  
  // 연결 페이즈
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), "Connect phase completed", UVM_HIGH)
  endfunction : connect_phase
  
  // 종료 페이즈 - 시퀀서 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Report: Sequencer processed %0d transactions", 
                                       this.seq_item_export.count()), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_sequencer

`endif // AXI_SEQUENCER_SVH