module top_fir_sim;
    reg clk = 0;
    reg reset_n = 0;
    reg signed [15:0] data_in;
    wire signed [31:0] data_out;
    fir_ip_chhatrapati u0 (
        .clk(clk),
        .reset_n(reset_n),
        .ast_sink_data(data_in),
        .ast_sink_valid(1'b1),
        .ast_source_data(data_out),
        .ast_source_valid()
    );
    // Clock generator
    always #5 clk = ~clk; 
    initial begin
        reset_n = 0;
        #10 reset_n = 1;
        data_in = 16'sd0;    #10;
        data_in = 16'sd8192; #10;
        data_in = -16'sd4096;#10;
        // Continue as needed for your sinewave file
        #200 $stop; 
    end
endmodule
