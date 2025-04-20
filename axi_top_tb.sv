`timescale 1ns/1ps

module top_tb;

  import uvm_pkg::*;
  import axi_pkg::*;


  `include "uvm_macros.svh"

  // Clock & Reset
  logic clk;
  logic rst_n;

  // Clock Generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset Generation
  initial begin
    rst_n = 0;
    #20 rst_n = 1;
  end

  // AXI4 Interface
  AXI4 #(.N(4), .I(4)) axi_if (.ACLK(clk), .ARESETn(rst_n));

  // Master BFM
  Axi4MasterBFM #(.N(4), .I(4)) axi_master_bfm (.intf(axi_if));

  axi_duv_slave dut (
    .aclk_i      (axi_if.ACLK),
    .aresetn_i   (axi_if.ARESETn),
    .awvalid_i   (axi_if.AWVALID),
    .awaddr_i    (axi_if.AWADDR),
    .awready_i   (axi_if.AWREADY),
    .awid_i      (axi_if.AWID),
    .awlen_i     (axi_if.AWLEN),
    .awsize_i    (axi_if.AWSIZE),
    .awburst_i   (axi_if.AWBURST),
    .awlock_i    (axi_if.AWLOCK),
    .awcache_i   (axi_if.AWCACHE),
    .awprot_i    (axi_if.AWPROT),
    .awqos_i     (4'b0000),
    .awregion_i  (4'b0000),
    .awuser_i    ('0),

    .wvalid_i    (axi_if.WVALID),
    .wdata_i     (axi_if.WDATA),
    .wstrb_i     (axi_if.WSTRB),
    .wlast_i     (axi_if.WLAST),
    .wready_i    (axi_if.WREADY),
    .wuser_i     ('0),

    .bvalid_i    (axi_if.BVALID),
    .bresp_i     (axi_if.BRESP),
    .bid_i       (axi_if.BID),
    .bready_i    (axi_if.BREADY),
    .buser_i     (),

    .arvalid_i   (axi_if.ARVALID),
    .araddr_i    (axi_if.ARADDR),
    .arready_i   (axi_if.ARREADY),
    .arid_i      (axi_if.ARID),
    .arlen_i     (axi_if.ARLEN),
    .arsize_i    (axi_if.ARSIZE),
    .arburst_i   (axi_if.ARBURST),
    .arlock_i    (axi_if.ARLOCK),
    .arcache_i   (axi_if.ARCACHE),
    .arprot_i    (axi_if.ARPROT),
    .arqos_i     (4'b0000),
    .arregion_i  (4'b0000),
    .aruser_i    ('0),

    .rvalid_i    (axi_if.RVALID),
    .rdata_i     (axi_if.RDATA),
    .rresp_i     (axi_if.RRESP),
    .rid_i       (axi_if.RID),
    .rlast_i     (axi_if.RLAST),
    .rready_i    (axi_if.RREADY),
    .ruser_i     (),

    .csysreq_i   (1'b0),
    .csysack_i   (1'b0),
    .cactive_i   (1'b0)
  );

  initial begin
    if (uvm_factory::get().find_by_name("axi_test") == null) begin
      $display("[ERROR] axi_test not found in UVM factory!");
      $finish;
    end else begin
      $display("[INFO] axi_test is correctly registered in the UVM factory.");
    end

    uvm_config_db#(virtual AXI4 #(4, 4))::set(null, "*", "vif", axi_if);

    run_test("axi_test");
  end

endmodule
