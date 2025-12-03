module experiment_6_opt_parallel #(parameter N = 99)(
  input wire clk,
  input wire rst,
  input wire signed [15:0] x_in0,
  input wire signed [15:0] x_in1,
  input wire signed [15:0] x_in2,
  input wire signed [15:0] coeff_in,
  input wire load_coeff,
  input wire start,
  output reg signed [31:0] y_out0,
  output reg signed [31:0] y_out1,
  output reg signed [31:0] y_out2
);

  localparam M = N/3; 
  
  reg signed [15:0] shift_reg [0:N+2];
  reg signed [15:0] coeffs0 [0:M-1];  
  reg signed [15:0] coeffs1 [0:M-1];  
  reg signed [15:0] coeffs2 [0:M-1]; 
  integer i;
  reg [6:0] coeff_index;
  
  reg signed [31:0] acc0;
  reg signed [31:0] acc1;
  reg signed [31:0] acc2;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      coeff_index <= 0;
      y_out0 <= 0;
      y_out1 <= 0;
      y_out2 <= 0;
      acc0 <= 0;
      acc1 <= 0;
      acc2 <= 0;
      for (i = 0; i < N+3; i = i + 1)
        shift_reg[i] <= 0;
      for (i = 0; i < M; i = i + 1) begin
        coeffs0[i] <= 0;
        coeffs1[i] <= 0;
        coeffs2[i] <= 0;
      end
    end 
    else if (load_coeff) begin
      if (coeff_index < M) begin
        coeffs0[coeff_index] <= coeff_in;
      end
      else if (coeff_index < 2*M) begin
        coeffs1[coeff_index - M] <= coeff_in;
      end 
      else if (coeff_index < 3*M) begin
        coeffs2[coeff_index - 2*M] <= coeff_in;
      end
      coeff_index <= (coeff_index == 3*M-1) ? 0 : coeff_index + 1;
    end 
    else if (start) begin
      for (i = N+2; i >= 3; i = i - 1)
        shift_reg[i] <= shift_reg[i-3];
      shift_reg[2] <= x_in2;
      shift_reg[1] <= x_in1;
      shift_reg[0] <= x_in0;
      acc0 = 0;
      acc1 = 0;
      acc2 = 0;
      if (M % 2 == 0) begin
		  // even number of coefficients
        for (i = 0; i < M/2; i = i + 1) begin
          acc0 = acc0 + coeffs0[i] * (shift_reg[3*i] + shift_reg[3*(M-1-i)]);
          acc1 = acc1 + coeffs1[i] * (shift_reg[3*i+1] + shift_reg[3*(M-1-i)+1]);
          acc2 = acc2 + coeffs2[i] * (shift_reg[3*i+2] + shift_reg[3*(M-1-i)+2]);
        end
      end 
      else begin
        // Odd number of coefficients
        for (i = 0; i < M/2; i = i + 1) begin
          acc0 = acc0 + coeffs0[i] * (shift_reg[3*i] + shift_reg[3*(M-1-i)]);
          acc1 = acc1 + coeffs1[i] * (shift_reg[3*i+1] + shift_reg[3*(M-1-i)+1]);
          acc2 = acc2 + coeffs2[i] * (shift_reg[3*i+2] + shift_reg[3*(M-1-i)+2]);
        end
        acc0 = acc0 + coeffs0[M/2] * shift_reg[3*(M/2)];
        acc1 = acc1 + coeffs1[M/2] * shift_reg[3*(M/2)+1];
        acc2 = acc2 + coeffs2[M/2] * shift_reg[3*(M/2)+2];
      end
      y_out0 <= acc0;
      y_out1 <= acc1;
      y_out2 <= acc2;
    end
  end
endmodule