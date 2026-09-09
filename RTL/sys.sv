module sys #(
  parameter int Width = 8,
  parameter int Matrix_N = 4 //matrix dimension NxN
) (
  input  logic              clk_i, 
  input  logic              rst_i,
  input  logic [Width-1:0]  data_i,
  input  logic [Width-1:0]  weight_i,
  input  logic [Width-1:0]  prevout_i,
  output logic [31:0]       result_o,
  output logic [Width-1:0]  data_o
);

