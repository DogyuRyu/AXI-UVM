`ifndef AXI_AGENT_SV
`define AXI_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_sequencer.sv"
`include "axi_driver.sv"
`include "axi_monitor.sv"

class axi_agent extends uvm_agent;

  `uvm_component_utils(axi_agent)

  axi_sequencer sequencer;
  axi_driver    driver;
  axi_monitor   monitor;

  function new(string name = "axi_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sequencer = axi_sequencer::type_id::create("sequencer", this);
    driver    = axi_driver::type_id::create("driver", this);
    monitor   = axi_monitor::type_id::create("monitor", this);

    // Set virtual interface for driver and monitor
    uvm_config_db#(virtual AXI4 #(4, 4))::set(this, "driver", "vif", get_vif());
    uvm_config_db#(virtual AXI4 #(4, 4))::set(this, "monitor", "vif", get_vif());
  endfunction

  function virtual AXI4 #(4, 4) get_vif();
    virtual AXI4 #(4, 4) vif;
    if (!uvm_config_db#(virtual AXI4 #(4, 4))::get(this, "", "vif", vif))
      `uvm_fatal("AXI_AGENT", "Failed to get vif")
    return vif;
  endfunction

  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass

`endif
