`ifndef AXI_TEST_SV
`define AXI_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

// axit_env와 sequence 인클루드
`include "axi_env.sv"
`include "axi_sequence.sv"

class axi_test extends uvm_test;

  `uvm_component_utils(axi_test)

  axi_env env;
  virtual AXI4 #(4, 4) vif;

  function new(string name = "axi_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual AXI4 #(4, 4))::get(this, "", "vif", vif))
      `uvm_fatal("AXI_TEST", "Cannot get VIF")
    uvm_config_db#(virtual AXI4 #(4, 4))::set(this, "env.agent", "vif", vif);
    env = axi_env::type_id::create("env", this);
  endfunction

task run_phase(uvm_phase phase);
  axi_write_sequence write_seq;
  axi_read_sequence read_seq;
  phase.raise_objection(this);

  `uvm_info("axi_test", ">>> Starting AXI Protocol Simulation Test", UVM_MEDIUM)

  write_seq = axi_write_sequence::type_id::create("write_seq");
  write_seq.start(env.agent.sequencer);

  env.scoreboard.expected_rdata = 32'hDEADBEEF;

  read_seq = axi_read_sequence::type_id::create("read_seq");
  read_seq.start(env.agent.sequencer);

  phase.drop_objection(this);
endtask


endclass


`endif
