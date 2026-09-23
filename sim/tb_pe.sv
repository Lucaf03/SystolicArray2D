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
  logic                clk_i;
  logic                rst_i;
  logic [Width-1:0]    data_i;
  logic [Width-1:0]    weight_i;
  logic [AccWidth-1:0] prevout_i;
  logic [AccWidth-1:0] result_o;
  logic [Width-1:0]    data_o;

  int total_errors = 0;

  // ---------------------------------------------------------------------------
  // DUT (Device Under Test) Instantiation
  // ---------------------------------------------------------------------------
  pe #(
    .Width   (Width),
    .AccWidth(AccWidth)
  ) dut (
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .data_i   (data_i),
    .weight_i (weight_i),
    .prevout_i(prevout_i),
    .result_o (result_o),
    .data_o   (data_o)
  );

  // ---------------------------------------------------------------------------
  // Clock Generation (50 MHz, Period 10 ns)
  // ---------------------------------------------------------------------------
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  // ---------------------------------------------------------------------------
  // Task: Drive Stimuli and Check Outputs
  // ---------------------------------------------------------------------------
  task automatic drive_and_check(
    input logic [Width-1:0]    d,
    input logic [Width-1:0]    w,
    input logic [AccWidth-1:0] p
  );
    logic [AccWidth-1:0] expected_result;

    // In a weight-stationary architecture, load weight into the PE register first
    weight_i <= w;
    @(posedge clk_i);

    // Drive data input and partial sum input
    data_i    <= d;
    prevout_i <= p;
    @(posedge clk_i);
    #1ps; // Delta delay for stable output sampling

    // Golden MAC result: y = prev_y + x * w
    expected_result = (AccWidth'(d) * AccWidth'(w)) + p;

    $display("[TIME %0t] IN: data=%0d, weight=%0d, prevout=%0d | OUT: result=%0d (EXP: %0d), data_o=%0d",
             $time, d, w, p, result_o, expected_result, data_o);

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
    clk_i     = 0;
    rst_i     = 1;
    data_i    = '0;
    weight_i  = '0;
    prevout_i = '0;

    // Reset release
    #(CLK_PERIOD * 2);
    rst_i = 0;
    @(posedge clk_i);

    $display("========================================");
    $display("   START PROCESSING ELEMENT TESTBENCH   ");
    $display("========================================");

    // Test 1: Specific known values
    drive_and_check(8'd5,   8'd4,   32'd10); // MAC: (5 * 4) + 10 = 30
    drive_and_check(8'd12,  8'd3,   32'd0);  // MAC: (12 * 3) + 0 = 36
    drive_and_check(8'd255, 8'd2,   32'd5);  // MAC: (255 * 2) + 5 = 515

    // Test 2: Random stimuli
    repeat (10) begin
      logic [Width-1:0]    rand_d, rand_w;
      logic [AccWidth-1:0] rand_p;
      rand_d = $urandom_range(0, (1<<Width)-1);
      rand_w = $urandom_range(0, (1<<Width)-1);
      rand_p = $urandom_range(0, 1000);

      drive_and_check(rand_d, rand_w, rand_p);
    end

    $display("========================================");
    if (total_errors == 0) begin
      $display("   TESTS COMPLETED SUCCESSFULLY (0 ERRORS) ");
    end else begin
      $display("   TESTBENCH FAILED WITH %0d ERRORS       ", total_errors);
    end
    $display("========================================");
    $finish;
  end

endmodule