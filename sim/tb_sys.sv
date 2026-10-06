`timescale 1ns/1ps

module tb_sys;

  // ---------------------------------------------------------------------------
  // Simulation Parameters
  // ---------------------------------------------------------------------------
  localparam int Width       = 8;
  localparam int AccWidth    = 32;
  localparam int N_matrix    = 4;
  localparam time CLK_PERIOD = 10ns;

  // ---------------------------------------------------------------------------
  // Matrix Type Definitions
  // ---------------------------------------------------------------------------
  typedef logic signed [Width-1:0]    mat_elem_t;
  typedef logic signed [AccWidth-1:0] acc_elem_t;

  typedef mat_elem_t mat_t     [0:N_matrix-1][0:N_matrix-1];
  typedef acc_elem_t res_mat_t [0:N_matrix-1][0:N_matrix-1];

  // ---------------------------------------------------------------------------
  // DUT Interface Signals
  // ---------------------------------------------------------------------------
  logic                                                clk_i;
  logic                                                rst_i;
  logic                                                load_weight_i;
  logic signed [N_matrix-1:0][Width-1:0]               data_i;
  logic signed [(Width*N_matrix)-1:0]                  weight_i;
  logic signed [N_matrix-1:0][AccWidth-1:0]            prevout_i;
  logic signed [N_matrix-1:0][AccWidth-1:0]            result_o;
  logic signed [N_matrix-1:0][Width-1:0]               data_o;

  // Global Tracking Variables
  int total_errors = 0;
  int test_count   = 0;

  // ---------------------------------------------------------------------------
  // DUT (Device Under Test) Instantiation
  // ---------------------------------------------------------------------------
  sys #(
    .Width   (Width),
    .AccWidth(AccWidth),
    .N_matrix(N_matrix)
  ) dut (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .load_weight_i(load_weight_i),
    .data_i       (data_i),
    .weight_i     (weight_i),
    .prevout_i    (prevout_i),
    .result_o     (result_o),
    .data_o       (data_o)
  );

  // ---------------------------------------------------------------------------
  // Clock Generation (100 MHz, Period 10 ns)
  // ---------------------------------------------------------------------------
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  // ---------------------------------------------------------------------------
  // Task: Shift-Register Weight Loading Sequence
  // ---------------------------------------------------------------------------
  task automatic load_weights_shift(input mat_t B);
    $display("[WEIGHT LOAD] Initiating sequential weight load protocol (%0d cycles)...", N_matrix);
    
    // In a shift-register architecture, we stream N_matrix rows of weights with load_weight_i = 1
    for (int step = N_matrix - 1; step >= 0; step--) begin
      load_weight_i <= 1'b1;
      for (int c = 0; c < N_matrix; c++) begin
        weight_i[Width*(c+1)-1 -: Width] <= B[step][c];
      end
      @(posedge clk_i);
    end

    // End of weight loading
    load_weight_i <= 1'b0;
    weight_i      <= '0;
    @(posedge clk_i);
    #1ps;
    $display("[WEIGHT LOAD] Weight loading protocol completed.");
  endtask

  // ---------------------------------------------------------------------------
  // Task: Inspect Internal Hardware Weight Registers
  // ---------------------------------------------------------------------------
  task automatic inspect_internal_weights(input mat_t B_expected, output int pe_errors);
    pe_errors = 0;
    $display("[HARDWARE DIAGNOSTIC] Inspecting DUT internal registers:");

    // 1. Check weight_int_q in sys.sv
    $display("  DUT weight_int_q: [ %0d, %0d, %0d, %0d ]", 
             dut.weight_row_q[0], dut.weight_row_q[1], dut.weight_row_q[2], dut.weight_row_q[3]);
    $display("  DUT load_weight_q: %0b", dut.load_weight_q);

    // 2. Check each PE's internal weight_q (statically unrolled for SystemVerilog generate blocks)
    `define CHECK_PE(R, C) \
      actual_pe_w = dut.gen_pe_row[R].gen_pe_col[C].u_pe.weight_q; \
      if ($isunknown(actual_pe_w)) begin \
        $display("  PE[%0d][%0d]: weight_q = 'h%h ('bx) | Expected: %0d  <-- [RTL ERROR: u_pe.weight_i is unconnected!]", R, C, actual_pe_w, B_expected[R][C]); \
        pe_errors++; \
      end else if (actual_pe_w !== B_expected[R][C]) begin \
        $display("  PE[%0d][%0d]: weight_q = %0d | Expected: %0d  <-- [MISMATCH]", R, C, actual_pe_w, B_expected[R][C]); \
        pe_errors++; \
      end else begin \
        $display("  PE[%0d][%0d]: weight_q = %0d | Expected: %0d  [OK]", R, C, actual_pe_w, B_expected[R][C]); \
      end

    begin
      logic signed [Width-1:0] actual_pe_w;
      `CHECK_PE(0,0) `CHECK_PE(0,1) `CHECK_PE(0,2) `CHECK_PE(0,3)
      `CHECK_PE(1,0) `CHECK_PE(1,1) `CHECK_PE(1,2) `CHECK_PE(1,3)
      `CHECK_PE(2,0) `CHECK_PE(2,1) `CHECK_PE(2,2) `CHECK_PE(2,3)
      `CHECK_PE(3,0) `CHECK_PE(3,1) `CHECK_PE(3,2) `CHECK_PE(3,3)
    end
    `undef CHECK_PE

    if (pe_errors > 0) begin
      $error("[HARDWARE ERROR] Found %0d PE weight error(s)! The RTL does not connect weight_i or shift registers to PEs.", pe_errors);
      total_errors += pe_errors;
    end else begin
      $display("[HARDWARE SUCCESS] All %0d PEs contain the correct weights!", N_matrix * N_matrix);
    end
  endtask

  // ---------------------------------------------------------------------------
  // Task: Execute GEMM Test with Automated Golden Model Verification
  // ---------------------------------------------------------------------------
  task automatic run_gemm_test(
    input string    test_name,
    input mat_t     A,
    input mat_t     B,
    input int       M_dim = N_matrix, // Number of active rows of A
    input int       K_dim = N_matrix, // Inner dimension (columns of A / rows of B)
    input int       P_dim = N_matrix  // Number of active columns of B
  );
    res_mat_t C_expected;
    res_mat_t C_actual;
    int test_errors = 0;
    int pe_weight_errors = 0;

    test_count++;
    $display("----------------------------------------------------------------");
    $display("TEST #%0d: %s", test_count, test_name);
    $display("Logical dimensions: (%0dx%0d) * (%0dx%0d) -> Result: (%0dx%0d)", 
             M_dim, K_dim, K_dim, P_dim, M_dim, P_dim);
    $display("----------------------------------------------------------------");

    // 1. Compute theoretical golden reference model C = A * B
    for (int r = 0; r < N_matrix; r++) begin
      for (int c = 0; c < N_matrix; c++) begin
        C_expected[r][c] = '0;
        C_actual[r][c]   = '0;
        for (int k = 0; k < N_matrix; k++) begin
          C_expected[r][c] += acc_elem_t'(A[r][k]) * acc_elem_t'(B[k][c]);
        end
      end
    end

    // 2. Cleanly reset the pipeline and inputs
    data_i        <= '0;
    prevout_i     <= '0;
    load_weight_i <= 1'b0;
    weight_i      <= '0;

    rst_i <= 1'b1;
    repeat (2) @(posedge clk_i);
    #1ps;
    rst_i <= 1'b0;
    @(posedge clk_i);

    // 3. Apply the new Weight Loading Protocol
    load_weights_shift(B);

    // 4. White-box hardware diagnostic on internal PE weights
    inspect_internal_weights(B, pe_weight_errors);

    // 5. Synchronous streaming of matrix A (row by row) and sampling of outputs C
    fork
      // Transmission process for input stream data_i
      begin : stream_A
        for (int i = 0; i < N_matrix; i++) begin
          for (int r = 0; r < N_matrix; r++) begin
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
          for (int c = 0; c < N_matrix; c++) begin
            // Result element C[i][c] is valid on result_o[c] at cycle = 4 + i + c
            if (cycle >= (4 + c) && cycle < (4 + c + N_matrix)) begin
              int i_idx = cycle - 4 - c;
              C_actual[i_idx][c] = result_o[c];
            end
          end
          @(posedge clk_i);
        end
      end : sample_C
    join

    // 6. Verification and comparison between actual and golden expected results
    for (int r = 0; r < M_dim; r++) begin
      for (int c = 0; c < P_dim; c++) begin
        if (C_actual[r][c] !== C_expected[r][c]) begin
          $error("[MISMATCH C[%0d][%0d]] Actual: %0d ('h%h) | Expected: %0d", 
                 r, c, C_actual[r][c], C_actual[r][c], C_expected[r][c]);
          test_errors++;
          total_errors++;
        end
      end
    end

    // 7. Print test summary
    if (test_errors == 0 && pe_weight_errors == 0) begin
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
      $display("[STATUS: FAILED] Found %0d calculation error(s) and %0d PE weight error(s)!", 
               test_errors, pe_weight_errors);
    end
    $display("");

  endtask

  // ---------------------------------------------------------------------------
  // Main Test Sequence
  // ---------------------------------------------------------------------------
  initial begin
    mat_t A_test, B_test;
    clk_i         = 0;
    rst_i         = 1;
    load_weight_i = 0;
    data_i        = '0;
    weight_i      = '0;
    prevout_i     = '0;

    $display("================================================================");
    $display("    START 2D SYSTOLIC ARRAY TESTBENCH (sys.sv)                 ");
    $display("    Testing new Shift-Register Weight Loading Protocol          ");
    $display("================================================================");
    $display("");

    // -------------------------------------------------------------------------
    // TEST 1: 4x4 Identity Matrix Multiplication (A * I = A)
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) begin
      for (int c = 0; c < 4; c++) begin
        A_test[r][c] = 8'sd1 + 8'(r * 4 + c);
        B_test[r][c] = (r == c) ? 8'sd1 : 8'sd0;
      end
    end
    run_gemm_test("Identity Matrix Multiplication (A * I = A)", A_test, B_test);

    // -------------------------------------------------------------------------
    // TEST 2: 4x4 Matrix with Known Numerical Values
    // -------------------------------------------------------------------------
    A_test = '{ '{8'sd1, 8'sd2, 8'sd3, 8'sd4},
                '{8'sd5, 8'sd6, 8'sd7, 8'sd8},
                '{8'sd1, 8'sd1, 8'sd1, 8'sd1},
                '{8'sd2, 8'sd0, 8'sd1, 8'sd3} };

    B_test = '{ '{8'sd1, 8'sd0, 8'sd2, 8'sd1},
                '{8'sd0, 8'sd1, 8'sd1, 8'sd0},
                '{8'sd2, 8'sd1, 8'sd0, 8'sd1},
                '{8'sd1, 8'sd0, 8'sd1, 8'sd2} };
    run_gemm_test("4x4 Matrix with Known Numerical Values", A_test, B_test);

    // -------------------------------------------------------------------------
    // TEST 3: Rectangular Multiplication (2x3) x (3x4) with Zero-Padding
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) begin A_test[r][c] = 0; B_test[r][c] = 0; end
    // A: 2 rows, 3 columns
    A_test[0][0] = 8'sd2; A_test[0][1] = 8'sd3; A_test[0][2] = 8'sd4;
    A_test[1][0] = 8'sd1; A_test[1][1] = 8'sd0; A_test[1][2] = 8'sd5;

    // B: 3 rows, 4 columns
    B_test[0][0] = 8'sd1; B_test[0][1] = 8'sd2; B_test[0][2] = 8'sd3; B_test[0][3] = 8'sd4;
    B_test[1][0] = 8'sd5; B_test[1][1] = 8'sd6; B_test[1][2] = 8'sd7; B_test[1][3] = 8'sd8;
    B_test[2][0] = 8'sd9; B_test[2][1] = 8'sd1; B_test[2][2] = 8'sd0; B_test[2][3] = 8'sd2;
    run_gemm_test("Rectangular Multiplication (2x3) x (3x4) with Zero-Padding", A_test, B_test, 2, 3, 4);

    // -------------------------------------------------------------------------
    // TEST 4: Reduced Square Multiplication (2x2) x (2x2) with Zero-Padding
    // -------------------------------------------------------------------------
    for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) begin A_test[r][c] = 0; B_test[r][c] = 0; end
    A_test[0][0] = 8'sd7; A_test[0][1] = 8'sd3;
    A_test[1][0] = 8'sd2; A_test[1][1] = 8'sd5;

    B_test[0][0] = 8'sd4; B_test[0][1] = 8'sd1;
    B_test[1][0] = 8'sd6; B_test[1][1] = 8'sd8;
    run_gemm_test("Reduced Square Multiplication (2x2) x (2x2) with Zero-Padding", A_test, B_test, 2, 2, 2);

    // -------------------------------------------------------------------------
    // TEST 5: Signed Numbers with Negatives (-128 to 127)
    // -------------------------------------------------------------------------
    A_test = '{ '{-8'sd5,  8'sd10, -8'sd2,  8'sd4},
                '{ 8'sd3, -8'sd7,   8'sd1, -8'sd8},
                '{-8'sd1,  8'sd2,  -8'sd3,  8'sd4},
                '{ 8'sd6, -8'sd1,   8'sd0, -8'sd2} };

    B_test = '{ '{ 8'sd2, -8'sd3,  8'sd1,  8'sd0},
                '{-8'sd4,  8'sd5, -8'sd2,  8'sd1},
                '{ 8'sd1, -8'sd1,  8'sd3, -8'sd2},
                '{-8'sd2,  8'sd0, -8'sd1,  8'sd4} };
    run_gemm_test("Signed Matrices with Negative Values", A_test, B_test);

    // -------------------------------------------------------------------------
    // Final Summary
    // -------------------------------------------------------------------------
    $display("================================================================");
    if (total_errors == 0) begin
      $display("   ALL TESTS COMPLETED SUCCESSFULLY! (0 ERRORS)                ");
    end else begin
      $display("   SIMULATION DETECTED %0d TOTAL ERROR(S)!                      ", total_errors);
    end
    $display("================================================================");
    $finish;
  end

endmodule
