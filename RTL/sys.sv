module sys #(
  parameter int Width = 8,
  parameter int AccWidth = 32,
  parameter int Matrix_N = 4 //matrix dimension NxN
) (
  input  logic                                         clk_i, 
  input  logic                                         rst_i,
  input  logic [Matrix_N-1:0][Width-1:0]               data_i,
  input  logic [Matrix_N-1:0][Matrix_N-1:0][Width-1:0] weight_i,
  input  logic [Matrix_N-1:0][AccWidth-1:0]            prevout_i,
  output logic [Matrix_N-1:0][AccWidth-1:0]            result_o,
  output logic [Matrix_N-1:0][Width-1:0]               data_o
);

logic [Width-1:0]    ff_skew   [Matrix_N-1:0][Matrix_N-1:0];
logic [Width-1:0]    sys_data  [Matrix_N-1:0];
logic [Width-1:0]    pe_data   [Matrix_N-1:0][Matrix_N-1:0];
logic [AccWidth-1:0] pe_result [Matrix_N-1:0][Matrix_N-1:0];

//Generating the input skew of the systolic array
genvar i;
genvar j;
for(i = 0; i < Matrix_N; i++) begin : gen_skew
  assign ff_skew[i][0] = data_i[i];
  assign sys_data[i] = ff_skew[i][i];
  for(j = 1; j <= i; j++) begin : gen_ff
    always_ff @(posedge clk_i or posedge rst_i) begin
      if(rst_i) begin
        ff_skew[i][j] <= '0;
      end else begin
        ff_skew[i][j] <= ff_skew[i][j-1];
      end
    end
  end 
end

//Instantation of the 2D Systolic Array,
genvar r;
genvar c;

for (r = 0; r < Matrix_N; r++) begin : gen_pe_row
  for (c = 0; c < Matrix_N; c++) begin : gen_pe_col

    logic [Width-1:0] data_in_pe;
      
    if (c == 0) begin : gen_data_in_edge
      assign data_in_pe = sys_data[r];
    end else begin : gen_data_in_internal
      assign data_in_pe = pe_data[r][c-1];
    end

    logic [AccWidth-1:0] prevout_in_pe;
    
    if (r == 0) begin : gen_prevout_in_edge
      assign prevout_in_pe = prevout_i[c];
    end else begin : gen_prevout_in_internal
      assign prevout_in_pe = pe_result[r-1][c];
    end

    pe #(
      .Width   (Width),
      .AccWidth(AccWidth)
    ) u_pe (
      .clk_i    (clk_i),
      .rst_i    (rst_i),
      .data_i   (data_in_pe),
      .weight_i (weight_i[r][c]),
      .prevout_i(prevout_in_pe),
      .result_o ( pe_result[r][c]),
      .data_o   (pe_data[r][c])
    );
  end 
end

for (c = 0; c < Matrix_N; c++) begin : gen_out_result
  assign result_o[c] = pe_result[Matrix_N-1][c];
end : gen_out_result

for (r = 0; r < Matrix_N; r++) begin : gen_out_data
  assign data_o[r] = pe_data[r][Matrix_N-1];
end : gen_out_data

endmodule  