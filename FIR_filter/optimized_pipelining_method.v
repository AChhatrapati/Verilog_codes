module experiment_5_opt_pipe #(parameter N = 100)(
  input clk,
  input rst,
  input signed [15:0] x_in,
  input signed [15:0] coeff_in,
  input load_coeff,       
  input start,          
  output reg signed [31:0] y_out
);
  reg signed [15:0] shift_reg [0:N-1];
  reg signed [15:0] coeffs [0:N-1];
  integer i;
  reg [6:0] coeff_index;  
  reg signed [31:0] product [0:(N/2)];
  reg signed [31:0] addition [0:(N/2)];
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      y_out <= 0;
      coeff_index <= 0;
      for (i = 0; i < N; i = i + 1) begin
        coeffs[i] <= 0;
        shift_reg[i] <= 0;
      end
		for (i = 0; i <= (N/2); i = i + 1) begin
        product[i] <= 0;
        addition[i] <= 0;
      end
    end 
    else if (load_coeff) begin
      coeffs[coeff_index] <= coeff_in;
      coeff_index <= coeff_index + 1;
    end 
    else if (start) begin
      for (i = N-1; i > 0; i = i - 1)
        shift_reg[i] <= shift_reg[i-1];
      shift_reg[0] <= x_in;
	   for (i = 0; i < (N/2); i = i + 1)
        product[i] <= coeffs[i] * (shift_reg[i] + shift_reg[N-1-i]);
      if (N % 2 == 1)
        product[N/2] <= coeffs[N/2] * shift_reg[N/2];
      else
        product[N/2] <= 0;
      addition[0] <= product[0];
      for (i = 1; i <= (N/2); i = i + 1)
        addition[i] <= addition[i-1] + product[i];
      y_out <= addition[N/2];
    end
  end
endmodule
