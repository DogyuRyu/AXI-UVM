/*****************************************************************************
� 2006 Cadence Design Systems, Inc. All rights reserved. 
This work may not be copied, modified, re-published, uploaded, executed, or
distributed in any way, in any medium, whether in whole or in part, without
prior written permission from Cadence Design Systems, Inc.
*****************************************************************************/

/*********************************************************/
// MODULE:      Simple AXI Slave
//
// FILE NAME:   axi_slave_duv.v
// VERSION:     1.0
// DATE:        Nov 01, 2006
// AUTHOR:      Cadence Design Systems, Inc.
// 
// CODE TYPE:   RTL
//
// DESCRIPTION: AXI slave
//
/*********************************************************/

module axi_duv_slave(
		 aclk_i,
		 aresetn_i,
		 awid_i,
		 awaddr_i,
		 awlen_i,
		 awsize_i,
		 awburst_i,
		 awlock_i,
		 awcache_i,
		 awprot_i,
		 awvalid_i,
		 awready_i,
		 awqos_i,
		 awregion_i,
		 awuser_i,
		 wdata_i,
		 wstrb_i,
		 wlast_i,
		 wvalid_i,
		 wready_i,
		 wuser_i,
		 bid_i,
		 bresp_i,
		 bvalid_i,
		 bready_i,
		 buser_i,
		 arid_i,
		 araddr_i,
		 arlen_i,
		 arsize_i,
		 arburst_i,
		 arlock_i,
		 arcache_i,
		 arprot_i,
		 arvalid_i,
		 arready_i,
		 arqos_i,
		 arregion_i,
		 aruser_i,		 
		 rid_i,
		 rdata_i,
		 rresp_i,
		 rlast_i,
		 rvalid_i,
		 rready_i,
		 ruser_i,
		 csysreq_i,
		 csysack_i,
		 cactive_i );
   
   parameter ADDR_WIDTH = 32;  // Address bus width
   parameter DATA_WIDTH = 32;  // Data bus width
   parameter ID_WIDTH   = 4;   // ID supported = 2^ID_WIDTH
   parameter LEN_WIDTH  = 8;   // Numbers of bits for capturing ARLEN/AWLEN
   parameter AWUSER_WIDTH            = 32; // Size of AWUser field
   parameter WUSER_WIDTH             = 32; // Size of WUser field
   parameter BUSER_WIDTH             = 32; // Size of BUser field
   parameter ARUSER_WIDTH            = 32; // Size of ARUser field
   parameter RUSER_WIDTH             = 32; // Size of RUser field
   parameter QOS_WIDTH               = 4;  // Size of QOS field
   parameter REGION_WIDTH            = 4;  // Size of Region field
   parameter MAX_OUTSTANDING_RD_REQ  = 4;  // Maximum pending read request before read 
   parameter MAX_OUTSTANDING_WR_REQ  = 4;  // Maximum pending write request before write 
   parameter MAX_OUTSTANDING_WR_RESP = 4;  // Maximum write response (BRESP) pending after
   parameter MAX_WAIT_CYCLES         = 16; // Maximum number of cycles before READY goes 
   parameter INTERLEAVE_ON        = 1;  
   
   localparam STRB_WIDTH = DATA_WIDTH/8;
   
   //size types
   localparam BYTE_1   = 3'b000,
     BYTE_2   = 3'b001,
     BYTE_4   = 3'b010,
     BYTE_8   = 3'b011,
     BYTE_16  = 3'b100,
     BYTE_32  = 3'b101,
     BYTE_64  = 3'b110,
     BYTE_128 = 3'b111;
   
   //access types
   localparam NORMAL    = 2'b00,
     EXCLUSIVE = 2'b01,
     LOCK      = 2'b10;
   
   //burst types
   localparam FIXED = 2'b00,
     INCR  = 2'b01,
     WRAP  = 2'b10;

   //response type
   localparam OKAY     = 2'b00,
     EXOKAY  = 2'b01,
     SLVERR  = 2'b10,
     DECERR  = 2'b11;
   
   //const for number of bits
   localparam bit_1   = 1;
   localparam bit_2   = 2;
   localparam bit_4   = 4;
   localparam bit_8   = 8;
   localparam bit_16  = 16;
   localparam bit_32  = 32;
   localparam bit_64  = 64;
   localparam bit_128 = 128;

   
   // Global Signals
   input     aclk_i;
   input     aresetn_i;

   //Write address channel ports
   input [ID_WIDTH-1:0] awid_i;
   input [ADDR_WIDTH-1:0] awaddr_i;
   input [LEN_WIDTH-1:0]  awlen_i;
   input [bit_2:0] 	  awsize_i;
   input [bit_1:0] 	  awburst_i;
   input        	  awlock_i;
   input [bit_4-1:0] 	  awcache_i;
   input [bit_2:0] 	  awprot_i;
   input 		  awvalid_i;
   output 		  awready_i;
   input [QOS_WIDTH-1:0]     awqos_i;     // Write address Quality of service
   input [REGION_WIDTH-1:0]  awregion_i;  // Write address slave address region
   input [AWUSER_WIDTH-1:0]  awuser_i;    // Write address user signal
   
   // Write data channel ports
   input [DATA_WIDTH-1:0] wdata_i;
   input [STRB_WIDTH-1:0] wstrb_i;
   input 		  wlast_i;
   input 		  wvalid_i;
   output 		  wready_i;
   input [WUSER_WIDTH-1:0]   wuser_i;     // Write user signal

   // Write response channel ports
   output [ID_WIDTH -1:0] bid_i;
   output [bit_1:0] 	  bresp_i;
   output 		  bvalid_i;
   input 		  bready_i;
   output [BUSER_WIDTH-1:0]   buser_i;     // Write response user signal

   // Read address channel ports
   input [ID_WIDTH-1:0]   arid_i;
   input [ADDR_WIDTH-1:0] araddr_i;
   input [LEN_WIDTH-1:0]  arlen_i;
   input [bit_2:0] 	  arsize_i;
   input [bit_1:0] 	  arburst_i;
   input        	  arlock_i;
   input [bit_4-1:0] 	  arcache_i;
   input [bit_2:0] 	  arprot_i;
   input 		  arvalid_i;
   output 		  arready_i;
   input [QOS_WIDTH-1:0]     arqos_i;     // Write address Quality of service
   input [REGION_WIDTH-1:0]  arregion_i;  // Write address slave address region
   input [AWUSER_WIDTH-1:0]  aruser_i;    // Write address user signal 
   
   // Read data channel ports
   output [ID_WIDTH-1:0]  rid_i;
   output [DATA_WIDTH-1:0] rdata_i;
   output [bit_1:0] 	   rresp_i;
   output 		   rlast_i;
   output 		   rvalid_i;
   input 		   rready_i;
   output [RUSER_WIDTH-1:0]   ruser_i;     // Read user signal

   // Low-power interface ports
   input 		   csysreq_i;
   input 		   csysack_i;
   input 		   cactive_i;

   reg [BUSER_WIDTH-1:0]   buser_i;     // Write response user signal
   reg [RUSER_WIDTH-1:0]   ruser_i;     // Read user signal
   reg 			   wready_i;
   reg [ID_WIDTH -1:0] 	   bid_i;
   reg 			   bvalid_i;
   reg [bit_1:0] 	   bresp_i;
   reg 			   arready_i;
   reg [ID_WIDTH-1:0] 	   rid_i;
   reg [DATA_WIDTH-1:0]    rdata_i;
   reg [bit_1:0] 	   rresp_i;
   reg 			   rlast_i;
   reg 			   rvalid_i;
   reg 			   awready_i;
   
   reg 			   local_bvalid;
   reg 			   local_rvalid;
   reg 			   local_arready;
   reg 			   local_awready;
   reg [MAX_OUTSTANDING_RD_REQ-1:0] count_read;
   reg [MAX_OUTSTANDING_RD_REQ+LEN_WIDTH-1:0] count_rd_data; 
   reg [MAX_OUTSTANDING_WR_REQ-1:0] 	      count_write_req_pending;
   reg [MAX_OUTSTANDING_WR_RESP-1:0] 	      count_write_resp_pending;
   reg [ID_WIDTH+LEN_WIDTH-1:0] 	      resp_len;
   reg [LEN_WIDTH+ID_WIDTH-1:0] 	      mem_read[MAX_OUTSTANDING_RD_REQ-1:0];
   reg [ID_WIDTH-1:0] 			      mem_write[MAX_OUTSTANDING_WR_REQ-1:0];
   integer 				      i;

   
   always @(posedge aclk_i)
     begin
	if(!aresetn_i)
	  begin
	     rvalid_i <= 1'b0;
	     local_rvalid <= 1'b0;
	     rdata_i <= {DATA_WIDTH{1'b0}};
	     rresp_i <= OKAY;
	     ruser_i <= 32'b0;
	     arready_i <= 1'b1;
	     local_arready <= 1'b1;
	     rid_i <= {ID_WIDTH{1'b0}};
	     rlast_i <= 1'b0;
	     for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
	       mem_read[i] <= {(ID_WIDTH+LEN_WIDTH){1'b0}};
	     count_read <= 0;
	     count_rd_data <= {MAX_OUTSTANDING_RD_REQ+LEN_WIDTH{1'b0}};
	     resp_len <= {ID_WIDTH+LEN_WIDTH{1'b0}};
	  end
	else if(arvalid_i)
	  begin
	     arready_i <= 1'b1;
	     local_arready <= 1'b1;
	     if(count_read < MAX_OUTSTANDING_RD_REQ)       
	       begin
		  if(count_read>0)         
		    begin
		       if(count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH]))
			 begin
			    if(rready_i)
			      begin
			 	 count_rd_data <= count_rd_data+1;
				 rvalid_i <= 1'b1;
				 local_rvalid <= 1'b1;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= 1'b1;
				 count_read <= local_arready?count_read+1:count_read;
				 rid_i <= resp_len[ID_WIDTH-1:0];
				 for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
				   if(i==count_read-1)
				     mem_read[i] <= local_arready?{arlen_i,arid_i}:mem_read[i];
				   else if(i==MAX_OUTSTANDING_RD_REQ-1)
				     mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
				   else
				     mem_read[i] <= mem_read[i];
			      end // if (rready_i)
			    else
			      begin
				 count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
				 rvalid_i <= !local_rvalid ? 1'b1:local_rvalid;
				 local_rvalid <= !local_rvalid ? 1'b1:local_rvalid; 
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= !local_rvalid?1'b1:rlast_i; 
				 rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
				 count_read <= local_arready?count_read+1:count_read;
				 for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
				   if(i==count_read-1)
				     mem_read[i] <= {arlen_i,arid_i};
				   else if(i==MAX_OUTSTANDING_RD_REQ-1)
				     mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
				   else
				     mem_read[i] <= mem_read[i];
			      end // else: !if(rready_i)
			 end // if (count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH]))
		       else if(count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
			 begin
			    if(rready_i)
			      begin
			 	 count_rd_data <= 0;
				 rvalid_i <= 1'b0;
				 local_rvalid <= 1'b0;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= 1'b0;
				 count_read <= local_arready?count_read:count_read-1;
				 resp_len <= (count_read==1)?{arlen_i,arid_i}:mem_read[0];
				 for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
				   if(i== ((count_read==1)?count_read-1:count_read-2))
				     mem_read[i] <= (count_read==1)?mem_read[i]:{arlen_i,arid_i};
				   else if(i==MAX_OUTSTANDING_RD_REQ-1)
				     mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
				   else
				     mem_read[i] <= mem_read[i+1];
			      end // if (rready_i)
			    else
			      begin
				 count_rd_data <= count_rd_data;
				 rvalid_i <= rvalid_i;
				 local_rvalid <= local_rvalid;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= rlast_i;
				 count_read <= local_arready?count_read+1:count_read;
				 for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
				   if(i==count_read-1)
				     mem_read[i] <= {arlen_i,arid_i};
				   else if(i==MAX_OUTSTANDING_RD_REQ-1)
				     mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
				   else
				     mem_read[i] <= mem_read[i];
			      end // else: !if(rready_i)
			 end // if (count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
		       else
			 begin
			    if(rready_i)
			      begin
			 	 count_rd_data <= count_rd_data+1;
				 rvalid_i <= 1'b1;
				 local_rvalid <= 1'b1;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= 1'b0;
				 rid_i <= resp_len[ID_WIDTH-1:0];
				 count_read <= local_arready?count_read+1:count_read;
				 for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
				   if(i==count_read-1)
				     mem_read[i] <= {arlen_i,arid_i};
				   else if(i==MAX_OUTSTANDING_RD_REQ-1)
				     mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
				   else
				     mem_read[i] <= mem_read[i];
			      end // if (rready_i)
			    else
			      begin
				 count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
				 rvalid_i <= !local_rvalid?1'b1:rvalid_i;
				 local_rvalid <= !local_rvalid?1'b1:local_rvalid;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
				 rlast_i <= !local_rvalid?1'b0:rlast_i;
				 count_read <= local_arready?count_read+1:count_read;
				 for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
				   if(i==count_read-1)
				     mem_read[i] <= {arlen_i,arid_i};
				   else if(i==MAX_OUTSTANDING_RD_REQ-1)
				     mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
				   else
				     mem_read[i] <= mem_read[i];
			      end // else: !if(rready_i)
			 end // else: !if(count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
		    end // if (count_read>0)
		  else 
		    begin
		       rvalid_i <= 1'b0;
		       local_rvalid <= 1'b0;
		       rresp_i <= OKAY;
		       ruser_i <= 32'b0;
		       rdata_i <= {DATA_WIDTH{1'b0}};
		       rlast_i <= 1'b0;
		       count_read <= local_arready?1:0;
		       resp_len <= local_arready?{arlen_i,arid_i}:resp_len;
		    end // else: !if(count_read>0)
	       end // if (count_read < MAX_OUTSTANDING_RD_REQ)
	     else 
	       begin
		  if(count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH]))
		    begin
		       if(rready_i)
			 begin
			    count_rd_data <= count_rd_data+1;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rid_i <= resp_len[ID_WIDTH-1:0];
			    rlast_i <= 1'b1;
			    rvalid_i <= 1'b1;
			    local_rvalid <= 1'b1;
			 end
		       else
			 begin
			    count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rlast_i <= !local_rvalid?1'b1:rlast_i;
			    rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
			    rvalid_i <= !local_rvalid?1'b1:rvalid_i;
			    local_rvalid <= !local_rvalid?1'b1:local_rvalid;
			 end // else: !if(rready_i)
		    end // if (count_rd_data < resp_len)
		  else if(count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1)
		    begin
		       if(rready_i)
			 begin
			    count_rd_data <= 0;
			    rvalid_i <=1'b0;
			    local_rvalid <= 1'b0;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rid_i <= resp_len[ID_WIDTH-1:0];
			    rlast_i <= 1'b0;
			    resp_len <= (count_read==1)?{arlen_i,arid_i}:mem_read[0];
			    count_read <= (local_arready && arvalid_i)?count_read:count_read-1;
			    for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
			      if(i== ((count_read==1)?count_read-1:count_read-2))      
				mem_read[i] <= (local_arready && arvalid_i)?(count_read==1)?mem_read[i]:{arlen_i,arid_i}:mem_read[i];
			      else if(i==MAX_OUTSTANDING_RD_REQ-1)
				mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
			      else
				mem_read[i] <= mem_read[i+1];
			 end
		       else
			 begin
			    count_rd_data <= count_rd_data;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rlast_i <= rlast_i;
			    rvalid_i <= rvalid_i;
			    local_rvalid <= local_rvalid;
			 end // else: !if(rready_i)
		    end // if (count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1)
		  else
		    begin
		       if(rready_i)
			 begin
			    count_rd_data <= count_rd_data+1;
			    rvalid_i <=1'b1;
			    local_rvalid <=1'b1;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rid_i <= resp_len[ID_WIDTH-1:0];
			    rlast_i <= 1'b0;
			 end
		       else
			 begin
			    count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rlast_i <= !local_rvalid?1'b0:rlast_i;
			    rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
			    rvalid_i <= !local_rvalid?1'b1:rvalid_i;
			    local_rvalid <=!local_rvalid?1'b1:local_rvalid;
			 end // else: !if(rready_i)
		    end // else: !if(count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1)
	       end // else: !if(count_read < MAX_OUTSTANDING_RD_REQ)
	  end // if (arvalid_i)
	else  
	  begin
	     if(count_read < MAX_OUTSTANDING_RD_REQ)
	       begin
		  arready_i <= 1'b1;
		  local_arready <= 1'b1;
		  if(count_read>0) 
		    begin
		       if(count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH]))
			 begin
			    if(rready_i)
			      begin
			 	 count_rd_data <= count_rd_data+1;
				 rvalid_i <= 1'b1;
				 local_rvalid <=1'b1;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rid_i <= resp_len[ID_WIDTH-1:0];
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= 1'b1;
				 count_read <= count_read;
			      end // if (rready_i)
			    else
			      begin
				 count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
				 rvalid_i <= !local_rvalid?1'b1:rvalid_i;
				 local_rvalid <=!local_rvalid?1'b1:local_rvalid;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= !local_rvalid?1'b1:rlast_i;
				 count_read <= count_read;
			      end
			 end // if (count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH]))
		       else if(count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
			 begin
			    if(rready_i)
			      begin
				 count_rd_data <= 0;
				 rvalid_i <= 1'b0;
				 local_rvalid <=1'b0;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= 1'b0;
				 count_read <= count_read-1;
				 resp_len <= mem_read[0];
				 for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
				   if(i==MAX_OUTSTANDING_RD_REQ-1)
				     mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
				   else
				     mem_read[i] <= mem_read[i+1];
			      end // if (rready_i)
			    else
			      begin
				 count_rd_data <= count_rd_data;
				 rvalid_i <= rvalid_i;
				 local_rvalid <=local_rvalid;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= rlast_i;
				 count_read <= count_read;
			      end // else: !if(rready_i)
			 end // if (count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
		       else
			 begin
			    if(rready_i)
			      begin
			 	 count_rd_data <= count_rd_data+1;
				 rvalid_i <= 1'b1;
				 local_rvalid <=1'b1;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rid_i <= resp_len[ID_WIDTH-1:0];
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rlast_i <= 1'b0;
				 count_read <= count_read;
			      end // if (rready_i)
			    else
			      begin
				 count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
				 rvalid_i <= !local_rvalid?1'b1:rvalid_i;
				 local_rvalid <= !local_rvalid?1'b1:local_rvalid;
				 rresp_i <= OKAY;
				 ruser_i <= 32'b0;
				 rdata_i <= {DATA_WIDTH{1'b1}};
				 rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
				 rlast_i <= !local_rvalid?1'b0:rlast_i;
				 count_read <= count_read;
			      end // else: !if(rready_i)
			 end // else: !if(count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
		    end // if (count_read>0)
		  else  
		    begin
		       rvalid_i <= 1'b0;
		       local_rvalid <= 1'b0;
		       rresp_i <= OKAY;
		       ruser_i <= 32'b0;
		       rdata_i <= {DATA_WIDTH{1'b1}};
		       rlast_i <= 1'b0;
		       count_read <= 0;
		    end // else: !if(count_read>0)
	       end // if (count_read < MAX_OUTSTANDING_RD_REQ)
	     else  
	       begin
		  if(count_rd_data == (resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH]))
		    begin
		       if(rready_i)
			 begin
			    count_rd_data <= count_rd_data+1;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rid_i <= resp_len[ID_WIDTH-1:0];
			    rlast_i <= 1'b1;
			    rvalid_i <= 1'b1;
			    local_rvalid <= 1'b1;
			 end
		       else
			 begin
			    count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rlast_i <= !local_rvalid?1'b1:rlast_i;
			    rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
			    rvalid_i <= !local_rvalid?1'b1:rvalid_i;
			    local_rvalid <= !local_rvalid?1'b1:local_rvalid;
			 end // else: !if(rready_i)
		    end // if (count_rd_data < resp_len)
		  else if(count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
		    begin
		     if(rready_i)
		       begin
			  count_rd_data <= 0;
			  rvalid_i <= 1'b0;
			  local_rvalid <= 1'b0;
			  rresp_i <= OKAY;
			  ruser_i <= 32'b0;
			  rdata_i <= {DATA_WIDTH{1'b1}};
			  rlast_i <= 1'b0;
			  rid_i <= resp_len[ID_WIDTH-1:0];
			  resp_len <= mem_read[0];
			  count_read <= count_read-1;
			  for(i=0;i<MAX_OUTSTANDING_RD_REQ;i=i+1)
			    if(i==MAX_OUTSTANDING_RD_REQ-1)
			      mem_read[i] <= {MAX_OUTSTANDING_RD_REQ{1'b0}};
			    else
			      mem_read[i] <= mem_read[i+1];
		       end
		     else
		       begin
			  count_rd_data <= count_rd_data;
			  rresp_i <= OKAY;
			  ruser_i <= 32'b0;
			  rdata_i <= {DATA_WIDTH{1'b1}};
			  rlast_i <= rlast_i;
			  rvalid_i <= rvalid_i;
			  local_rvalid <= local_rvalid;
		       end // else: !if(rready_i)
		  end // if (count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
		  else
		    begin
		       if(rready_i)
			 begin
			    count_rd_data <= count_rd_data+1;
			    rvalid_i <= 1'b1;
			    local_rvalid <= 1'b1;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rid_i <= resp_len[ID_WIDTH-1:0];
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rlast_i <= 1'b0;
			    count_read <= count_read;
			 end // if (rready_i)
		       else
			 begin
			    count_rd_data <= !local_rvalid?count_rd_data+1:count_rd_data;
			    rvalid_i <= !local_rvalid?1'b1:rvalid_i;
			    local_rvalid <= !local_rvalid?1'b1:local_rvalid;
			    rresp_i <= OKAY;
			    ruser_i <= 32'b0;
			    rid_i   <= !local_rvalid?resp_len[ID_WIDTH:0]:rid_i;
			    rdata_i <= {DATA_WIDTH{1'b1}};
			    rlast_i <= !local_rvalid?1'b0:rlast_i;
			    count_read <= count_read;
			 end // else: !if(rready_i)
		    end // else: !if(count_rd_data == ((resp_len[ID_WIDTH+LEN_WIDTH-1:ID_WIDTH])+1))
	       end // else: !if(count_read < MAX_OUTSTANDING_RD_REQ)
	  end // else: !if(arvalid_i)
     end // always @ (posedge aclk_i)
   
   
   always@(posedge aclk_i)
     begin
	if(!aresetn_i)
	  begin
	     wready_i     <= 1'b1;
	     bvalid_i     <= 1'b0;
	     local_bvalid <= 1'b0;
	     bresp_i      <= OKAY;
	     buser_i      <= 32'b0;
	     bid_i         <= {ID_WIDTH{1'b0}};
	     count_write_resp_pending <= {MAX_OUTSTANDING_WR_REQ{1'b0}};
	     for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
	       mem_write[i] <= {ID_WIDTH{1'b0}};
	  end
	else if(bready_i)
	  begin
	     if(count_write_resp_pending>0)
	       begin
		  bvalid_i <= (count_write_resp_pending>1)?1'b1:!local_bvalid?1'b1:1'b0;
		  local_bvalid <= (count_write_resp_pending>1)?1'b1:!local_bvalid?1'b1:1'b0;
		  if(wvalid_i)
		    begin
		       wready_i <= 1'b1;
		       if(wlast_i)
			 begin
			    count_write_resp_pending <= (local_bvalid) ? count_write_resp_pending:count_write_resp_pending+1;
			    bid_i <= mem_write[0];
			    bresp_i <= OKAY;
			    buser_i      <= 32'b0;
			    for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
			      if(i==(local_bvalid ? (count_write_resp_pending==1)?count_write_resp_pending-1:count_write_resp_pending-2:count_write_resp_pending-1))
				mem_write[i] <= awid_i;
			      else if(i == MAX_OUTSTANDING_WR_REQ-1)
				mem_write[i] <= {ID_WIDTH{1'b0}};
			      else
				mem_write[i] <= local_bvalid?mem_write[i+1]:mem_write[i];
			 end // if (wlast_i)
		       else
			 begin
			    count_write_resp_pending <= (local_bvalid)?count_write_resp_pending-1:count_write_resp_pending;
			    bid_i <= mem_write[0];
			    bresp_i <= OKAY;
			    buser_i      <= 32'b0;
			    for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
			      if(i == MAX_OUTSTANDING_WR_REQ-1)
				mem_write[i] <= {ID_WIDTH{1'b0}};
			      else
				mem_write[i] <= local_bvalid?mem_write[i+1]:mem_write[i];
			 end
		    end // if (wvalid_i)
		  else
		    begin
		       count_write_resp_pending <= (local_bvalid)?count_write_resp_pending-1:count_write_resp_pending;
		       bid_i          <= mem_write[0];
		       bresp_i        <= OKAY;
		       buser_i      <= 32'b0;
		       for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
			 if(i == MAX_OUTSTANDING_WR_REQ-1)
			   mem_write[i] <= {ID_WIDTH{1'b0}};
			 else
			   mem_write[i] <= mem_write[i+1];
		    end // else: !if(wvalid_i)
	       end // if (count_write_resp_pending>0)
	     else 
	       begin
		  if(wvalid_i)
		    begin
		       wready_i <= 1'b1;
		       if(wlast_i)
			 begin
			    bvalid_i <= 1'b1;
			    local_bvalid <= 1'b1;
			    bid_i <= awid_i;
			    count_write_resp_pending <= 1;
			 end
		       else
			 begin
			    bvalid_i <= 1'b0;
			    local_bvalid <= 1'b0;
			    count_write_resp_pending <= 0;
			 end // else: !if(wlast_i)
		    end // if (wvalid_i)
		  else
		    begin
		       bvalid_i <= 1'b0;
		       local_bvalid <= 1'b0;
		       count_write_resp_pending <= 0;
		    end // else: !if(wvalid_i)
	       end // else: !if(count_write_resp_pending >0)
	  end // if (bready_i)
	else 
	  begin
	     if(count_write_resp_pending >0)
	       begin
		  bvalid_i <= !local_bvalid ? 1'b1:bvalid_i;
		  local_bvalid <= !local_bvalid?1'b1:local_bvalid;
		  if(wvalid_i)
		    begin
		       wready_i <= 1'b1;
		       if(wlast_i)
			 begin
			    bid_i <= !local_bvalid ? mem_write[0]:bid_i;
			    for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
			      if(i==count_write_resp_pending-1)
				mem_write[i] <= awid_i;
			      else if(i==(MAX_OUTSTANDING_WR_REQ-1))
				mem_write[i] <= {MAX_OUTSTANDING_WR_REQ{1'b0}};
			      else 
				mem_write[i] <= !local_bvalid?mem_write[i+1]:mem_write[i];
			    count_write_resp_pending <=  count_write_resp_pending+1;
			    bresp_i <= OKAY;
			    buser_i      <= 32'b0;
			 end
		       else
			 begin
			    bid_i <= !local_bvalid ? mem_write[0]:bid_i;
			    for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
			      if(i==(MAX_OUTSTANDING_WR_REQ-1))
				mem_write[i] <= {MAX_OUTSTANDING_WR_REQ{1'b0}};
			      else
				mem_write[i] <= !local_bvalid?mem_write[i+1]:mem_write[i];
			    count_write_resp_pending <=  count_write_resp_pending;
			    bresp_i <= OKAY;
			    buser_i      <= 32'b0;
			 end // else: !if(wlast_i)
		    end // if (wvalid_i)
		  else
		    begin
		       bid_i <= !local_bvalid ? mem_write[0]:bid_i;
		       for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
			 if(i==(MAX_OUTSTANDING_WR_REQ-1))
			   mem_write[i] <= {MAX_OUTSTANDING_WR_REQ{1'b0}};
			 else 
			   mem_write[i] <= !local_bvalid?mem_write[i+1]:mem_write[i];
		       count_write_resp_pending <=  count_write_resp_pending;
		       bresp_i <= OKAY;
		       buser_i      <= 32'b0;
		    end // else: !if(wvalid_i)
	       end // if (count_write_resp_pending >0)
	     else 
	       begin
		  bvalid_i <= bvalid_i;
		  local_bvalid <= local_bvalid;
		  if(wvalid_i)
		    begin
		       wready_i <= 1'b1;
		       if(wlast_i)
			 begin
			    for(i=0;i<MAX_OUTSTANDING_WR_REQ;i=i+1)
			      if(i==0)
				mem_write[i] <= awid_i;
			      else 
				mem_write[i] <= mem_write[i];
			    count_write_resp_pending <=  count_write_resp_pending+1;
			 end // if (wlast_i)
		       else
			 count_write_resp_pending <=  0;
		    end // if (wvalid_i)
		  else
		    count_write_resp_pending <=  0;
	       end // if (count_write_resp_pending >0)
	  end // else: !if(bready_i)
     end // always@ (posedge aclk_i)

   always@(posedge aclk_i)
     begin
	if(!aresetn_i)
	  begin
	     awready_i    <= 1'b1;
	     local_awready <= 1'b1;
	     count_write_req_pending <= {MAX_OUTSTANDING_WR_REQ{1'b0}};
	  end
	else 
	  begin
	     awready_i <= 1'b1;
	     local_awready <= 1'b1;
	     if(awvalid_i && local_awready)
	       count_write_req_pending <= (local_bvalid && bready_i) ? count_write_req_pending:count_write_req_pending+1;
	     else
	       count_write_req_pending <= (local_bvalid && bready_i) ? count_write_req_pending-1:count_write_req_pending;
	  end
     end // always@ (posedge aclk_i)
   assign awid_i = 4'b0001;
endmodule // axi_duv_slave

