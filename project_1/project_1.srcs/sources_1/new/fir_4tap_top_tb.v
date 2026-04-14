`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2026 05:03:01 PM
// Design Name: 
// Module Name: fir_4tap_top_tb
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


module fir_4tap_top_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz clock

    // Inputs to the DUT (Device Under Test)
    reg                     i_clk;
    reg                     i_rst_n;
    reg  signed [7:0]       i_data;

    // Outputs from the DUT
    wire signed [7:0]       o_data;

    // Instantiate the Unit Under Test (UUT)
    fir_4tap_top uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_data(i_data),
        .o_data(o_data)
    );

    // Clock Generation
    initial begin
        i_clk = 0;
        forever #(CLK_PERIOD/2) i_clk = ~i_clk;
    end

    // Stimulus Process
    initial begin
        // Initialize Inputs
        i_rst_n = 0;
        i_data = 8'd0;

        // Apply Asynchronous Reset [cite: 8, 43]
        #(CLK_PERIOD * 2);
        i_rst_n = 1;
        #(CLK_PERIOD);

        // --- Test Case 1: Unit Impulse Response ---
        // Sending a single pulse to see the filter coefficients in the output
        $display("Starting Unit Impulse Test...");
        i_data = 8'd10; // Input a value (scaled for Q8.7 context)
        #(CLK_PERIOD);
        i_data = 8'd0;
        
        // Wait for data to propagate through the 5-tap pipeline [cite: 47-50]
        #(CLK_PERIOD * 10);

        // --- Test Case 2: Constant DC Input ---
        $display("Starting DC Input Test...");
        i_data = 8'd5; 
        #(CLK_PERIOD * 10);
        
        // --- Test Case 3: Zero Input ---
        i_data = 8'd0;
        #(CLK_PERIOD * 10);

        $display("Simulation Finished.");
        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | i_data: %d | o_data: %d", $time, i_data, o_data);
    end

endmodule