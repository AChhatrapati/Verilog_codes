module lower_inverse_stage (
    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,
    input  wire signed [2047:0] L_real_in,
    input  wire signed [2047:0] L_imag_in,
    output reg  signed [2047:0] L_inv_real_out,
    output reg  signed [2047:0] L_inv_imag_out,
    output reg out_valid
);
    parameter IDLE = 2'd0;
    parameter COMPUTE = 2'd1;
    parameter DONE = 2'd2;
    reg [1:0] state;
    reg [2:0] i_reg, j_reg, k_reg;
    reg signed [31:0] L_real [0:63];
    reg signed [31:0] L_imag [0:63];
    reg signed [31:0] L_inv_real [0:63];
    reg signed [31:0] L_inv_imag [0:63];
    reg signed [63:0] sum_real_reg;
    reg signed [63:0] sum_imag_reg;
    reg signed [63:0] denom_reg;
    reg signed [31:0] div_real_reg;
    reg signed [31:0] div_imag_reg;
    reg div_valid_reg;
    integer idx;
    always @(*) begin
        for (idx = 0; idx < 64; idx = idx + 1) begin
            L_real[idx] = L_real_in[(idx+1)*32-1 -: 32];
            L_imag[idx] = L_imag_in[(idx+1)*32-1 -: 32];
        end
    end
    always @(*) begin
        for (idx = 0; idx < 64; idx = idx + 1) begin
            L_inv_real_out[(idx+1)*32-1 -: 32] = L_inv_real[idx];
            L_inv_imag_out[(idx+1)*32-1 -: 32] = L_inv_imag[idx];
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            out_valid <= 1'b0;
            i_reg <= 3'd0;
            j_reg <= 3'd0;
            k_reg <= 3'd0;
            sum_real_reg <= 64'd0;
            sum_imag_reg <= 64'd0;
            denom_reg <= 64'd0;
            div_valid_reg <= 1'b0;
            for (idx = 0; idx < 64; idx = idx + 1) begin
                L_inv_real[idx] <= 32'd0;
                L_inv_imag[idx] <= 32'd0;
            end
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
                        sum_real_reg <= 64'd0;
                        sum_imag_reg <= 64'd0;
                    end
                end
                COMPUTE: begin
                    if (i_reg < 3'd8) begin
                        if (j_reg <= i_reg) begin
                            if (i_reg == j_reg) begin
                                denom_reg <= (($signed(L_real[i_reg*8 + i_reg]) * $signed(L_real[i_reg*8 + i_reg]) + $signed(L_imag[i_reg*8 + i_reg]) * $signed(L_imag[i_reg*8 + i_reg])) >>> 29);
                                if (denom_reg != 64'd0) begin
                                    L_inv_real[i_reg*8 + i_reg] <= ($signed(L_real[i_reg*8 + i_reg]) << 29) / denom_reg;
                                    L_inv_imag[i_reg*8 + i_reg] <= ($signed(-L_imag[i_reg*8 + i_reg]) << 29) / denom_reg;
                                end 
										  else begin
                                    L_inv_real[i_reg*8 + i_reg] <= 32'd0;
                                    L_inv_imag[i_reg*8 + i_reg] <= 32'd0;
                                end
                                j_reg <= j_reg + 1;
                            end 
									 else begin
                                if (k_reg < i_reg) begin
                                    sum_real_reg <= sum_real_reg + (($signed(L_real[i_reg*8 + k_reg]) * $signed(L_inv_real[k_reg*8 + j_reg]) - $signed(L_imag[i_reg*8 + k_reg]) * $signed(L_inv_imag[k_reg*8 + j_reg])) >>> 29);
                                    sum_imag_reg <= sum_imag_reg + (($signed(L_real[i_reg*8 + k_reg]) * $signed(L_inv_imag[k_reg*8 + j_reg]) + $signed(L_imag[i_reg*8 + k_reg]) * $signed(L_inv_real[k_reg*8 + j_reg])) >>> 29);
                                    k_reg <= k_reg + 1;
                                end 
										  else begin
                                    denom_reg <= (($signed(L_real[i_reg*8 + i_reg]) * $signed(L_real[i_reg*8 + i_reg]) + $signed(L_imag[i_reg*8 + i_reg]) * $signed(L_imag[i_reg*8 + i_reg])) >>> 29);
                                    if (denom_reg != 64'd0) begin
                                        div_real_reg <= ($signed(L_real[i_reg*8 + i_reg]) << 29) / denom_reg;
                                        div_imag_reg <= ($signed(-L_imag[i_reg*8 + i_reg]) << 29) / denom_reg;
                                        div_valid_reg <= 1'b1;
                                        if (div_valid_reg) begin
                                            L_inv_real[i_reg*8 + j_reg] <= (($signed(-sum_real_reg) * div_real_reg - $signed(-sum_imag_reg) * div_imag_reg) >>> 29);
                                            L_inv_imag[i_reg*8 + j_reg] <= (($signed(-sum_real_reg) * div_imag_reg + $signed(-sum_imag_reg) * div_real_reg) >>> 29);
                                            j_reg <= j_reg + 1;
                                            k_reg <= j_reg + 1;
                                            sum_real_reg <= 64'd0;
                                            sum_imag_reg <= 64'd0;
                                            div_valid_reg <= 1'b0;
                                        end
                                    end 
												else begin
                                        L_inv_real[i_reg*8 + j_reg] <= 32'd0;
                                        L_inv_imag[i_reg*8 + j_reg] <= 32'd0;
                                        j_reg <= j_reg + 1;
                                        k_reg <= j_reg + 1;
                                        sum_real_reg <= 64'd0;
                                        sum_imag_reg <= 64'd0;
                                        div_valid_reg <= 1'b0;
                                    end
                                end
                            end
                        end 
								else begin
                            i_reg <= i_reg + 1;
                            j_reg <= 3'd0;
                            k_reg <= 3'd0;
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