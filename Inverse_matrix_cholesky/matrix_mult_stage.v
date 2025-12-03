module matrix_mult_stage (
    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,
    input  wire signed [2047:0] L_inv_real_in,
    input  wire signed [2047:0] L_inv_imag_in,
    input  wire signed [2047:0] L_inv_tran_real_in,
    input  wire signed [2047:0] L_inv_tran_imag_in,
    output reg  signed [2047:0] out_real,
    output reg  signed [2047:0] out_imag,
    output reg out_valid
);
    parameter IDLE = 2'd0;
    parameter COMPUTE = 2'd1;
    parameter DONE = 2'd2;
    reg [1:0] state;
    reg [2:0] i_reg, j_reg, k_reg;
    reg signed [31:0] Linv_r [0:63];
    reg signed [31:0] Linv_i [0:63];
    reg signed [31:0] Linvtr_r [0:63];
    reg signed [31:0] Linvtr_i [0:63];
    reg signed [63:0] sum_real_reg [0:63];
    reg signed [63:0] sum_imag_reg [0:63];
    reg signed [63:0] prod_real_reg;
    reg signed [63:0] prod_imag_reg;
    integer idx;
    always @(*) begin
        for (idx = 0; idx < 64; idx = idx + 1) begin
            Linv_r[idx] = L_inv_real_in[(idx+1)*32-1 -: 32];
            Linv_i[idx] = L_inv_imag_in[(idx+1)*32-1 -: 32];
            Linvtr_r[idx] = L_inv_tran_real_in[(idx+1)*32-1 -: 32];
            Linvtr_i[idx] = L_inv_tran_imag_in[(idx+1)*32-1 -: 32];
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            out_valid <= 1'b0;
            i_reg <= 3'd0;
            j_reg <= 3'd0;
            k_reg <= 3'd0;
            prod_real_reg <= 64'd0;
            prod_imag_reg <= 64'd0;
            for (idx = 0; idx < 64; idx = idx + 1) begin
                sum_real_reg[idx] <= 64'd0;
                sum_imag_reg[idx] <= 64'd0;
            end
            out_real <= 2048'd0;
            out_imag <= 2048'd0;
        end 
		  else begin
            case (state)
                IDLE: begin
                    out_valid <= 1'b0;
                    if (in_valid) begin
                        state <= COMPUTE;
                        i_reg <= 3'd0;
                        j_reg <= 3'd0;
                        k_reg <= 3'd0;
                        for (idx = 0; idx < 64; idx = idx + 1) begin
                            sum_real_reg[idx] <= 64'd0;
                            sum_imag_reg[idx] <= 64'd0;
                        end
                    end
                end
                COMPUTE: begin
                    if (i_reg < 3'd8) begin
                        if (j_reg < 3'd8) begin
                            if (k_reg < 3'd8) begin
                                prod_real_reg <= ($signed(Linvtr_r[i_reg*8 + k_reg]) * $signed(Linv_r[k_reg*8 + j_reg]) - $signed(Linvtr_i[i_reg*8 + k_reg]) * $signed(Linv_i[k_reg*8 + j_reg]));
                                prod_imag_reg <= ($signed(Linvtr_r[i_reg*8 + k_reg]) * $signed(Linv_i[k_reg*8 + j_reg]) + $signed(Linvtr_i[i_reg*8 + k_reg]) * $signed(Linv_r[k_reg*8 + j_reg]));
                                sum_real_reg[i_reg*8 + j_reg] <= sum_real_reg[i_reg*8 + j_reg] + (prod_real_reg >>> 29);
                                sum_imag_reg[i_reg*8 + j_reg] <= sum_imag_reg[i_reg*8 + j_reg] + (prod_imag_reg >>> 29);
                                k_reg <= k_reg + 1;
                            end 
									 else begin
                                out_real[(i_reg*8 + j_reg + 1)*32-1 -: 32] <= sum_real_reg[i_reg*8 + j_reg][31:0];
                                out_imag[(i_reg*8 + j_reg + 1)*32-1 -: 32] <= sum_imag_reg[i_reg*8 + j_reg][31:0];
                                j_reg <= j_reg + 1;
                                k_reg <= 3'd0;
                            end
                        end 
								else begin
                            i_reg <= i_reg + 1;
                            j_reg <= 3'd0;
                        end
                    end 
						  else begin
                        state <= DONE;
                        out_valid <= 1'b1;
                    end
                end
                DONE: begin
                    out_valid <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule