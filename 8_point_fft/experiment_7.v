module experiment_7 (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [2:0] input_sel,     
    input wire signed [7:0] real_in, 
    input wire signed [7:0] imag_in,     
    output reg signed [10:0] real_out, 
    output reg signed [10:0] imag_out    
);
    //Twiddle Factors(Q2.5)
    localparam signed [7:0] W0_real = 8'b01000000;  // 1.00000
    localparam signed [7:0] W0_imag = 8'b00000000;  // 0.00000
    localparam signed [7:0] W1_real = 8'b00101101;  // 0.70711
    localparam signed [7:0] W1_imag = 8'b11010011;  // -0.70711
    localparam signed [7:0] W2_real = 8'b00000000;  // 0.00000
    localparam signed [7:0] W2_imag = 8'b11000000;  // -1.00000
    localparam signed [7:0] W3_real = 8'b11010011;  // -0.70711
    localparam signed [7:0] W3_imag = 8'b11010011;  // -0.70711
    reg signed [7:0] input_real [0:7];
    reg signed [7:0] input_imag [0:7];
	 reg [2:0] input_sel_reg;
    //pipeline stages
    reg signed [8:0] stage1_real [0:7];
    reg signed [8:0] stage1_imag [0:7];
    reg signed [9:0] stage2_real [0:7];
    reg signed [9:0] stage2_imag [0:7];
    reg signed [10:0] stage3_real [0:7];
    reg signed [10:0] stage3_imag [0:7];
    reg [1:0] pipeline_stage;
    integer i,j;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                input_real[i] <= 0;
                input_imag[i] <= 0;
            end
        end 
        else if (start) begin
            input_real[input_sel] <= real_in;
            input_imag[input_sel] <= imag_in;
				input_sel_reg <= input_sel + 1;
        end  
	  end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pipeline_stage <= 0;
            real_out <= 0;
            imag_out <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                stage1_real[i] <= 0;
                stage1_imag[i] <= 0;
                stage2_real[i] <= 0;
                stage2_imag[i] <= 0;
                stage3_real[i] <= 0;
                stage3_imag[i] <= 0;
            end
        end else if (input_sel_reg == 3'd7) begin
            case (pipeline_stage)
                // Stage 1
                2'd0: begin
                    stage1_real[0] <= input_real[0] + input_real[4];
                    stage1_imag[0] <= input_imag[0] + input_imag[4];
                    stage1_real[4] <= input_real[0] - input_real[4];
                    stage1_imag[4] <= input_imag[0] - input_imag[4];
                    stage1_real[1] <= input_real[1] + input_real[5];
                    stage1_imag[1] <= input_imag[1] + input_imag[5];
                    stage1_real[5] <= (input_real[1] - input_real[5]) * W2_real - (input_imag[1] - input_imag[5]) * W2_imag;
                    stage1_imag[5] <= (input_real[1] - input_real[5]) * W2_imag + (input_imag[1] - input_imag[5]) * W2_real;
                    stage1_real[2] <= input_real[2] + input_real[6];
                    stage1_imag[2] <= input_imag[2] + input_imag[6];
                    stage1_real[6] <= (input_real[2] - input_real[6]) * W1_real - (input_imag[2] - input_imag[6]) * W1_imag;
                    stage1_imag[6] <= (input_real[2] - input_real[6]) * W1_imag + (input_imag[2] - input_imag[6]) * W1_real;
                    stage1_real[3] <= input_real[3] + input_real[7];
                    stage1_imag[3] <= input_imag[3] + input_imag[7];
                    stage1_real[7] <= (input_real[3] - input_real[7]) * W3_real - (input_imag[3] - input_imag[7]) * W3_imag;
                    stage1_imag[7] <= (input_real[3] - input_real[7]) * W3_imag + (input_imag[3] - input_imag[7]) * W3_real;     
                    pipeline_stage <= 1;
                end
                // Stage 2
                2'd1: begin
                    stage2_real[0] <= stage1_real[0] + stage1_real[2];
                    stage2_imag[0] <= stage1_imag[0] + stage1_imag[2];
                    stage2_real[2] <= stage1_real[0] - stage1_real[2];
                    stage2_imag[2] <= stage1_imag[0] - stage1_imag[2];
                    stage2_real[1] <= stage1_real[1] + stage1_real[3];
                    stage2_imag[1] <= stage1_imag[1] + stage1_imag[3];
                    stage2_real[3] <= (stage1_real[1] - stage1_real[3]) * W2_real - (stage1_imag[1] - stage1_imag[3]) * W2_imag;
                    stage2_imag[3] <= (stage1_real[1] - stage1_real[3]) * W2_imag + (stage1_imag[1] - stage1_imag[3]) * W2_real;
                    stage2_real[4] <= stage1_real[4] + stage1_real[6];
                    stage2_imag[4] <= stage1_imag[4] + stage1_imag[6];
                    stage2_real[6] <= stage1_real[4] - stage1_real[6];
                    stage2_imag[6] <= stage1_imag[4] - stage1_imag[6];
                    stage2_real[5] <= stage1_real[5] + stage1_real[7];
                    stage2_imag[5] <= stage1_imag[5] + stage1_imag[7];
                    stage2_real[7] <= (stage1_real[5] - stage1_real[7]) * W2_real - (stage1_imag[5] - stage1_imag[7]) * W2_imag;
                    stage2_imag[7] <= (stage1_real[5] - stage1_real[7]) * W2_imag + (stage1_imag[5] - stage1_imag[7]) * W2_real;
                    pipeline_stage <= 2;
                end
                // Stage 3
                2'd2: begin
                    stage3_real[0] <= stage2_real[0] + stage2_real[1];
                    stage3_imag[0] <= stage2_imag[0] + stage2_imag[1];
                    stage3_real[1] <= stage2_real[0] - stage2_real[1];
                    stage3_imag[1] <= stage2_imag[0] - stage2_imag[1];
                    stage3_real[2] <= stage2_real[2] + stage2_real[3];
                    stage3_imag[2] <= stage2_imag[2] + stage2_imag[3];
                    stage3_real[3] <= (stage2_real[2] - stage2_real[3]) * W1_real - (stage2_imag[2] - stage2_imag[3]) * W1_imag;
                    stage3_imag[3] <= (stage2_real[2] - stage2_real[3]) * W1_imag + (stage2_imag[2] - stage2_imag[3]) * W1_real;
                    stage3_real[4] <= stage2_real[4] + stage2_real[5];
                    stage3_imag[4] <= stage2_imag[4] + stage2_imag[5];
                    stage3_real[5] <= (stage2_real[4] - stage2_real[5]) * W2_real - (stage2_imag[4] - stage2_imag[5]) * W2_imag;
                    stage3_imag[5] <= (stage2_real[4] - stage2_real[5]) * W2_imag + (stage2_imag[4] - stage2_imag[5]) * W2_real;
                    stage3_real[6] <= stage2_real[6] + stage2_real[7];
                    stage3_imag[6] <= stage2_imag[6] + stage2_imag[7];
                    stage3_real[7] <= (stage2_real[6] - stage2_real[7]) * W3_real - (stage2_imag[6] - stage2_imag[7]) * W3_imag;
                    stage3_imag[7] <= (stage2_real[6] - stage2_real[7]) * W3_imag + (stage2_imag[6] - stage2_imag[7]) * W3_real;    
                    pipeline_stage <= 3;
                end
                2'd3: begin
                    for (i = 0; i < 8; i = i + 1) begin
                        real_out[i] <= stage3_real[i];
                        imag_out[i] <= stage3_imag[i];
                    end
                    pipeline_stage <= 0;     
                end
            endcase
        end
    end
endmodule