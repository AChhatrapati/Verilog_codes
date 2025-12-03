module matrix_inv (
    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,
    output wire out_valid
);
    reg signed [2047:0] test_real;
    reg signed [2047:0] test_imag;
    wire signed [2047:0] in_real  = test_real;
    wire signed [2047:0] in_imag  = test_imag;
    integer i;
	 //input
    // Real part  : 1, 2, 3, ..., 64
    // Imag part  : 101, 102, ..., 164
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_real <= 0;
            test_imag <= 0;
        end 
        else if (in_valid) begin
            for (i = 0; i < 64; i = i + 1) begin
                test_real[i*32 +: 32] <= i + 1;
                test_imag[i*32 +: 32] <= i + 101;
            end
        end
    end
    combine core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_real(in_real),
        .in_imag(in_imag),
        .out_real(out_real),
        .out_imag(out_imag),
        .out_valid(out_valid)
    );
endmodule

module combine (
    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,
    input  wire signed [2047:0] in_real,
    input  wire signed [2047:0] in_imag,
    output wire signed [2047:0] out_real,
    output wire signed [2047:0] out_imag,
    output wire out_valid
);
    wire signed [2047:0] L_real_flat;
    wire signed [2047:0] L_imag_flat;
    wire signed [2047:0] L_inv_real_flat;
    wire signed [2047:0] L_inv_imag_flat;
    wire signed [2047:0] L_inv_tran_real_flat;
    wire signed [2047:0] L_inv_tran_imag_flat;
    wire done_chol;
    wire done_inv;
    wire done_tran;
    wire done_mult;
    reg signed [2047:0] L_real_reg;
    reg signed [2047:0] L_imag_reg;
    reg signed [2047:0] L_inv_real_reg;
    reg signed [2047:0] L_inv_imag_reg;
    reg signed [2047:0] L_inv_tran_real_reg;
    reg signed [2047:0] L_inv_tran_imag_reg;
    reg done_chol_reg;
    reg done_inv_reg;
    reg done_tran_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            L_real_reg <= 2048'd0;
            L_imag_reg <= 2048'd0;
            L_inv_real_reg <= 2048'd0;
            L_inv_imag_reg <= 2048'd0;
            L_inv_tran_real_reg <= 2048'd0;
            L_inv_tran_imag_reg <= 2048'd0;
            done_chol_reg <= 1'b0;
            done_inv_reg <= 1'b0;
            done_tran_reg <= 1'b0;
        end 
		  else begin
            L_real_reg <= L_real_flat;
            L_imag_reg <= L_imag_flat;
            L_inv_real_reg <= L_inv_real_flat;
            L_inv_imag_reg <= L_inv_imag_flat;
            L_inv_tran_real_reg <= L_inv_tran_real_flat;
            L_inv_tran_imag_reg <= L_inv_tran_imag_flat;
            done_chol_reg <= done_chol;
            done_inv_reg <= done_inv;
            done_tran_reg <= done_tran;
        end
    end
    cholesky_stage cs (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_real(in_real),
        .in_imag(in_imag),
        .L_real_out(L_real_flat),
        .L_imag_out(L_imag_flat),
        .out_valid(done_chol)
    );
    lower_inverse_stage lis (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(done_chol_reg),
        .L_real_in(L_real_reg),
        .L_imag_in(L_imag_reg),
        .L_inv_real_out(L_inv_real_flat),
        .L_inv_imag_out(L_inv_imag_flat),
        .out_valid(done_inv)
    );
    transpose_stage ts (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(done_inv_reg),
        .L_inv_real_in(L_inv_real_reg),
        .L_inv_imag_in(L_inv_imag_reg),
        .L_inv_tran_real_out(L_inv_tran_real_flat),
        .L_inv_tran_imag_out(L_inv_tran_imag_flat),
        .out_valid(done_tran)
    );
    matrix_mult_stage mms (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(done_tran_reg),
        .L_inv_real_in(L_inv_real_reg),
        .L_inv_imag_in(L_inv_imag_reg),
        .L_inv_tran_real_in(L_inv_tran_real_reg),
        .L_inv_tran_imag_in(L_inv_tran_imag_reg),
        .out_real(out_real),
        .out_imag(out_imag),
        .out_valid(done_mult)
    );
    assign out_valid = done_mult;
endmodule


