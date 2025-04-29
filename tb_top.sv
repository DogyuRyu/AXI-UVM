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
  initial begin
    clk = 0; // Explicit initial value
    forever #5 clk = ~clk;
  end
  
  // Reset generation
  initial begin
    rst = 0; // Active low reset
    $display("Reset asserted at time %t", $time);
    #20 rst = 1;
    $display("Reset released at time %t", $time);
  end
  
  // Debug signal monitoring
  initial begin
    forever begin
      @(posedge clk);
      if (intf.AWVALID && intf.AWREADY)
        $display("Time %t: Write Address Handshake - AWID=%h, AWADDR=%h, AWLEN=%d", 
                 $time, intf.AWID, intf.AWADDR, intf.AWLEN);
      
      if (intf.WVALID && intf.WREADY)
        $display("Time %t: Write Data Handshake - WDATA=%h, WLAST=%b", 
                 $time, intf.WDATA, intf.WLAST);
      
      if (intf.BVALID && intf.BREADY)
        $display("Time %t: Write Response Handshake - BID=%h, BRESP=%h", 
                 $time, intf.BID, intf.BRESP);
      
      if (intf.ARVALID && intf.ARREADY)
        $display("Time %t: Read Address Handshake - ARID=%h, ARADDR=%h, ARLEN=%d", 
                 $time, intf.ARID, intf.ARADDR, intf.ARLEN);
      
      if (intf.RVALID && intf.RREADY)
        $display("Time %t: Read Data Handshake - RID=%h, RDATA=%h, RLAST=%b", 
                 $time, intf.RID, intf.RDATA, intf.RLAST);
    end
  end
  
  // Timeout mechanism
  initial begin
    #1000000000000; // 1ms timeout
    $display("ERROR: Simulation timeout at %t", $time);
    $finish;
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
    
    // Run test with debugging info
    $display("Starting test: axi_burst_test at time %t", $time);
    run_test("axi_burst_test"); // Or any other test class name
  end
  
  // Dump waveforms (for simulator support)
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
  
endmodule