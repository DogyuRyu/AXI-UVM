//------------------------------------------------------------------------------
// File: axi_transactions.svh
// Description: AXI Transaction class for UVM testbench
//------------------------------------------------------------------------------

`ifndef AXI_TRANSACTIONS_SVH
`define AXI_TRANSACTIONS_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

// AXI 버스트 타입 정의
typedef enum bit[1:0] {
  FIXED = 2'b00,
  INCR  = 2'b01,
  WRAP  = 2'b10
} axi_burst_type_e;

// AXI 트랜잭션 클래스
class axi_transaction extends uvm_sequence_item;
  // 트랜잭션 타입
  typedef enum {READ, WRITE} trans_type_e;
  rand trans_type_e trans_type;

  // 공통 파라미터
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 16;
  parameter ID_WIDTH = 8;
  parameter STRB_WIDTH = (DATA_WIDTH/8);

  // 공통 필드
  rand bit [ID_WIDTH-1:0]    id;
  rand bit [ADDR_WIDTH-1:0]  addr;
  rand axi_burst_type_e      burst_type;
  rand bit [2:0]             burst_size;
  rand bit [7:0]             burst_len;

  // 제어 신호들
  rand bit                   lock;
  rand bit [3:0]             cache;
  rand bit [2:0]             prot;

  // 데이터 필드
  rand bit [DATA_WIDTH-1:0]  data[];
  rand bit [STRB_WIDTH-1:0]  strb[];

  // 응답 필드
  bit [1:0]                  resp[];
  bit                        last[];

  // 등록 매크로
  `uvm_object_param_utils_begin(axi_transaction)
    `uvm_field_enum(trans_type_e, trans_type, UVM_ALL_ON)
    `uvm_field_int(id, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_enum(axi_burst_type_e, burst_type, UVM_ALL_ON)
    `uvm_field_int(burst_size, UVM_ALL_ON)
    `uvm_field_int(burst_len, UVM_ALL_ON)
    `uvm_field_int(lock, UVM_ALL_ON)
    `uvm_field_int(cache, UVM_ALL_ON)
    `uvm_field_int(prot, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
    `uvm_field_array_int(strb, UVM_ALL_ON)
    `uvm_field_array_int(resp, UVM_ALL_ON)
    `uvm_field_array_int(last, UVM_ALL_ON)
  `uvm_object_utils_end

  // 제약 조건들
  // 버스트 사이즈 제약: 버스트 사이즈는 데이터 폭보다 작거나 같아야 함
  constraint valid_size {
    burst_size <= $clog2(STRB_WIDTH);
  }

  // 데이터 배열 크기 제약
  constraint data_array_size {
    solve burst_len before data;
    data.size() == burst_len + 1;
    strb.size() == burst_len + 1;
  }

  // 버스트 타입에 따른 제약
  constraint burst_constraints {
    if (burst_type == FIXED) {
      burst_len inside {0, 1, 3, 7, 15};
    }
    else if (burst_type == WRAP) {
      burst_len inside {1, 3, 7, 15};
      // WRAP 모드에서 주소는 경계에 정렬되어야 함
      (addr % (2**burst_size * (burst_len+1))) == 0;
    }
  }

  // STRB 제약 조건 (쓰기 시에만 적용)
  constraint strb_constraints {
    if (trans_type == WRITE) {
      foreach (strb[i]) {
        strb[i] != 0; // 최소한 하나의 바이트는 쓰여야 함
      }
    }
  }

  // 응답 배열 초기화
  function void post_randomize();
    resp = new[burst_len + 1];
    last = new[burst_len + 1];
    
    foreach (last[i]) begin
      last[i] = (i == burst_len); // 마지막 전송에만 last 신호 설정
    end
  endfunction

  // 생성자
  function new(string name = "axi_transaction");
    super.new(name);
  endfunction

  // 문자열 변환 함수
  function string convert2string();
    string s;
    s = super.convert2string();
    s = {s, $sformatf("\nTransaction Type: %s", trans_type.name())};
    s = {s, $sformatf("\nID: 0x%0h", id)};
    s = {s, $sformatf("\nAddress: 0x%0h", addr)};
    s = {s, $sformatf("\nBurst Type: %s", burst_type.name())};
    s = {s, $sformatf("\nBurst Size: %0d", burst_size)};
    s = {s, $sformatf("\nBurst Length: %0d", burst_len)};
    
    if (data.size() > 0) begin
      s = {s, "\nData: "};
      foreach (data[i]) begin
        s = {s, $sformatf("0x%0h ", data[i])};
      end
    end
    
    return s;
  endfunction
  
endclass

`endif // AXI_TRANSACTIONS_SVH