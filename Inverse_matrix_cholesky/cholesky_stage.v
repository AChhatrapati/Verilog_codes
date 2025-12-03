module cholesky_stage (
    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,
    input  wire signed [2047:0] in_real,
    input  wire signed [2047:0] in_imag,
    output reg  signed [2047:0] L_real_out,
    output reg  signed [2047:0] L_imag_out,
    output reg out_valid
);
    parameter IDLE = 3'd0;
    parameter COMPUTE = 3'd1;
    parameter DONE = 3'd2;
    reg [2:0] state;
    reg [2:0] i_reg, j_reg, k_reg;
    reg signed [31:0] mat_real [0:63];
    reg signed [31:0] mat_imag [0:63];
    reg signed [31:0] L_real [0:63];
    reg signed [31:0] L_imag [0:63];
    reg signed [63:0] sum_real_reg;
    reg signed [63:0] sum_imag_reg;
    // Square root
    reg sqrt_in_valid;
    wire sqrt_out_valid;
    reg signed [31:0] sqrt_in_val;
    wire signed [31:0] sqrt_out_val;
    integer idx;
    integer p, q;
    always @(*) begin
        for (idx = 0; idx < 64; idx = idx + 1) begin
            mat_real[idx] = in_real[(idx+1)*32-1 -: 32];
            mat_imag[idx] = in_imag[(idx+1)*32-1 -: 32];
        end
    end
    always @(*) begin
        for (idx = 0; idx < 64; idx = idx + 1) begin
            L_real_out[(idx+1)*32-1 -: 32] = L_real[idx];
            L_imag_out[(idx+1)*32-1 -: 32] = L_imag[idx];
        end
    end
    // square root module
    sqrt_nr sqrt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(sqrt_in_valid),
        .in_val(sqrt_in_val),
        .out_val(sqrt_out_val),
        .out_valid(sqrt_out_valid)
    );
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            out_valid <= 1'b0;
            i_reg <= 3'd0;
            j_reg <= 3'd0;
            k_reg <= 3'd0;
            sum_real_reg <= 64'd0;
            sum_imag_reg <= 64'd0;
            sqrt_in_val <= 32'd0;
            sqrt_in_valid <= 1'b0;
            for (idx = 0; idx < 64; idx = idx + 1) begin
                L_real[idx] <= 32'd0;
                L_imag[idx] <= 32'd0;
            end
        end 
		  else begin
            case (state)
                IDLE: begin
                    out_valid <= 1'b0;
                    sqrt_in_valid <= 1'b0;
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
                            if (k_reg < j_reg) begin
                                //L[i,j]
                                p = i_reg*8 + k_reg;
                                q = j_reg*8 + k_reg;
                                sum_real_reg <= sum_real_reg + (($signed(L_real[p]) * $signed(L_real[q]) + $signed(L_imag[p]) * $signed(L_imag[q])) >>> 29);
                                sum_imag_reg <= sum_imag_reg + (($signed(L_imag[p]) * $signed(L_real[q]) - $signed(L_real[p]) * $signed(L_imag[q])) >>> 29);
                                k_reg <= k_reg + 1;
                            end 
									 else begin
                                if (i_reg == j_reg) begin
                                    //L[i,i]
                                    sqrt_in_val <= mat_real[i_reg*8 + i_reg] - (sum_real_reg >>> 29);
                                    sqrt_in_valid <= 1'b1;
                                    if (sqrt_out_valid) begin
                                        L_real[i_reg*8 + i_reg] <= sqrt_out_val;
                                        L_imag[i_reg*8 + i_reg] <= 32'd0;
                                        j_reg <= j_reg + 1;
                                        k_reg <= 3'd0;
                                        sum_real_reg <= 64'd0;
                                        sum_imag_reg <= 64'd0;
                                        sqrt_in_valid <= 1'b0;
                                    end
                                end 
										  else begin
                                    //L[j,i]
                                    if (L_real[j_reg*8 + j_reg] != 32'd0) begin
                                        L_real[i_reg*8 + j_reg] <= (($signed(mat_real[i_reg*8 + j_reg] - (sum_real_reg >>> 29)) << 29) / $signed(L_real[j_reg*8 + j_reg]));
                                        L_imag[i_reg*8 + j_reg] <= (($signed(mat_imag[i_reg*8 + j_reg] - (sum_imag_reg >>> 29)) << 29) / $signed(L_real[j_reg*8 + j_reg]));
                                    end 
												else begin
                                        L_real[i_reg*8 + j_reg] <= 32'd0;
                                        L_imag[i_reg*8 + j_reg] <= 32'd0;
                                    end
                                    j_reg <= j_reg + 1;
                                    k_reg <= 3'd0;
                                    sum_real_reg <= 64'd0;
                                    sum_imag_reg <= 64'd0;
                                    sqrt_in_valid <= 1'b0;
                                end
                            end
                        end 
								else begin
                            i_reg <= i_reg + 1;
                            j_reg <= 3'd0;
                            sqrt_in_valid <= 1'b0;
                        end
                    end 
						  else begin
                        state <= DONE;
                        out_valid <= 1'b1;
                        sqrt_in_valid <= 1'b0;
                    end
                end
                DONE: begin
                    out_valid <= 1'b0;
                    state <= IDLE;
                    sqrt_in_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule