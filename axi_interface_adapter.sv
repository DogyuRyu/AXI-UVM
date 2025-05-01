module axi_interface_adapter #(
  parameter AXI_DW = 64,
  parameter AXI_AW = 32,
  parameter AXI_IW = 8,
  parameter AXI_SW = AXI_DW/8
) (
  // AXI4 interface (BFM side)
  AXI4 bfm_intf,

  input                    axi_clk_i,    // Receives clock
  input                    axi_rstn_i,   // Receives reset
  
  // axi write address channel
  output     [ AXI_IW-1: 0] axi_awid_i,
  output     [ AXI_AW-1: 0] axi_awaddr_i,
  output     [      4-1: 0] axi_awlen_i,
  output     [      3-1: 0] axi_awsize_i,
  output     [      2-1: 0] axi_awburst_i,
  output     [      2-1: 0] axi_awlock_i,
  output     [      4-1: 0] axi_awcache_i,
  output     [      3-1: 0] axi_awprot_i,
  output                    axi_awvalid_i,
  input                     axi_awready_o,
  
  // axi write data channel
  output     [ AXI_IW-1: 0] axi_wid_i,
  output     [ AXI_DW-1: 0] axi_wdata_i,
  output     [ AXI_SW-1: 0] axi_wstrb_i,
  output                    axi_wlast_i,
  output                    axi_wvalid_i,
  input                     axi_wready_o,
  
  // axi write response channel
  input      [ AXI_IW-1: 0] axi_bid_o,
  input      [      2-1: 0] axi_bresp_o,
  input                     axi_bvalid_o,
  output                    axi_bready_i,
  
  // axi read address channel
  output     [ AXI_IW-1: 0] axi_arid_i,
  output     [ AXI_AW-1: 0] axi_araddr_i,
  output     [      4-1: 0] axi_arlen_i,
  output     [      3-1: 0] axi_arsize_i,
  output     [      2-1: 0] axi_arburst_i,
  output     [      2-1: 0] axi_arlock_i,
  output     [      4-1: 0] axi_arcache_i,
  output     [      3-1: 0] axi_arprot_i,
  output                    axi_arvalid_i,
  input                     axi_arready_o,
  
  // axi read data channel
  input      [ AXI_IW-1: 0] axi_rid_o,
  input      [ AXI_DW-1: 0] axi_rdata_o,
  input      [      2-1: 0] axi_rresp_o,
  input                     axi_rlast_o,
  input                     axi_rvalid_o,
  output                    axi_rready_i,
  
  // System bus signals (FROM DUT)
  input      [ AXI_AW-1: 0] sys_addr_o,
  input      [ AXI_DW-1: 0] sys_wdata_o,
  input      [ AXI_SW-1: 0] sys_sel_o,
  input                     sys_wen_o,
  input                     sys_ren_o,
  
  // System bus signals (TO DUT)
  input      [ AXI_DW-1: 0] sys_rdata_i,
  input                     sys_err_i,
  input                     sys_ack_i
);

  // REMOVED - Do NOT drive interface clock and reset
  // assign bfm_intf.ACLK = axi_clk_i;
  // assign bfm_intf.ARESETn = axi_rstn_i;
  
  // Write Address channel connections
  assign axi_awid_i = bfm_intf.AWID;
  assign axi_awaddr_i = bfm_intf.AWADDR;
  assign axi_awlen_i = bfm_intf.AWLEN[3:0]; // AXI4 -> AXI3 conversion
  assign axi_awsize_i = bfm_intf.AWSIZE;
  assign axi_awburst_i = bfm_intf.AWBURST;
  assign axi_awlock_i = {1'b0, bfm_intf.AWLOCK}; // AXI4 is 1-bit, AXI3 is 2-bit
  assign axi_awcache_i = bfm_intf.AWCACHE;
  assign axi_awprot_i = bfm_intf.AWPROT;
  assign axi_awvalid_i = bfm_intf.AWVALID;
  assign bfm_intf.AWREADY = axi_awready_o;
  
  // Write Data channel connections
  assign axi_wid_i = bfm_intf.AWID; // AXI4 has no WID, use AWID
  assign axi_wdata_i = bfm_intf.WDATA;
  assign axi_wstrb_i = bfm_intf.WSTRB;
  assign axi_wlast_i = bfm_intf.WLAST;
  assign axi_wvalid_i = bfm_intf.WVALID;
  assign bfm_intf.WREADY = axi_wready_o;
  
  // Write Response channel connections
  assign bfm_intf.BID = axi_bid_o;
  assign bfm_intf.BRESP = axi_bresp_o;
  assign bfm_intf.BVALID = axi_bvalid_o;
  assign axi_bready_i = bfm_intf.BREADY;
  
  // Read Address channel connections
  assign axi_arid_i = bfm_intf.ARID;
  assign axi_araddr_i = bfm_intf.ARADDR;
  assign axi_arlen_i = bfm_intf.ARLEN[3:0]; // AXI4 -> AXI3 conversion
  assign axi_arsize_i = bfm_intf.ARSIZE;
  assign axi_arburst_i = bfm_intf.ARBURST;
  assign axi_arlock_i = {1'b0, bfm_intf.ARLOCK}; // AXI4 is 1-bit, AXI3 is 2-bit
  assign axi_arcache_i = bfm_intf.ARCACHE;
  assign axi_arprot_i = bfm_intf.ARPROT;
  assign axi_arvalid_i = bfm_intf.ARVALID;
  assign bfm_intf.ARREADY = axi_arready_o;
  
  // Read Data channel connections
  assign bfm_intf.RID = axi_rid_o;
  assign bfm_intf.RDATA = axi_rdata_o;
  assign bfm_intf.RRESP = axi_rresp_o;
  assign bfm_intf.RLAST = axi_rlast_o;
  assign bfm_intf.RVALID = axi_rvalid_o;
  assign axi_rready_i = bfm_intf.RREADY;
  
  // No system bus assignments needed
  
endmodule