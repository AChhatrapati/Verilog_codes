module FFB (
    input  signed [15:0] ain,
    input  signed [15:0] hi,
    input  signed [31:0] bin,
    output signed [31:0] bout
);
    assign bout = bin + ain * hi;
endmodule

module experiment_5_genvar #(parameter N = 100)(
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
  wire signed [31:0] b [0:N];  
  assign b[0] = 32'd0;
  genvar k;
  generate
    for (k = 0; k < N; k = k + 1) begin : FIR_CHAIN
      FFB DUT (
        .ain(shift_reg[k]),
        .hi(coeffs[k]),
        .bin(b[k]),
        .bout(b[k+1])
      );
    end
  endgenerate
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      y_out <= 0;
      coeff_index <= 0;
      for (i = 0; i < N; i = i + 1) begin
        coeffs[i] <= 0;
        shift_reg[i] <= 0;
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
      y_out <= b[N];
    end
  end
endmodule
