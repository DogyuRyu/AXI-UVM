// axi_pkg.sv
`ifndef AXI_PKG_SV
`define AXI_PKG_SV

package axi_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;

  `include "axi_transactions.sv"
  `include "axi_sequence.sv"
  `include "axi_sequencer.sv"
  `include "axi_driver.sv"
  `include "axi_monitor.sv"
  `include "axi_scoreboard.sv"
  `include "axi_agent.sv"
  `include "axi_env.sv"
  `include "axi_test.sv"

endpackage

`endif
