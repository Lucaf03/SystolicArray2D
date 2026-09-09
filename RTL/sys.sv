module sys #(
  parameter int Width = 8,
  parameter int Rows = 4,
  parameter int Cols = 4
) (
  input  logic                        clk_i, 
  input  logic                        rst_i,
  input  logic                        load_weight_i,
  input  logic [Rows-1:0][Width-1:0]  data_i,
  input  logic [Cols-1:0][Width-1:0]  weight_i,
  output logic [Cols-1:0][31:0]       result_o
);

logic [Width-1:0] a_wire   [Rows][Cols+1];
logic [Width-1:0] w_wire   [Rows+1][Cols];
logic [32:0]      res_wire [Rows+1][Cols];

genvar r,c;
generate 
  for (r = 0; r < Rows; r++) begin 
    assign a_wire[r][0] = data_i[r];
  end 

  for (c = 0; c < Cols; c++) begin 
    assign res_wire[0][c] = '0;
    assign w_wire[0][c] = weight_i[c];
    assign result_o[c] = res_wire[Rows][c];
  end
endgenerate

endmodule
