module pe #(
  parameter int Width = 8
) (
  input  logic              clk_i, 
  input  logic              rst_i,
  input  logic [Width-1:0]  data_i,
  input  logic [Width-1:0]  weight_i,
  input  logic [Width-1:0]  prevout_i,
  output logic [31:0]       result_o,
  output logic [Width-1:0]  data_o
);

logic [Width-1:0]      weight_q;
logic [31:0]           y_q;
logic [Width-1:0]      x_q;
logic [31:0]           y_int;

assign result_o = y_q;
assign data_o = x_q;

//Output register y
always_ff @(posedge clk_i or posedge rst_i) begin 
  if (rst_i == 1'b1) begin
    y_q <= 32'h0000;
  end else 
    y_q <= y_int;
end


//Propagation of input x
always_ff @(posedge clk_i or posedge rst_i) begin 
  if (rst_i == 1'b1) begin
    x_q <= 8'h00;
  end else 
    x_q <= data_i;
end


//Weight-Stationary Register
always_ff @(posedge clk_i or posedge rst_i) begin
  if (rst_i == 1'b1) begin 
    weight_q <= 8'h00;
  end else 
    weight_q <= weight_i;
end

//Result generation: y = prev_y + x*w
always_comb begin 
  y_int = 32'(prevout_i) + 32'(data_i) * 32'(weight_i);
end 
endmodule
