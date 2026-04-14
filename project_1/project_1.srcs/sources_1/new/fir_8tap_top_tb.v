`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2026 01:46:27 PM
// Design Name: 
// Module Name: fir_8tap_top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fir_8tap_top_tb();

    // Signals
    reg                   clk;
    reg                   rst_n;
    reg  signed [7:0]     i_data;   // Updated to signed
    wire signed [7:0]     o_data;   // Updated to signed

    // Filter Coefficients (9 Taps: h0 to h8)
    reg signed [7:0] h[0:8];
    initial begin
        h[0] = 8'd7;  h[1] = 8'd17; h[2] = 8'd32; h[3] = 8'd46;
        h[4] = 8'd52; h[5] = 8'd46; h[6] = 8'd32; h[7] = 8'd17; h[8] = 8'd7;
    end

    // Instantiate the Top Module
    fir_8tap_top uut (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_data(i_data),
        .o_data(o_data)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Pipeline Emulation for "Expected" Value ---
    // Total Latency: 9 MAC stages (2 cycles each) + 1 cycle for o_data register = 19 cycles
    reg signed [7:0] expected_history [0:19]; 
    integer i, j;

    // Calculation Logic
    reg signed [15:0] prod;
    reg signed [7:0]  chain_sum;
    reg signed [7:0]  x_pipe [0:8];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<20; i=i+1) expected_history[i] <= 0;
            for (i=0; i<9; i=i+1) x_pipe[i] <= 0;
        end else begin
            // 1. Shift Software Data Pipe
            for (i=8; i>0; i=i-1) x_pipe[i] <= x_pipe[i-1];
            x_pipe[0] <= i_data;

            // 2. Emulate the "Chain" Math (matching mac_u.v)
            // Each stage in hardware scales (shifts). We do the same here.
            chain_sum = 0;
            for (i=0; i<9; i=i+1) begin
                prod = x_pipe[i] * h[i];
                // Using >>> 7 to match your mac_u.v logic
                chain_sum = (prod[15:8]) + chain_sum; 
            end

            // 3. Store in History Buffer to account for 19-cycle latency
            for (j=19; j>0; j=j-1) expected_history[j] <= expected_history[j-1];
            expected_history[0] <= chain_sum;
        end
    end

    // --- Stimulus ---
    initial begin
        rst_n = 0;
        i_data = 0;
        #20 rst_n = 1;

        // Test Case 1: Impulse Response
        @(posedge clk);
        i_data = 8'sd127; // Maximum positive
        @(posedge clk); 
        i_data = 8'sd0;
        
        repeat(30) @(posedge clk);

        // Test Case 2: Step Input
        repeat(20) begin
            @(posedge clk);
            i_data = 8'sd10; 
        end

        repeat(50) @(posedge clk);
        $stop;
    end

    // --- Verification Monitor ---
    always @(posedge clk) begin
        if (rst_n) begin
            $display("Time: %t | In: %d | Out: %d | Exp: %d", 
                      $time, i_data, o_data, expected_history[19]);
        end
    end

endmodule