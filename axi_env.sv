`ifndef AXI_ENV_SV
`define AXI_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_agent.sv"
`include "axi_scoreboard.sv"

class axi_env extends uvm_env;

  `uvm_component_utils(axi_env)

  axi_agent       agent;
  axi_scoreboard  scoreboard;

  function new(string name = "axi_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agent      = axi_agent::type_id::create("agent", this);
    scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agent.monitor.ap.connect(scoreboard.imp);
  endfunction

endclass

`endif
