`timescale 1ns/1ps

module tb_pe;

  // Parametri di testbench
  localparam int Width = 8;
  localparam time CLK_PERIOD = 10ns;

  // Segnali di interfaccia DUT
  logic             clk_i;
  logic             rst_i;
  logic [Width-1:0] data_i;
  logic [Width-1:0] weight_i;
  logic [Width-1:0] prevout_i;
  logic [31:0]      result_o;
  logic [Width-1:0] data_o;

  // Istanziazione del DUT (Device Under Test)
  pe #(
    .Width(Width)
  ) dut (
    .clk_i    (clk_i),
    .rst_i    (rst_i),
    .data_i   (data_i),
    .weight_i (weight_i),
    .prevout_i(prevout_i),
    .result_o (result_o),
    .data_o   (data_o)
  );

  // Generazione del Clock (50 MHz)
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  // Sequenza di test
  initial begin
    // Inizializzazione segnali
    clk_i     = 0;
    rst_i     = 1;
    data_i    = '0;
    weight_i  = '0;
    prevout_i = '0;

    // Rilascio Reset
    #(CLK_PERIOD * 2);
    rst_i = 0;
    @(posedge clk_i);

    $display("========================================");
    $display("   INIZIO TESTBENCH PROCESSING ELEMENT  ");
    $display("========================================");

    // Test 1: Valori noti specifici
    drive_and_check(8'd5,  8'd4,  8'd10); // MAC: (5 * 4) + 10 = 30
    drive_and_check(8'd12, 8'd3,  8'd0);  // MAC: (12 * 3) + 0 = 36
    drive_and_check(8'd255,8'd2,  8'd5);  // MAC: (255 * 2) + 5 = 515

    // Test 2: Stimoli Casuali
    repeat (10) begin
      logic [Width-1:0] rand_d, rand_w, rand_p;
      rand_d = $urandom_range(0, (1<<Width)-1);
      rand_w = $urandom_range(0, (1<<Width)-1);
      rand_p = $urandom_range(0, (1<<Width)-1);

      drive_and_check(rand_d, rand_w, rand_p);
    end

    $display("========================================");
    $display("   TEST COMPLETATI SENZA ERRORE         ");
    $display("========================================");
    $finish;
  end

// Task automatizzata per invio stimolo e controllo risultati
  task automatic drive_and_check(
    input logic [Width-1:0] d,
    input logic [Width-1:0] w,
    input logic [Width-1:0] p
  );
    // Dichiarazione delle variabili locali ALL'INIZIO del task
    logic [31:0] expected_result;

    // Assegnamento ingressi e gestione timing
    data_i    <= d;
    weight_i  <= w;
    prevout_i <= p;

    @(posedge clk_i);
    #1ps; // Delta delay per il campionamento sicuro delle uscite

    // Calcolo del valore teorico atteso
    expected_result = (d * w) + p;

    // Display dello stato
    $display("[TIME %0t] IN: data=%0d, weight=%0d, prevout=%0d | OUT: result=%0d (EXP: %0d), data_o=%0d",
             $time, d, w, p, result_o, expected_result, data_o);

    // Assertions di controllo
    if (result_o !== expected_result) begin
      $error("[ERRORE MAC] Risultato non corretto! Ottenuto: %0d, Atteso: %0d", result_o, expected_result);
    end
    if (data_o !== d) begin
      $error("[ERRORE PASSTHROUGH] data_o errato! Ottenuto: %0d, Atteso: %0d", data_o, d);
    end
  endtask

endmodule