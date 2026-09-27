`timescale 1ns/1ps

module tb_sys;

  // ---------------------------------------------------------------------------
  // Simulation Parameters
  // ---------------------------------------------------------------------------
  localparam int Width       = 8;
  localparam int AccWidth    = 32;
  localparam int Matrix_N    = 4;
  localparam time CLK_PERIOD = 10ns;

  // ---------------------------------------------------------------------------
  // Matrix Type Definitions
  // ---------------------------------------------------------------------------
  typedef logic [Width-1:0]    mat_elem_t;
  typedef logic [AccWidth-1:0] acc_elem_t;

  typedef mat_elem_t mat_t     [0:Matrix_N-1][0:Matrix_N-1];
  typedef acc_elem_t res_mat_t [0:Matrix_N-1][0:Matrix_N-1];

  // ---------------------------------------------------------------------------
  // DUT Interface Signals
  // ---------------------------------------------------------------------------
  logic                                                clk_i;
  logic                                                rst_i;
  logic [Matrix_N-1:0][Width-1:0]                      data_i;
  logic [Matrix_N-1:0][Matrix_N-1:0][Width-1:0]        weight_i;
  logic [Matrix_N-1:0][AccWidth-1:0]                   prevout_i;
  logic [Matrix_N-1:0][AccWidth-1:0]                   result_o;
  logic [Matrix_N-1:0][Width-1:0]                      data_o;

  // Global Tracking Variables
  int total_errors = 0;
  int test_count   = 0;

  // ---------------------------------------------------------------------------
  // DUT (Device Under Test) Instantiation
  // ---------------------------------------------------------------------------
  sys #(
    .Width   (Width),
    .AccWidth(AccWidth),
    .Matrix_N(Matrix_N)
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
  // Clock Generation (100 MHz, Period 10 ns)
  // ---------------------------------------------------------------------------
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  // ---------------------------------------------------------------------------
  // Task: Execute GEMM Test with Automated Golden Model Verification
  // ---------------------------------------------------------------------------
  task automatic run_gemm_test(
    input string    test_name,
    input mat_t     A,
    input mat_t     B,
    input int       M_dim = Matrix_N, // Number of active rows of A
    input int       K_dim = Matrix_N, // Inner dimension (columns of A / rows of B)
    input int       P_dim = Matrix_N  // Number of active columns of B
  );
    res_mat_t C_expected;
    res_mat_t C_actual;
    int test_errors = 0;

    test_count++;
    $display("----------------------------------------------------------------");
    $display("TEST #%0d: %s", test_count, test_name);
    $display("Logical dimensions: (%0dx%0d) * (%0dx%0d) -> Result: (%0dx%0d)", 
             M_dim, K_dim, K_dim, P_dim, M_dim, P_dim);
    $display("----------------------------------------------------------------");

    // 1. Compute theoretical golden reference model C = A * B
    for (int r = 0; r < Matrix_N; r++) begin
      for (int c = 0; c < Matrix_N; c++) begin
        C_expected[r][c] = '0;
        C_actual[r][c]   = '0;
        for (int k = 0; k < Matrix_N; k++) begin
          C_expected[r][c] += acc_elem_t'(A[r][k]) * acc_elem_t'(B[k][c]);
        end
      end
    end

    // 2. Apply weights B and cleanly reset the pipeline
    data_i    <= '0;
    prevout_i <= '0;
    for (int r = 0; r < Matrix_N; r++) begin
      for (int c = 0; c < Matrix_N; c++) begin
        weight_i[r][c] <= B[r][c];
      end
    end

    rst_i <= 1'b1;
    repeat (2) @(posedge clk_i);
    #1ps;
    rst_i <= 1'b0;
    @(posedge clk_i); // 1 clock cycle to allow all PEs to latch weight_q <= weight_i

    // 3. Synchronous streaming of matrix A (row by row) and sampling of outputs C
    fork
      // Transmission process for input stream data_i
      begin : stream_A
        for (int i = 0; i < Matrix_N; i++) begin
          for (int r = 0; r < Matrix_N; r++) begin
            data_i[r] <= A[i][r];
          end
          @(posedge clk_i);
        end
        data_i <= '0;
      end : stream_A

      // Sampling process for output results result_o
      begin : sample_C
        for (int cycle = 0; cycle <= 12; cycle++) begin
          #1ps;
          for (int c = 0; c < Matrix_N; c++) begin
            // Result element C[i][c] is valid on result_o[c] at cycle = 4 + i + c
            if (cycle >= (4 + c) && cycle < (4 + c + Matrix_N)) begin
              int i_idx = cycle - 4 - c;
              C_actual[i_idx][c] = result_o[c];
            end
          end
          @(posedge clk_i);
        end
      end : sample_C
    join

    // 4. Verification and comparison between actual and golden expected results
    for (int r = 0; r < M_dim; r++) begin
      for (int c = 0; c < P_dim; c++) begin
        if (C_actual[r][c] !== C_expected[r][c]) begin
          $error("[MISMATCH C[%0d][%0d]] Actual value: %0d | Expected value: %0d", 
                 r, c, C_actual[r][c], C_expected[r][c]);
          test_errors++;
          total_errors++;
        end
      end
    end

    // 5. Print test summary
    if (test_errors == 0) begin
      $display("[STATUS: PASSED] Output Result Matrix C (%0dx%0d):", M_dim, P_dim);
      for (int r = 0; r < M_dim; r++) begin
        string row_str = "  [";
        for (int c = 0; c < P_dim; c++) begin
          row_str = $sformatf("%s %6d", row_str, C_actual[r][c]);
        end
        row_str = {row_str, " ]"};
        $display("%s", row_str);
      end
    end else begin
      $display("[STATUS: FAILED] Found %0d error(s) in this test!", test_errors);
    end
    $display("");

  endtask

  // ---------------------------------------------------------------------------
  // Main Test Sequence
  // ---------------------------------------------------------------------------
  initial begin
    mat_t A_test, B_test;
    clk_i = 0;
    rst_i = 1;

    $display("================================================================");
    $display("    START 2D SYSTOLIC ARRAY TESTBENCH (sys.sv)                 ");
    $display("================================================================");
    $display("");

    // -------------------------------------------------------------------------
    // TEST 1: 4x4 Identity Matrix Multiplication (A * I = A)
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        A_test[r][c] = 8'(r * 4 + c + 1);
        B_test[r][c] = (r == c) ? 8'd1 : 8'd0;
      end
    end
    run_gemm_test("Identity Matrix Multiplication (A * I = A)", A_test, B_test);

    // -------------------------------------------------------------------------
    // TEST 2: 4x4 Matrix with Known Numerical Values
    // -------------------------------------------------------------------------
    A_test = '{ '{8'd1, 8'd2, 8'd3, 8'd4},
                '{8'd5, 8'd6, 8'd7, 8'd8},
                '{8'd1, 8'd1, 8'd1, 8'd1},
                '{8'd2, 8'd0, 8'd1, 8'd3} };

    B_test = '{ '{8'd1, 8'd0, 8'd2, 8'd1},
                '{8'd0, 8'd1, 8'd1, 8'd0},
                '{8'd2, 8'd1, 8'd0, 8'd1},
                '{8'd1, 8'd0, 8'd1, 8'd2} };
    run_gemm_test("4x4 Matrix with Known Numerical Values", A_test, B_test);

    // -------------------------------------------------------------------------
    // TEST 3: Rectangular Multiplication (2x3) x (3x4) with Zero-Padding
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) begin A_test[r][c] = 0; B_test[r][c] = 0; end
    // A: 2 rows, 3 columns
    A_test[0][0] = 8'd2; A_test[0][1] = 8'd3; A_test[0][2] = 8'd4;
    A_test[1][0] = 8'd1; A_test[1][1] = 8'd0; A_test[1][2] = 8'd5;

    // B: 3 rows, 4 columns
    B_test[0][0] = 8'd1; B_test[0][1] = 8'd2; B_test[0][2] = 8'd3; B_test[0][3] = 8'd4;
    B_test[1][0] = 8'd5; B_test[1][1] = 8'd6; B_test[1][2] = 8'd7; B_test[1][3] = 8'd8;
    B_test[2][0] = 8'd9; B_test[2][1] = 8'd1; B_test[2][2] = 8'd0; B_test[2][3] = 8'd2;
    run_gemm_test("Rectangular Multiplication (2x3) x (3x4) with Zero-Padding", A_test, B_test, 2, 3, 4);

    // -------------------------------------------------------------------------
    // TEST 4: Reduced Square Multiplication (2x2) x (2x2) with Zero-Padding
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) begin A_test[r][c] = 0; B_test[r][c] = 0; end
    A_test[0][0] = 8'd7; A_test[0][1] = 8'd3;
    A_test[1][0] = 8'd2; A_test[1][1] = 8'd5;

    B_test[0][0] = 8'd4; B_test[0][1] = 8'd1;
    B_test[1][0] = 8'd6; B_test[1][1] = 8'd8;
    run_gemm_test("Reduced Square Multiplication (2x2) x (2x2) with Zero-Padding", A_test, B_test, 2, 2, 2);

    // -------------------------------------------------------------------------
    // TEST 5: Rectangular Multiplication (3x2) x (2x4) with Zero-Padding
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) begin A_test[r][c] = 0; B_test[r][c] = 0; end
    A_test[0][0] = 8'd3; A_test[0][1] = 8'd1;
    A_test[1][0] = 8'd4; A_test[1][1] = 8'd2;
    A_test[2][0] = 8'd5; A_test[2][1] = 8'd3;

    B_test[0][0] = 8'd2; B_test[0][1] = 8'd4; B_test[0][2] = 8'd1; B_test[0][3] = 8'd3;
    B_test[1][0] = 8'd1; B_test[1][1] = 8'd0; B_test[1][2] = 8'd5; B_test[1][3] = 8'd2;
    run_gemm_test("Rectangular Multiplication (3x2) x (2x4) with Zero-Padding", A_test, B_test, 3, 2, 4);

    // -------------------------------------------------------------------------
    // TEST 6-9: Random 4x4 Multiplications (Random Stimuli)
    // -------------------------------------------------------------------------
    repeat (4) begin
      for (int r = 0; r < 4; r++) begin
        for (int c = 0; c < 4; c++) begin
          A_test[r][c] = $urandom_range(0, 100);
          B_test[r][c] = $urandom_range(0, 100);
        end
      end
      run_gemm_test("Random 4x4 Matrices", A_test, B_test);
    end

    // -------------------------------------------------------------------------
    // TEST 10: Random (3x3) x (3x3) Multiplication with Zero-Padding
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) begin A_test[r][c] = 0; B_test[r][c] = 0; end
    for (int r = 0; r < 3; r++) begin
      for (int c = 0; c < 3; c++) begin
        A_test[r][c] = $urandom_range(1, 40);
        B_test[r][c] = $urandom_range(1, 40);
      end
    end
    run_gemm_test("Random (3x3) x (3x3) Multiplication with Zero-Padding", A_test, B_test, 3, 3, 3);

    // -------------------------------------------------------------------------
    // Final Summary
    // -------------------------------------------------------------------------
    $display("================================================================");
    if (total_errors == 0) begin
      $display("   ALL TESTS COMPLETED SUCCESSFULLY! (0 ERRORS)                ");
    end else begin
      $display("   WARNING: SIMULATION DETECTED %0d ERROR(S)!                   ", total_errors);
    end
    $display("================================================================");
    $finish;
  end

endmodule
