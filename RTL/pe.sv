module pe #(
  parameter int Width = 8,
  parameter int AccWidth = 32
) (
  input  logic                        clk_i, 
  input  logic                        rst_i,
  input  logic                        load_weight_i,
  input  logic signed [Width-1:0]     data_i,
  input  logic signed [Width-1:0]     weight_i,
  output  logic signed [Width-1:0]    weight_o,
  input  logic signed [AccWidth-1:0]  prevout_i,
  output logic signed [AccWidth-1:0]  result_o,
  output logic signed [Width-1:0]     data_o
);

logic signed [Width-1:0]    weight_q;
logic signed [AccWidth-1:0] y_q;
logic signed [Width-1:0]    x_q;
logic signed [AccWidth-1:0] y_int;
logic signed [2*Width-1:0]  mul_res;

assign result_o = y_q;
assign data_o   = x_q;
assign weight_o = weight_q;

// Output register y
always_ff @(posedge clk_i or posedge rst_i) begin 
  if (rst_i == 1'b1) begin
    y_q <= '0;
  end else begin
    y_q <= y_int;
  end
end

// Propagation of input x
always_ff @(posedge clk_i or posedge rst_i) begin 
  if (rst_i == 1'b1) begin
    x_q <= '0;
  end else begin
    x_q <= data_i;
  end
end

// Weight-Stationary Register
always_ff @(posedge clk_i or posedge rst_i) begin
  if (rst_i == 1'b1) begin 
    weight_q <= '0;
  end else if (load_weight_i == 1'b1) begin
    weight_q <= weight_i;
  end
end

// Result generation: y = prev_y + x*w
always_comb begin
  mul_res = data_i*weight_q;
  y_int = prevout_i + AccWidth'(mul_res);
end 

endmodule
