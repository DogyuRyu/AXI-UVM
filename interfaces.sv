//------------------------------------------------------------------------------
// File: interfaces.sv
// Description: AXI Interface Definition for UVM testbench
//------------------------------------------------------------------------------

`ifndef INTERFACES_SV
`define INTERFACES_SV

interface axi_intf #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter ID_WIDTH = 8,
    parameter STRB_WIDTH = (DATA_WIDTH/8)
)(
    input bit clk,
    input bit rst
);

    // Write Address Channel
    logic [ID_WIDTH-1:0]    AWID;
    logic [ADDR_WIDTH-1:0]  AWADDR;
    logic [7:0]             AWLEN;
    logic [2:0]             AWSIZE;
    logic [1:0]             AWBURST;
    logic                   AWLOCK;
    logic [3:0]             AWCACHE;
    logic [2:0]             AWPROT;
    logic                   AWVALID;
    logic                   AWREADY;

    // Write Data Channel
    logic [DATA_WIDTH-1:0]  WDATA;
    logic [STRB_WIDTH-1:0]  WSTRB;
    logic                   WLAST;
    logic                   WVALID;
    logic                   WREADY;

    // Write Response Channel
    logic [ID_WIDTH-1:0]    BID;
    logic [1:0]             BRESP;
    logic                   BVALID;
    logic                   BREADY;

    // Read Address Channel
    logic [ID_WIDTH-1:0]    ARID;
    logic [ADDR_WIDTH-1:0]  ARADDR;
    logic [7:0]             ARLEN;
    logic [2:0]             ARSIZE;
    logic [1:0]             ARBURST;
    logic                   ARLOCK;
    logic [3:0]             ARCACHE;
    logic [2:0]             ARPROT;
    logic                   ARVALID;
    logic                   ARREADY;

    // Read Data Channel
    logic [ID_WIDTH-1:0]    RID;
    logic [DATA_WIDTH-1:0]  RDATA;
    logic [1:0]             RRESP;
    logic                   RLAST;
    logic                   RVALID;
    logic                   RREADY;

    // Master Driver Clocking Block
    clocking m_drv_cb @(posedge clk);
        output AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWVALID;
        output WDATA, WSTRB, WLAST, WVALID;
        output BREADY;
        output ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT, ARVALID;
        output RREADY;
        
        input AWREADY;
        input WREADY;
        input BID, BRESP, BVALID;
        input ARREADY;
        input RID, RDATA, RRESP, RLAST, RVALID;
    endclocking

    // Monitor Clocking Block
    clocking mon_cb @(posedge clk);
        input AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWVALID;
        input WDATA, WSTRB, WLAST, WVALID;
        input BREADY;
        input ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT, ARVALID;
        input RREADY;
        
        input AWREADY;
        input WREADY;
        input BID, BRESP, BVALID;
        input ARREADY;
        input RID, RDATA, RRESP, RLAST, RVALID;
    endclocking

    // Interface Modports
    modport MDRV(clocking m_drv_cb, input rst);
    modport MON(clocking mon_cb, input rst);

    // Protocol Assertions
    // Address channel stability checks
    property aw_stable;
        @(posedge clk) (AWVALID && !AWREADY) |=> $stable({AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT});
    endproperty
    
    property ar_stable;
        @(posedge clk) (ARVALID && !ARREADY) |=> $stable({ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT});
    endproperty
    
    // Data channel stability checks
    property w_stable;
        @(posedge clk) (WVALID && !WREADY) |=> $stable({WDATA, WSTRB, WLAST});
    endproperty
    
    property r_stable;
        @(posedge clk) (RVALID && !RREADY) |=> $stable({RID, RDATA, RRESP, RLAST});
    endproperty
    
    // Response channel stability checks
    property b_stable;
        @(posedge clk) (BVALID && !BREADY) |=> $stable({BID, BRESP});
    endproperty

    // Assert properties
    assert property(aw_stable) else $error("AXI Protocol Violation: Write address signals changed while AWVALID=1 and AWREADY=0");
    assert property(ar_stable) else $error("AXI Protocol Violation: Read address signals changed while ARVALID=1 and ARREADY=0");
    assert property(w_stable) else $error("AXI Protocol Violation: Write data signals changed while WVALID=1 and WREADY=0");
    assert property(r_stable) else $error("AXI Protocol Violation: Read data signals changed while RVALID=1 and RREADY=0");
    assert property(b_stable) else $error("AXI Protocol Violation: Write response signals changed while BVALID=1 and BREADY=0");

endinterface

`endif // INTERFACES_SV