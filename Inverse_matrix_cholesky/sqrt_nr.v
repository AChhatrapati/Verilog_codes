module sqrt_nr (
    input  wire clk,
    input  wire rst_n,
    input  wire in_valid,
    input  wire signed [31:0] in_val,
    output reg  signed [31:0] out_val,
    output reg out_valid
);
    reg signed [31:0] pipe_val [0:4];
    reg signed [31:0] pipe_x [0:4];
    reg valid_pipe [0:4];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 5; i = i + 1) begin
                pipe_val[i] <= 32'd0;
                pipe_x[i] <= 32'd0;
                valid_pipe[i] <= 1'b0;
            end
            out_val <= 32'd0;
            out_valid <= 1'b0;
        end 
		  else begin
            pipe_val[0] <= in_val;
            if (in_val != 32'd0) begin
                pipe_x[0] <= (in_val > 32'd0) ? (in_val >>> 1) : 32'd0;
            end 
				else begin
                pipe_x[0] <= 32'd0;
            end
            valid_pipe[0] <= in_valid;
            if (pipe_x[0] != 32'd0) begin
                pipe_x[1] <= (pipe_x[0] + (({pipe_val[0][31], pipe_val[0]} << 29) / pipe_x[0])) >>> 1;
            end 
				else begin
                pipe_x[1] <= 32'd0;
            end
            pipe_val[1] <= pipe_val[0];
            valid_pipe[1] <= valid_pipe[0];
            if (pipe_x[1] != 32'd0) begin
                pipe_x[2] <= (pipe_x[1] + (({pipe_val[1][31], pipe_val[1]} << 29) / pipe_x[1])) >>> 1;
            end 
				else begin
                pipe_x[2] <= 32'd0;
            end
            pipe_val[2] <= pipe_val[1];
            valid_pipe[2] <= valid_pipe[1];
            if (pipe_x[2] != 32'd0) begin
                pipe_x[3] <= (pipe_x[2] + (({pipe_val[2][31], pipe_val[2]} << 29) / pipe_x[2])) >>> 1;
            end 
				else begin
                pipe_x[3] <= 32'd0;
            end
            pipe_val[3] <= pipe_val[2];
            valid_pipe[3] <= valid_pipe[2];
            if (pipe_x[3] != 32'd0) begin
                pipe_x[4] <= (pipe_x[3] + (({pipe_val[3][31], pipe_val[3]} << 29) / pipe_x[3])) >>> 1;
            end 
				else begin
                pipe_x[4] <= 32'd0;
            end
            pipe_val[4] <= pipe_val[3];
            valid_pipe[4] <= valid_pipe[3];
            out_val <= pipe_x[4];
            out_valid <= valid_pipe[4];
        end
    end
endmodule