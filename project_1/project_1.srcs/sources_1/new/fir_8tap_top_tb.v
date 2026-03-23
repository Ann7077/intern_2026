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
    reg          clk;
    reg          rst_n;
    reg  [7:0]   i_data;
    wire [7:0]   o_data;

    // Filter Coefficients from assignment [cite: 6]
    // We use the first 8 for an 8-tap filter
    reg [7:0] h[0:7];
    initial begin
        h[0] = 8'd7;  h[1] = 8'd17; h[2] = 8'd32; h[3] = 8'd46;
        h[4] = 8'd52; h[5] = 8'd46; h[6] = 8'd32; h[7] = 8'd17;
    end

    // Input data buffer to calculate expected value
    reg [7:0] x_pipe[0:7];
    integer i;

    // Instantiate the Top Module
    fir_8tap_top dut (
        .i_clk   (clk),
        .i_rst_n (rst_n),
        .i_data  (i_data),
        .o_data  (o_data)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Expected Value Calculation Logic
    reg [31:0] expected_full;
    reg [7:0]  expected_scaled;
    
    // The diagram shows a deep pipeline (Layer 1 to Layer 5)
    // We need to account for the cycles it takes for data to reach the output
    reg [7:0] expected_history[0:15]; 

    initial begin
        // Initialize
        rst_n = 0;
        i_data = 0;
        for(i=0; i<8; i=i+1) x_pipe[i] = 0;
        
        #20 rst_n = 1; 

        // Stimulus: Feed a step input (all 10s)
        repeat(20) begin
            @(posedge clk);
            i_data = 8'd10; 
            
            // Shift software pipeline for expected calc
            for(i=7; i>0; i=i-1) x_pipe[i] = x_pipe[i-1];
            x_pipe[0] = i_data;

            // Calculate Sum of (Products)
            expected_full = (x_pipe[0]*h[0]) + (x_pipe[1]*h[1]) + (x_pipe[2]*h[2]) + (x_pipe[3]*h[3]) +
                            (x_pipe[4]*h[4]) + (x_pipe[5]*h[5]) + (x_pipe[6]*h[6]) + (x_pipe[7]*h[7]);
            
            // Apply Q8.7 scaling (shift right 7) as seen in mac_u 
            expected_scaled = expected_full >> 7;

            // Shift history to align with hardware pipeline delay
            for(i=15; i>0; i=i-1) expected_history[i] = expected_history[i-1];
            expected_history[0] = expected_scaled;

            $display("In: %d | Hardware Out: %d | Expected (delayed): %d", 
                      i_data, o_data, expected_history[10]); // Adjusted for pipe depth
        end

        #100 $finish;
    end

endmodule