`ifndef AXI_MONITOR_SV
`define AXI_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_transactions.sv"

class axi_monitor extends uvm_component;

  `uvm_component_utils(axi_monitor)

  // virtual interface
  virtual AXI4 #(4, 4) vif;

  uvm_analysis_port #(axi_transaction) ap;

  function new(string name = "axi_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual AXI4 #(4, 4))::get(this, "", "vif", vif)) begin
      `uvm_fatal("AXI_MONITOR", "Virtual interface not set")
    end
  endfunction

task run_phase(uvm_phase phase);
  axi_transaction tr;
  uvm_object obj;

  forever begin
    @(posedge vif.ACLK);
    if (vif.RVALID && vif.RREADY) begin
      obj = axi_transaction::type_id::create("read_tr");
      if (!$cast(tr, obj)) begin
        `uvm_fatal("AXI_MONITOR", "Failed to cast to axi_transaction")
      end
      tr.cmd   = AXI_READ;
      tr.addr  = vif.ARADDR;
      tr.rdata = vif.RDATA;
      tr.resp  = vif.RRESP;
      ap.write(tr);
    end
    if (vif.BVALID && vif.BREADY) begin
      obj = axi_transaction::type_id::create("write_tr");
      if (!$cast(tr, obj)) begin
        `uvm_fatal("AXI_MONITOR", "Failed to cast to axi_transaction")
      end
      tr.cmd  = AXI_WRITE;
      tr.resp = vif.BRESP;
      ap.write(tr);
    end
  end
endtask

endclass

`endif // AXI_MONITOR_SV
