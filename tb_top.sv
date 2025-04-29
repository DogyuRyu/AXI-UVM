//------------------------------------------------------------------------------
// File: tb_top.sv
// Description: AXI Testbench Top Module
//------------------------------------------------------------------------------

`include "uvm_macros.svh"
`include "axi_transactions.svh"
`include "axi_sequences.svh"
`include "axi_sequencer.svh"
`include "axi_driver.svh"
`include "axi_monitor.svh"
`include "axi_scoreboard.svh"
`include "axi_agent.svh"
`include "axi_env.svh"
`include "axi_test.svh"

module tb_top;
  import uvm_pkg::*;
  
  // Clock and reset generation
  bit clk;
  bit rst;
  
  // Clock generation - 10ns period
  always #5 clk = ~clk;
  
  // Reset generation
  initial begin
    rst = 0; // Active low reset
    #20 rst = 1;
  end
  
  // AXI interface instance
  axi_intf #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(16),
    .ID_WIDTH(8)
  ) intf (
    .clk(clk),
    .rst(rst)
  );
  
  // DUT instance
  axi_slave #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(16),
    .ID_WIDTH(8)
  ) dut (
    .clk(clk),
    .rst(!rst), // Note: Adjust reset polarity if needed for your DUT
    
    // Write Address Channel
    .s_axi_awid(intf.AWID),
    .s_axi_awaddr(intf.AWADDR),
    .s_axi_awlen(intf.AWLEN),
    .s_axi_awsize(intf.AWSIZE),
    .s_axi_awburst(intf.AWBURST),
    .s_axi_awlock(intf.AWLOCK),
    .s_axi_awcache(intf.AWCACHE),
    .s_axi_awprot(intf.AWPROT),
    .s_axi_awvalid(intf.AWVALID),
    .s_axi_awready(intf.AWREADY),
    
    // Write Data Channel
    .s_axi_wdata(intf.WDATA),
    .s_axi_wstrb(intf.WSTRB),
    .s_axi_wlast(intf.WLAST),
    .s_axi_wvalid(intf.WVALID),
    .s_axi_wready(intf.WREADY),
    
    // Write Response Channel
    .s_axi_bid(intf.BID),
    .s_axi_bresp(intf.BRESP),
    .s_axi_bvalid(intf.BVALID),
    .s_axi_bready(intf.BREADY),
    
    // Read Address Channel
    .s_axi_arid(intf.ARID),
    .s_axi_araddr(intf.ARADDR),
    .s_axi_arlen(intf.ARLEN),
    .s_axi_arsize(intf.ARSIZE),
    .s_axi_arburst(intf.ARBURST),
    .s_axi_arlock(intf.ARLOCK),
    .s_axi_arcache(intf.ARCACHE),
    .s_axi_arprot(intf.ARPROT),
    .s_axi_arvalid(intf.ARVALID),
    .s_axi_arready(intf.ARREADY),
    
    // Read Data Channel
    .s_axi_rid(intf.RID),
    .s_axi_rdata(intf.RDATA),
    .s_axi_rresp(intf.RRESP),
    .s_axi_rlast(intf.RLAST),
    .s_axi_rvalid(intf.RVALID),
    .s_axi_rready(intf.RREADY)
  );
  
  // Start UVM test
  initial begin
    // Set virtual interface in config DB
    uvm_config_db#(virtual axi_intf)::set(null, "uvm_test_top", "vif", intf);
    
    // Run test
    run_test("axi_burst_test"); // Or any other test class name
  end
  
  // Dump waveforms (for simulator support)
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
  
endmodule