`timescale 1ns/1ps

module tb_pe;

  // ---------------------------------------------------------------------------
  // Testbench Parameters
  // ---------------------------------------------------------------------------
  localparam int  Width      = 8;
  localparam int  AccWidth   = 32;
  localparam time CLK_PERIOD = 10ns;

  // ---------------------------------------------------------------------------
  // DUT Interface Signals
  // ---------------------------------------------------------------------------
  logic                        clk_i;
  logic                        rst_i;
  logic                        load_weight_i;
  logic signed [Width-1:0]     data_i;
  logic signed [Width-1:0]     weight_i;
  logic signed [Width-1:0]     weight_o;
  logic signed [AccWidth-1:0]  prevout_i;
  logic signed [AccWidth-1:0]  result_o;
  logic signed [Width-1:0]     data_o;

  int total_errors = 0;
  int test_count   = 0;

  // ---------------------------------------------------------------------------
  // DUT (Device Under Test) Instantiation
  // ---------------------------------------------------------------------------
  pe #(
    .Width   (Width),
    .AccWidth(AccWidth)
  ) dut (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .load_weight_i(load_weight_i),
    .data_i       (data_i),
    .weight_i     (weight_i),
    .weight_o     (weight_o),
    .prevout_i    (prevout_i),
    .result_o     (result_o),
    .data_o       (data_o)
  );

  // ---------------------------------------------------------------------------
  // Clock Generation (100 MHz, Period 10 ns)
  // ---------------------------------------------------------------------------
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  // ---------------------------------------------------------------------------
  // Task: Load Weight into PE
  // ---------------------------------------------------------------------------
  task automatic load_weight(input logic signed [Width-1:0] w);
    $display("[LOAD WEIGHT] Loading weight = %0d into PE register...", w);
    load_weight_i <= 1'b1;
    weight_i      <= w;
    @(posedge clk_i);
    #1ps;
    load_weight_i <= 1'b0;
    weight_i      <= '0; // Clear weight_i to ensure weight_q is retained

    // Verify weight_o has latched the new weight
    if (weight_o !== w) begin
      $error("[WEIGHT LOAD ERROR] weight_o mismatch! Got: %0d, Expected: %0d", weight_o, w);
      total_errors++;
    end else begin
      $display("[LOAD WEIGHT SUCCESS] weight_o correctly latched: %0d", weight_o);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Task: Drive Data Stimuli and Verify MAC Output
  // ---------------------------------------------------------------------------
  task automatic drive_mac_and_check(
    input logic signed [Width-1:0]    d,
    input logic signed [AccWidth-1:0] p,
    input logic signed [Width-1:0]    expected_w
  );
    logic signed [AccWidth-1:0] expected_result;

    // Drive data input and partial sum input
    data_i    <= d;
    prevout_i <= p;
    @(posedge clk_i);
    #1ps; // Delta delay for stable output sampling

    // Golden MAC result: y = prev_y + x * w
    expected_result = (AccWidth'(d) * AccWidth'(expected_w)) + p;

    $display("[TIME %0t] IN: data=%0d, active_weight=%0d, prevout=%0d | OUT: result=%0d (EXP: %0d), data_o=%0d",
             $time, d, expected_w, p, result_o, expected_result, data_o);

    // Verify MAC accumulation result
    if (result_o !== expected_result) begin
      $error("[MAC ERROR] Incorrect result! Got: %0d, Expected: %0d", result_o, expected_result);
      total_errors++;
    end

    // Verify horizontal data passthrough
    if (data_o !== d) begin
      $error("[PASSTHROUGH ERROR] Incorrect data_o! Got: %0d, Expected: %0d", data_o, d);
      total_errors++;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Test Sequence
  // ---------------------------------------------------------------------------
  initial begin
    // Signal initialization
    clk_i         = 0;
    rst_i         = 1;
    load_weight_i = 0;
    data_i        = '0;
    weight_i      = '0;
    prevout_i     = '0;

    // Reset release
    #(CLK_PERIOD * 2);
    rst_i = 0;
    @(posedge clk_i);
    #1ps;

    $display("================================================================");
    $display("       START PROCESSING ELEMENT (pe.sv) TESTBENCH              ");
    $display("================================================================");

    // -------------------------------------------------------------------------
    // TEST 1: Reset State Verification
    // -------------------------------------------------------------------------
    $display("\n--- TEST 1: Verification of Reset State ---");
    if (weight_o !== '0) begin
      $error("[RESET ERROR] weight_o is not 0 after reset! Got: %0d", weight_o);
      total_errors++;
    end else begin
      $display("[PASS] weight_o is cleanly reset to 0.");
    end

    // -------------------------------------------------------------------------
    // TEST 2: Weight Loading and Weight-Stationary Retention
    // -------------------------------------------------------------------------
    $display("\n--- TEST 2: Weight Loading & Weight-Stationary Verification ---");
    load_weight(8'sd5);

    // Verify weight retention when load_weight_i = 0, even if weight_i changes
    weight_i <= 8'sd99;
    @(posedge clk_i);
    #1ps;
    if (weight_o !== 8'sd5) begin
      $error("[RETENTION ERROR] PE failed to retain weight! Got: %0d, Expected: 5", weight_o);
      total_errors++;
    end else begin
      $display("[PASS] PE retained weight=5 while weight_i=99 and load_weight_i=0.");
    end
    weight_i <= '0;

    // -------------------------------------------------------------------------
    // TEST 3: MAC Computation with Loaded Weight (Positive & Zero)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 3: MAC Computations with Weight = 5 ---");
    drive_mac_and_check(8'sd4,  32'sd10, 8'sd5); // (4 * 5) + 10 = 30
    drive_mac_and_check(8'sd12, 32'sd0,  8'sd5); // (12 * 5) + 0 = 60
    drive_mac_and_check(8'sd0,  32'sd50, 8'sd5); // (0 * 5) + 50 = 50

    // -------------------------------------------------------------------------
    // TEST 4: Weight Update to Signed Negative Value
    // -------------------------------------------------------------------------
    $display("\n--- TEST 4: Weight Update to Negative Value (-7) ---");
    load_weight(-8'sd7);

    drive_mac_and_check(8'sd6,   32'sd50,  -8'sd7); // (6 * -7) + 50 = 8
    drive_mac_and_check(-8'sd3,  32'sd10,  -8'sd7); // (-3 * -7) + 10 = 31
    drive_mac_and_check(-8'sd10, -32'sd20, -8'sd7); // (-10 * -7) - 20 = 50

    // -------------------------------------------------------------------------
    // TEST 5: Boundary Values (INT8 Limits: -128, +127)
    // -------------------------------------------------------------------------
    $display("\n--- TEST 5: INT8 Boundary Testing (-128, 127) ---");
    load_weight(8'sd127);
    drive_mac_and_check(8'sd2, 32'sd0, 8'sd127); // (2 * 127) = 254

    load_weight(-8'sd128);
    drive_mac_and_check(8'sd2, 32'sd300, -8'sd128); // (2 * -128) + 300 = 44

    // -------------------------------------------------------------------------
    // TEST 6: Randomized Stimuli
    // -------------------------------------------------------------------------
    $display("\n--- TEST 6: Randomized Stimuli ---");
    repeat (10) begin
      logic signed [Width-1:0]    rand_w;
      logic signed [Width-1:0]    rand_d;
      logic signed [AccWidth-1:0] rand_p;

      rand_w = $signed($urandom_range(0, 255));
      rand_d = $signed($urandom_range(0, 255));
      rand_p = $signed($urandom_range(0, 5000));

      load_weight(rand_w);
      drive_mac_and_check(rand_d, rand_p, rand_w);
    end

    // -------------------------------------------------------------------------
    // Final Summary
    // -------------------------------------------------------------------------
    $display("\n================================================================");
    if (total_errors == 0) begin
      $display("   PE TESTBENCH COMPLETED SUCCESSFULLY! (0 ERRORS)            ");
    end else begin
      $display("   PE TESTBENCH FAILED WITH %0d ERROR(S)!                     ", total_errors);
    end
    $display("================================================================");
    $finish;
  end

endmodule