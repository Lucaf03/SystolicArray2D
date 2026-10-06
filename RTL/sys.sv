module sys #(
  parameter int Width    = 8,
  parameter int AccWidth = 32,
  parameter int N_matrix = 4 // matrix dimension NxN
) (
  input  logic                                                clk_i, 
  input  logic                                                rst_i,
  input  logic                                                load_weight_i,
  input  logic signed [N_matrix-1:0][Width-1:0]               data_i,
  input  logic signed [(Width*N_matrix)-1:0]                  weight_i,
  input  logic signed [N_matrix-1:0][AccWidth-1:0]            prevout_i,
  output logic signed [N_matrix-1:0][AccWidth-1:0]            result_o,
  output logic signed [N_matrix-1:0][Width-1:0]               data_o
);

logic        [Width-1:0]    ff_skew         [N_matrix-1:0][N_matrix-1:0];
logic signed [Width-1:0]    sys_data        [N_matrix-1:0];
logic signed [Width-1:0]    pe_data         [N_matrix-1:0][N_matrix-1:0];
logic signed [AccWidth-1:0] pe_result       [N_matrix-1:0][N_matrix-1:0];
logic signed [Width-1:0]    weight_row      [N_matrix-1:0];
logic signed [Width-1:0]    weight_row_q    [N_matrix-1:0];
logic signed [Width-1:0]    pe_weight       [N_matrix-1:0][N_matrix-1:0];
logic                       load_weight_q;

// Generating the input skew of the systolic array
genvar i;
genvar j;
for(i = 0; i < N_matrix; i++) begin : gen_skew
  assign ff_skew[i][0] = data_i[i];
  assign sys_data[i]   = $signed(ff_skew[i][i]);
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

// Instantiation of the 2D Systolic Array
genvar r;
genvar c;

for (r = 0; r < N_matrix; r++) begin : gen_pe_row
  for (c = 0; c < N_matrix; c++) begin : gen_pe_col

    logic signed [Width-1:0] data_in_pe;
    assign data_in_pe = !c ? sys_data[r] : pe_data[r][c-1];

    logic signed [AccWidth-1:0] prevout_in_pe;
    assign prevout_in_pe = !r ? prevout_i[c] : pe_result[r-1][c];
    
    logic signed [Width-1:0] weight_int;
    assign weight_int = !r ? weight_row_q[c] : pe_weight[r-1][c];

    pe #(
      .Width   (Width),
      .AccWidth(AccWidth)
    ) u_pe (
      .clk_i         (clk_i),
      .rst_i         (rst_i),
      .data_i        (data_in_pe),
      .load_weight_i (load_weight_q),
      .weight_i      (weight_int),
      .prevout_i     (prevout_in_pe),
      .weight_o      (pe_weight[r][c]),
      .result_o      (pe_result[r][c]),
      .data_o        (pe_data[r][c])
    );
  end 
end

for (c = 0; c < N_matrix; c++) begin : gen_out_result
  assign result_o[c] = pe_result[N_matrix-1][c];
end : gen_out_result

for (r = 0; r < N_matrix; r++) begin : gen_out_data
  assign data_o[r] = pe_data[r][N_matrix-1];
end : gen_out_data

//Load Unit for Weights (Shift-register)

for(i = 0; i < N_matrix; i++) begin 
  assign weight_row[i] = weight_i[Width*(i+1)-1:(Width*i)];
end 

always_ff @(posedge clk_i or posedge rst_i) begin 
  if(rst_i) begin
    weight_row_q  <= '0;
    load_weight_q <= 0;
  end else begin 
    load_weight_q <= load_weight_i;
    
    if (load_weight_i) begin
      weight_row_q  <= weight_row;
    end
  end
end


endmodule
