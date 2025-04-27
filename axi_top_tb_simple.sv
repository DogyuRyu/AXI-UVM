`timescale 1ns/1ps

module axi_top_tb_simple;
  // Clock and reset signals
  bit clk;  // 'bit' type with initial value of 0
  bit rstn; // 'bit' type with initial value of 0
  
  // Clock generation
  always #5 clk = ~clk;  // 100MHz clock
  
  // Reset generation
  initial begin
    rstn = 0;
    #50;
    rstn = 1;
  end
  
  // AXI interface instantiation
  AXI4 #(.N(8), .I(8)) axi_if(.ACLK(clk), .ARESETn(rstn));
  
  // BFM instantiation
  Axi4MasterBFM #(.N(8), .I(8)) master_bfm(axi_if);
  Axi4SlaveBFM #(.N(8), .I(8)) slave_bfm(axi_if);
  
  // Enum type to track test stages
  typedef enum {
    SINGLE_WRITE,
    SINGLE_READ,
    INCR_BURST_WRITE,
    INCR_BURST_READ,
    WRAP_BURST_WRITE,
    WRAP_BURST_READ,
    FIXED_BURST_WRITE,
    FIXED_BURST_READ,
    UNALIGNED_WRITE,
    UNALIGNED_READ,
    NARROW_WRITE,
    NARROW_READ,
    DIFFERENT_ID_WRITE,
    DIFFERENT_ID_READ,
    TEST_DONE
  } test_stage_t;
  
  // Basic test sequence
  initial begin
    import pkg_Axi4Types::*;
    
    // Test stage variable
    test_stage_t current_test;
    
    // Object declarations with parameterized types
    ABeat #(.N(8), .I(8)) ar_beat;
    ABeat #(.N(8), .I(8)) aw_beat;
    WBeat #(.N(8)) w_beat;
    BBeat #(.I(8)) b_beat;
    RBeat #(.N(8), .I(8)) r_beat;
    
    // Test data
    bit [63:0] test_data [16];
    bit [63:0] read_data [16];
    bit [63:0] expected_data; // Pre-declare
    
    // Test initialization
    current_test = SINGLE_WRITE;
    
    // Initialize test data
    for(int i=0; i<16; i++) begin
      test_data[i] = 64'hDEAD_BEEF_0000_0000 + i;
    end
    
    // Basic delay
    #100;
    $display("\n=== AXI4 Test Start - Time: %0t ===", $time);
    
    //--------------------------------------------------------------------------
    // Test 1: Single Write/Read Transaction
    //--------------------------------------------------------------------------
    $display("\n--- Test 1: Single Write/Read Transaction ---");
    
    // Write data to memory - ID 0, address 0x1000
    aw_beat = new();
    aw_beat.id = 0;
    aw_beat.addr = 32'h1000;
    aw_beat.len = 0;  // Single transfer
    aw_beat.size = 3; // 8 bytes
    aw_beat.burst = 1; // INCR mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: Single Write Request - Address=0x%h, Data=0x%h", $time, aw_beat.addr, test_data[0]);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = test_data[0];
    w_beat.strb = 8'hFF;
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: Single Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // Read data from memory - ID 0, address 0x1000
    ar_beat = new();
    ar_beat.id = 0;
    ar_beat.addr = 32'h1000;
    ar_beat.len = 0;  // Single transfer
    ar_beat.size = 3; // 8 bytes
    ar_beat.burst = 1; // INCR mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: Single Read Request - Address=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // Wait for read response
    master_bfm.Rmbx.get(r_beat);
    read_data[0] = r_beat.data;
    $display("Time %0t: Single Read Response Received - ID=%0d, Data=0x%h, Response Code=%0d, Last=%0d", 
             $time, r_beat.id, r_beat.data, r_beat.resp, r_beat.last);
    
    // Data verification
    if(read_data[0] == test_data[0])
      $display("Data Verification Success: 0x%h == 0x%h", read_data[0], test_data[0]);
    else
      $display("Data Verification Failed: 0x%h != 0x%h", read_data[0], test_data[0]);
    
    //--------------------------------------------------------------------------
    // Test 2: INCR Burst Write/Read Transaction
    //--------------------------------------------------------------------------
    $display("\n--- Test 2: INCR Burst Write/Read Transaction ---");
    
    // Write data to memory - ID 1, address 0x2000, burst length 7 (8 transfers)
    aw_beat = new();
    aw_beat.id = 1;
    aw_beat.addr = 32'h2000;
    aw_beat.len = 7;  // 8 transfers
    aw_beat.size = 3; // 8 bytes
    aw_beat.burst = 1; // INCR mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: INCR Burst Write Request - Address=0x%h, Length=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 8 data transfers
    for(int i=0; i<8; i++) begin
      w_beat = new();
      w_beat.data = test_data[i];
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 7); // Set last only for the last transfer
      
      $display("Time %0t: INCR Burst Write Data Transfer #%0d - Data=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: INCR Burst Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // Read data from memory - ID 1, address 0x2000, burst length 7 (8 transfers)
    ar_beat = new();
    ar_beat.id = 1;
    ar_beat.addr = 32'h2000;
    ar_beat.len = 7;  // 8 transfers
    ar_beat.size = 3; // 8 bytes
    ar_beat.burst = 1; // INCR mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: INCR Burst Read Request - Address=0x%h, Length=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // Receive 8 data responses
    for(int i=0; i<8; i++) begin
      master_bfm.Rmbx.get(r_beat);
      read_data[i] = r_beat.data;
      $display("Time %0t: INCR Burst Read Response #%0d - Data=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // Data verification
      if(read_data[i] == test_data[i])
        $display("Data Verification Success: 0x%h == 0x%h", read_data[i], test_data[i]);
      else
        $display("Data Verification Failed: 0x%h != 0x%h", read_data[i], test_data[i]);
    end
    
    //--------------------------------------------------------------------------
    // Test 3: WRAP Burst Write/Read Transaction
    //--------------------------------------------------------------------------
    $display("\n--- Test 3: WRAP Burst Write/Read Transaction ---");
    
    // Write data to memory - ID 2, address 0x3010, burst length 3 (4 transfers), WRAP type
    aw_beat = new();
    aw_beat.id = 2;
    aw_beat.addr = 32'h3010;  // Range 0x3010 ~ 0x3020
    aw_beat.len = 3;          // 4 transfers
    aw_beat.size = 3;         // 8 bytes
    aw_beat.burst = 2;        // WRAP mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: WRAP Burst Write Request - Address=0x%h, Length=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 4 data transfers
    for(int i=0; i<4; i++) begin
      w_beat = new();
      w_beat.data = test_data[i+8];  // Use different data
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 3); // Set last only for the last transfer
      
      $display("Time %0t: WRAP Burst Write Data Transfer #%0d - Data=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: WRAP Burst Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // Read data from memory - ID 2, address 0x3010, burst length 3 (4 transfers), WRAP type
    ar_beat = new();
    ar_beat.id = 2;
    ar_beat.addr = 32'h3010;
    ar_beat.len = 3;  // 4 transfers
    ar_beat.size = 3; // 8 bytes
    ar_beat.burst = 2; // WRAP mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: WRAP Burst Read Request - Address=0x%h, Length=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // Receive 4 data responses
    for(int i=0; i<4; i++) begin
      master_bfm.Rmbx.get(r_beat);
      read_data[i+8] = r_beat.data;
      $display("Time %0t: WRAP Burst Read Response #%0d - Data=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // Data verification
      if(read_data[i+8] == test_data[i+8])
        $display("Data Verification Success: 0x%h == 0x%h", read_data[i+8], test_data[i+8]);
      else
        $display("Data Verification Failed: 0x%h != 0x%h", read_data[i+8], test_data[i+8]);
    end
    
    //--------------------------------------------------------------------------
    // Test 4: FIXED Burst Write/Read Transaction
    //--------------------------------------------------------------------------
    $display("\n--- Test 4: FIXED Burst Write/Read Transaction ---");
    
    // Write data to memory - ID 3, address 0x4000, burst length 3 (4 transfers), FIXED type
    aw_beat = new();
    aw_beat.id = 3;
    aw_beat.addr = 32'h4000;
    aw_beat.len = 3;  // 4 transfers
    aw_beat.size = 3; // 8 bytes
    aw_beat.burst = 0; // FIXED mode - repeated access to same address
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: FIXED Burst Write Request - Address=0x%h, Length=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 4 data transfers (only the last value is valid since writing to the same address)
    for(int i=0; i<4; i++) begin
      w_beat = new();
      w_beat.data = test_data[i+12];  // Use different data
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 3); // Set last only for the last transfer
      
      $display("Time %0t: FIXED Burst Write Data Transfer #%0d - Data=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: FIXED Burst Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // Read data from memory - ID 3, address 0x4000, burst length 3 (4 transfers), FIXED type
    ar_beat = new();
    ar_beat.id = 3;
    ar_beat.addr = 32'h4000;
    ar_beat.len = 3;  // 4 transfers
    ar_beat.size = 3; // 8 bytes
    ar_beat.burst = 0; // FIXED mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: FIXED Burst Read Request - Address=0x%h, Length=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // Receive 4 data responses (reading the same data 4 times)
    for(int i=0; i<4; i++) begin
      master_bfm.Rmbx.get(r_beat);
      read_data[i+12] = r_beat.data;
      $display("Time %0t: FIXED Burst Read Response #%0d - Data=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // Data verification (all responses should match the last written data)
      if(read_data[i+12] == test_data[15])
        $display("Data Verification Success: 0x%h == 0x%h", read_data[i+12], test_data[15]);
      else
        $display("Data Verification Failed: 0x%h != 0x%h", read_data[i+12], test_data[15]);
    end
    
    //--------------------------------------------------------------------------
    // Test 5: Various Sized Transactions
    //--------------------------------------------------------------------------
    $display("\n--- Test 5: Various Sized Transactions ---");
    
    // 1-byte write/read
    aw_beat = new();
    aw_beat.id = 4;
    aw_beat.addr = 32'h5000;
    aw_beat.len = 0;  // Single transfer
    aw_beat.size = 0; // 1 byte (2^0)
    aw_beat.burst = 1; // INCR mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: 1-byte Write Request - Address=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h12; // Only first byte valid
    w_beat.strb = 8'h01;  // Only first byte active
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: 1-byte Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // 1-byte read
    ar_beat = new();
    ar_beat.id = 4;
    ar_beat.addr = 32'h5000;
    ar_beat.len = 0;  // Single transfer
    ar_beat.size = 0; // 1 byte
    ar_beat.burst = 1; // INCR mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: 1-byte Read Request - Address=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // Wait for read response
    master_bfm.Rmbx.get(r_beat);
    $display("Time %0t: 1-byte Read Response Received - Data=0x%h", $time, r_beat.data & 8'hFF);
    
    // Data verification (first byte only)
    if((r_beat.data & 8'hFF) == 8'h12)
      $display("Data Verification Success: 0x%h == 0x%h", r_beat.data & 8'hFF, 8'h12);
    else
      $display("Data Verification Failed: 0x%h != 0x%h", r_beat.data & 8'hFF, 8'h12);
    
    //--------------------------------------------------------------------------
    // Test 6: 2-byte write/read
    //--------------------------------------------------------------------------
    
    // 2-byte write
    aw_beat = new();
    aw_beat.id = 5;
    aw_beat.addr = 32'h5010;
    aw_beat.len = 0;  // Single transfer
    aw_beat.size = 1; // 2 bytes (2^1)
    aw_beat.burst = 1; // INCR mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: 2-byte Write Request - Address=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h1234; // Only first two bytes valid
    w_beat.strb = 8'h03;    // Only first two bytes active
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: 2-byte Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // 2-byte read
    ar_beat = new();
    ar_beat.id = 5;
    ar_beat.addr = 32'h5010;
    ar_beat.len = 0;  // Single transfer
    ar_beat.size = 1; // 2 bytes
    ar_beat.burst = 1; // INCR mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: 2-byte Read Request - Address=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // Wait for read response
    master_bfm.Rmbx.get(r_beat);
    $display("Time %0t: 2-byte Read Response Received - Data=0x%h", $time, r_beat.data & 16'hFFFF);
    
    // Data verification (first 2 bytes only)
    if((r_beat.data & 16'hFFFF) == 16'h1234)
      $display("Data Verification Success: 0x%h == 0x%h", r_beat.data & 16'hFFFF, 16'h1234);
    else
      $display("Data Verification Failed: 0x%h != 0x%h", r_beat.data & 16'hFFFF, 16'h1234);
    
    //--------------------------------------------------------------------------
    // Test 7: 4-byte write/read
    //--------------------------------------------------------------------------
    
    // 4-byte write
    aw_beat = new();
    aw_beat.id = 6;
    aw_beat.addr = 32'h5020;
    aw_beat.len = 0;  // Single transfer
    aw_beat.size = 2; // 4 bytes (2^2)
    aw_beat.burst = 1; // INCR mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: 4-byte Write Request - Address=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h12345678; // Only first 4 bytes valid
    w_beat.strb = 8'h0F;        // Only first 4 bytes active
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: 4-byte Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // 4-byte read
    ar_beat = new();
    ar_beat.id = 6;
    ar_beat.addr = 32'h5020;
    ar_beat.len = 0;  // Single transfer
    ar_beat.size = 2; // 4 bytes
    ar_beat.burst = 1; // INCR mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: 4-byte Read Request - Address=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // Wait for read response
    master_bfm.Rmbx.get(r_beat);
    $display("Time %0t: 4-byte Read Response Received - Data=0x%h", $time, r_beat.data & 32'hFFFFFFFF);
    
    // Data verification (first 4 bytes only)
    if((r_beat.data & 32'hFFFFFFFF) == 32'h12345678)
      $display("Data Verification Success: 0x%h == 0x%h", r_beat.data & 32'hFFFFFFFF, 32'h12345678);
    else
      $display("Data Verification Failed: 0x%h != 0x%h", r_beat.data & 32'hFFFFFFFF, 32'h12345678);
    
    //--------------------------------------------------------------------------
    // Test 8: Unaligned Address Transaction
    //--------------------------------------------------------------------------
    $display("\n--- Test 8: Unaligned Address Transaction ---");
    
    // Write to unaligned address with 4 bytes
    aw_beat = new();
    aw_beat.id = 7;
    aw_beat.addr = 32'h5021;  // Byte unaligned
    aw_beat.len = 0;  // Single transfer
    aw_beat.size = 2; // 4 bytes (2^2)
    aw_beat.burst = 1; // INCR mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: Unaligned Address Write Request - Address=0x%h", $time, aw_beat.addr);
    master_bfm.AWmbx.put(aw_beat);
    
    w_beat = new();
    w_beat.data = 64'h87654321; // 4 bytes data
    w_beat.strb = 8'h1E;        // Bytes 1-4 active
    w_beat.last = 1;
    master_bfm.Wmbx.put(w_beat);
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: Unaligned Address Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #100;
    
    // Read from unaligned address with 4 bytes
    ar_beat = new();
    ar_beat.id = 7;
    ar_beat.addr = 32'h5021;  // Byte unaligned
    ar_beat.len = 0;  // Single transfer
    ar_beat.size = 2; // 4 bytes
    ar_beat.burst = 1; // INCR mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: Unaligned Address Read Request - Address=0x%h", $time, ar_beat.addr);
    master_bfm.ARmbx.put(ar_beat);
    
    // Wait for read response
    master_bfm.Rmbx.get(r_beat);
    $display("Time %0t: Unaligned Address Read Response Received - Data=0x%h", $time, r_beat.data & 32'hFFFFFFFF);
    
    // Data verification (bytes 1-4)
    expected_data = ((64'h87654321 & 32'h00FFFFFF) << 8);
    if(((r_beat.data) & 32'hFFFFFF00) == expected_data)
      $display("Data Verification Success: 0x%h == 0x%h", (r_beat.data) & 32'hFFFFFF00, expected_data);
    else
      $display("Data Verification Failed: 0x%h != 0x%h", (r_beat.data) & 32'hFFFFFF00, expected_data);
    
    //--------------------------------------------------------------------------
    // Test 9: Multiple ID Transactions
    //--------------------------------------------------------------------------
    $display("\n--- Test 9: Multiple ID Transactions ---");
    
    // Send read requests with 3 different IDs
    for(int i=0; i<3; i++) begin
      ar_beat = new();
      ar_beat.id = i + 10;  // IDs 10, 11, 12
      ar_beat.addr = 32'h6000 + (i * 8); // Addresses 0x6000, 0x6008, 0x6010
      ar_beat.len = 0;  // Single transfer
      ar_beat.size = 3; // 8 bytes
      ar_beat.burst = 1; // INCR mode
      ar_beat.lock = 0;
      ar_beat.cache = 0;
      ar_beat.prot = 0;
      ar_beat.qos = 0;
      ar_beat.region = 0;
      
      // Write data first
      aw_beat = new();
      aw_beat.id = i + 10;  // Use same ID
      aw_beat.addr = ar_beat.addr;
      aw_beat.len = 0;
      aw_beat.size = 3;
      aw_beat.burst = 1;
      aw_beat.lock = 0;
      aw_beat.cache = 0;
      aw_beat.prot = 0;
      aw_beat.qos = 0;
      aw_beat.region = 0;
      
      $display("Time %0t: Writing data with ID %0d to address 0x%h", $time, aw_beat.id, aw_beat.addr);
      master_bfm.AWmbx.put(aw_beat);
      
      w_beat = new();
      w_beat.data = 64'hA000_0000_0000_0000 | aw_beat.id; // Data includes ID
      w_beat.strb = 8'hFF;
      w_beat.last = 1;
      master_bfm.Wmbx.put(w_beat);
    end
    
    // Receive 3 responses
    for(int i=0; i<3; i++) begin
      master_bfm.Bmbx.get(b_beat);
      $display("Time %0t: Write Response Received for ID %0d - Response Code=%0d", $time, b_beat.id, b_beat.resp);
    end
    
    // Delay
    #100;
    
    // Read requests with 3 different IDs
    for(int i=0; i<3; i++) begin
      ar_beat = new();
      ar_beat.id = i + 10;  // IDs 10, 11, 12
      ar_beat.addr = 32'h6000 + (i * 8); // Addresses 0x6000, 0x6008, 0x6010
      ar_beat.len = 0;  // Single transfer
      ar_beat.size = 3; // 8 bytes
      ar_beat.burst = 1; // INCR mode
      ar_beat.lock = 0;
      ar_beat.cache = 0;
      ar_beat.prot = 0;
      ar_beat.qos = 0;
      ar_beat.region = 0;
      
      $display("Time %0t: Reading data with ID %0d from address 0x%h", $time, ar_beat.id, ar_beat.addr);
      master_bfm.ARmbx.put(ar_beat);
    end
    
    // Receive 3 responses (order may vary depending on ID)
    for(int i=0; i<3; i++) begin
      master_bfm.Rmbx.get(r_beat);
      $display("Time %0t: Read Response Received for ID %0d - Data=0x%h", $time, r_beat.id, r_beat.data);
      
      // Data verification (data includes ID)
      expected_data = 64'hA000_0000_0000_0000 | r_beat.id;
      if(r_beat.data == expected_data)
        $display("Data Verification Success: 0x%h == 0x%h", r_beat.data, expected_data);
      else
        $display("Data Verification Failed: 0x%h != 0x%h", r_beat.data, expected_data);
    end
    
    //--------------------------------------------------------------------------
    // Test 10: Long Burst Length Transaction
    //--------------------------------------------------------------------------
    $display("\n--- Test 10: Long Burst Length Transaction ---");
    
    // Maximum length burst write (limited to 16 for testing)
    aw_beat = new();
    aw_beat.id = 15;
    aw_beat.addr = 32'h8000;
    aw_beat.len = 15;  // 16 transfers (AXI4 supports up to 256 but limiting to 16 for testing)
    aw_beat.size = 3;  // 8 bytes
    aw_beat.burst = 1; // INCR mode
    aw_beat.lock = 0;
    aw_beat.cache = 0;
    aw_beat.prot = 0;
    aw_beat.qos = 0;
    aw_beat.region = 0;
    
    $display("Time %0t: Long Burst Write Request - Address=0x%h, Length=%0d", $time, aw_beat.addr, aw_beat.len + 1);
    master_bfm.AWmbx.put(aw_beat);
    
    // 16 data transfers
    for(int i=0; i<16; i++) begin
      w_beat = new();
      w_beat.data = 64'hB000_0000_0000_0000 | i; // Data includes index
      w_beat.strb = 8'hFF;
      w_beat.last = (i == 15); // Set last only for the last transfer
      
      $display("Time %0t: Long Burst Write Data Transfer #%0d - Data=0x%h", $time, i, w_beat.data);
      master_bfm.Wmbx.put(w_beat);
    end
    
    // Wait for write response
    master_bfm.Bmbx.get(b_beat);
    $display("Time %0t: Long Burst Write Response Received - ID=%0d, Response Code=%0d", $time, b_beat.id, b_beat.resp);
    
    // Delay
    #200;
    
    // Long burst read
    ar_beat = new();
    ar_beat.id = 15;
    ar_beat.addr = 32'h8000;
    ar_beat.len = 15;  // 16 transfers
    ar_beat.size = 3;  // 8 bytes
    ar_beat.burst = 1; // INCR mode
    ar_beat.lock = 0;
    ar_beat.cache = 0;
    ar_beat.prot = 0;
    ar_beat.qos = 0;
    ar_beat.region = 0;
    
    $display("Time %0t: Long Burst Read Request - Address=0x%h, Length=%0d", $time, ar_beat.addr, ar_beat.len + 1);
    master_bfm.ARmbx.put(ar_beat);
    
    // Receive 16 data responses
    for(int i=0; i<16; i++) begin
      master_bfm.Rmbx.get(r_beat);
      $display("Time %0t: Long Burst Read Response #%0d - Data=0x%h, Last=%0d", 
               $time, i, r_beat.data, r_beat.last);
      
      // Data verification
      expected_data = 64'hB000_0000_0000_0000 | i;
      if(r_beat.data == expected_data)
        $display("Data Verification Success: 0x%h == 0x%h", r_beat.data, expected_data);
      else
        $display("Data Verification Failed: 0x%h != 0x%h", r_beat.data, expected_data);
    end
    
    //--------------------------------------------------------------------------
    // Test Complete
    //--------------------------------------------------------------------------
    $display("\n=== All Tests Completed - Time: %0t ===", $time);
    
    // End simulation
    #1000;
    $display("Simulation Complete");
    $finish;
  end
  
  // Waveform generation
  initial begin
    $dumpfile("axi_tb.vcd");
    $dumpvars(0, axi_top_tb_simple);
  end
  
endmodule