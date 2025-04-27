`ifndef AXI_MONITOR_SVH
`define AXI_MONITOR_SVH

// AXI 모니터 클래스
// AXI 인터페이스의 트랜잭션을 관찰하고 분석하는 UVM 모니터
class axi_monitor extends uvm_monitor;
  
  // UVM 매크로 선언
  `uvm_component_utils(axi_monitor)
  
  // 구성 객체
  axi_config cfg;
  
  // 가상 인터페이스
  virtual AXI4 #(.N(8), .I(8)) vif;
  
  // 분석 포트 - 트랜잭션을 스코어보드로 전송
  uvm_analysis_port #(axi_seq_item) item_collected_port;
  
  // 트랜잭션 카운터
  int num_collected;
  int num_read_collected;
  int num_write_collected;
  
  // 생성자
  function new(string name, uvm_component parent);
    super.new(name, parent);
    num_collected = 0;
    num_read_collected = 0;
    num_write_collected = 0;
    item_collected_port = new("item_collected_port", this);
    `uvm_info(get_type_name(), "AXI Monitor created", UVM_HIGH)
  endfunction : new
  
  // 빌드 페이즈 - 구성 객체 획득
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 구성 객체 가져오기
    if (!uvm_config_db#(axi_config)::get(this, "", "cfg", cfg)) begin
      `uvm_warning(get_type_name(), "No configuration object found, using default configuration")
      cfg = axi_config::type_id::create("default_cfg");
    end
    
    // 가상 인터페이스 가져오기
    if (!uvm_config_db#(virtual AXI4 #(.N(8), .I(8)))::get(this, "", "vif", vif)) begin 
      `uvm_fatal(get_type_name(), "No virtual interface found")
    end
    
    `uvm_info(get_type_name(), "Build phase completed", UVM_HIGH)
  endfunction : build_phase
  
  // 실행 페이즈 - 트랜잭션 모니터링 시작
  task run_phase(uvm_phase phase);
    axi_seq_item read_trans[$];  // 진행 중인 읽기 트랜잭션 큐
    axi_seq_item write_trans[$]; // 진행 중인 쓰기 트랜잭션 큐
    
    `uvm_info(get_type_name(), "Run phase started", UVM_MEDIUM)
    
    // 병렬로 모든 채널 모니터링
    fork
      // 읽기 주소 채널 모니터링
      monitor_ar_channel(read_trans);
      
      // 읽기 데이터 채널 모니터링
      monitor_r_channel(read_trans);
      
      // 쓰기 주소 채널 모니터링
      monitor_aw_channel(write_trans);
      
      // 쓰기 데이터 채널 모니터링
      monitor_w_channel(write_trans);
      
      // 쓰기 응답 채널 모니터링
      monitor_b_channel(write_trans);
      
      // 리셋 모니터링
      monitor_reset();
    join
  endtask : run_phase
  
  // 읽기 주소 채널 모니터링
  task monitor_ar_channel(ref axi_seq_item read_trans[$]);
    axi_seq_item tr;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.ARVALID && vif.ARREADY) begin
        // 새 읽기 트랜잭션 생성
        tr = axi_seq_item::type_id::create("tr");
        tr.addr = vif.ARADDR;
        tr.id = vif.ARID;
        tr.is_write = 0;  // 읽기 트랜잭션
        
        `uvm_info(get_type_name(), $sformatf("Detected read transaction: addr=0x%0h, id=0x%0h", 
                                           tr.addr, tr.id), UVM_HIGH)
        
        // 읽기 트랜잭션 큐에 추가
        read_trans.push_back(tr);
      end
    end
  endtask : monitor_ar_channel
  
  // 읽기 데이터 채널 모니터링
  task monitor_r_channel(ref axi_seq_item read_trans[$]);
    int i;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.RVALID && vif.RREADY) begin
        // 해당 ID의 읽기 트랜잭션 찾기
        for (i = 0; i < read_trans.size(); i++) begin
          if (read_trans[i].id == vif.RID) begin
            read_trans[i].rdata = vif.RDATA;
            read_trans[i].resp = vif.RRESP;
            
            `uvm_info(get_type_name(), $sformatf("Completed read transaction: addr=0x%0h, data=0x%0h, resp=0x%0h", 
                                               read_trans[i].addr, read_trans[i].rdata, read_trans[i].resp), UVM_HIGH)
            
            // 트랜잭션 완료 - 분석 포트로 전송
            if (vif.RLAST) begin
              item_collected_port.write(read_trans[i]);
              num_collected++;
              num_read_collected++;
              read_trans.delete(i);
            end
            
            break;
          end
        end
      end
    end
  endtask : monitor_r_channel
  
  // 쓰기 주소 채널 모니터링
  task monitor_aw_channel(ref axi_seq_item write_trans[$]);
    axi_seq_item tr;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.AWVALID && vif.AWREADY) begin
        // 새 쓰기 트랜잭션 생성
        tr = axi_seq_item::type_id::create("tr");
        tr.addr = vif.AWADDR;
        tr.id = vif.AWID;
        tr.is_write = 1;  // 쓰기 트랜잭션
        
        `uvm_info(get_type_name(), $sformatf("Detected write transaction: addr=0x%0h, id=0x%0h", 
                                           tr.addr, tr.id), UVM_HIGH)
        
        // 쓰기 트랜잭션 큐에 추가
        write_trans.push_back(tr);
      end
    end
  endtask : monitor_aw_channel
  
  // 쓰기 데이터 채널 모니터링
  task monitor_w_channel(ref axi_seq_item write_trans[$]);
    int i;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.WVALID && vif.WREADY) begin
        // 진행 중인 쓰기 트랜잭션에 데이터 추가
        if (write_trans.size() > 0) begin
          i = write_trans.size() - 1; // 가장 최근 트랜잭션
          write_trans[i].data = vif.WDATA;
          write_trans[i].strb = vif.WSTRB;
          
          `uvm_info(get_type_name(), $sformatf("Write data: data=0x%0h, strb=0x%0h", 
                                             write_trans[i].data, write_trans[i].strb), UVM_HIGH)
        end
      end
    end
  endtask : monitor_w_channel
  
  // 쓰기 응답 채널 모니터링
  task monitor_b_channel(ref axi_seq_item write_trans[$]);
    int i;
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.BVALID && vif.BREADY) begin
        // 해당 ID의 쓰기 트랜잭션 찾기
        for (i = 0; i < write_trans.size(); i++) begin
          if (write_trans[i].id == vif.BID) begin
            write_trans[i].resp = vif.BRESP;
            
            `uvm_info(get_type_name(), $sformatf("Completed write transaction: addr=0x%0h, data=0x%0h, resp=0x%0h", 
                                               write_trans[i].addr, write_trans[i].data, write_trans[i].resp), UVM_HIGH)
            
            // 트랜잭션 완료 - 분석 포트로 전송
            item_collected_port.write(write_trans[i]);
            num_collected++;
            num_write_collected++;
            write_trans.delete(i);
            
            break;
          end
        end
      end
    end
  endtask : monitor_b_channel
  
  // 리셋 모니터링
  task monitor_reset();
    forever begin
      @(negedge vif.ARESETn);
      `uvm_info(get_type_name(), "Reset detected", UVM_MEDIUM)
      
      // 리셋 동안 대기
      wait(vif.ARESETn);
      `uvm_info(get_type_name(), "Reset released", UVM_MEDIUM)
    end
  endtask : monitor_reset
  
  // 종료 페이즈 - 모니터 통계 출력
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Report: Monitor collected %0d transactions (%0d reads, %0d writes)", 
                                       num_collected, num_read_collected, num_write_collected), UVM_LOW)
  endfunction : report_phase
  
endclass : axi_monitor

`endif // AXI_MONITOR_SVH