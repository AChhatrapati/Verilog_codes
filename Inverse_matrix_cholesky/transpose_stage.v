module transpose_stage (
    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,
    input  wire signed [2047:0] L_inv_real_in,
    input  wire signed [2047:0] L_inv_imag_in,
    output reg  signed [2047:0] L_inv_tran_real_out,
    output reg  signed [2047:0] L_inv_tran_imag_out,
    output reg out_valid
);
    reg signed [31:0] L_inv_real [0:63];
    reg signed [31:0] L_inv_imag [0:63];
    reg signed [31:0] L_inv_tran_real [0:63];
    reg signed [31:0] L_inv_tran_imag [0:63];
    reg valid_reg;
    integer i, j;
    always @(*) begin
        for (i = 0; i < 64; i = i + 1) begin
            L_inv_real[i] = L_inv_real_in[(i+1)*32-1 -: 32];
            L_inv_imag[i] = L_inv_imag_in[(i+1)*32-1 -: 32];
        end
    end
    always @(*) begin
        for (i = 0; i < 64; i = i + 1) begin
            L_inv_tran_real_out[(i+1)*32-1 -: 32] = L_inv_tran_real[i];
            L_inv_tran_imag_out[(i+1)*32-1 -: 32] = L_inv_tran_imag[i];
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            valid_reg <= 1'b0; 
            for (i = 0; i < 64; i = i + 1) begin
                L_inv_tran_real[i] <= 32'd0;
                L_inv_tran_imag[i] <= 32'd0;
            end
        end 
		  else begin
            valid_reg <= in_valid;
            if (in_valid) begin
                for (i = 0; i < 8; i = i + 1) begin
                    for (j = 0; j <= i; j = j + 1) begin
                        L_inv_tran_real[i*8 + j] <= L_inv_real[j*8 + i];
                        L_inv_tran_imag[i*8 + j] <= L_inv_imag[j*8 + i];
                    end
                end
            end
            out_valid <= valid_reg;
        end
    end
endmodule