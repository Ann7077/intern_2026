`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2026 08:51:22 PM
// Design Name: 
// Module Name: fir_filter_tb
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


module fir_filter_tb;

    // Parameters
    parameter DATA_W  = 12;
    parameter COEFF_W = 12;
    parameter CAS_W   = 32;

    // Inputs
    reg i_clk;
    reg i_rst_n;
    reg signed [DATA_W-1:0] i_data;

    // Outputs
    wire signed [CAS_W-1:0]  o_data;

    // Unit Under Test
    fir_filter #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .CAS_W(CAS_W)
    ) uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_data(i_data),
        .o_data(o_data)
    );

    // Clock Generation 
    always begin
        #5 i_clk = ~i_clk; // 100MHz clock
    end

    // Stimulus Block
    initial begin
        // Initialize Inputs
        i_clk   = 1'b0;
        i_rst_n = 1'b0;
        i_data  = {DATA_W{1'b0}};

        #100;
        
        // Release Reset
        @(posedge i_clk);
        i_rst_n = 1'b1;
        
        // Apply Step Input to observe impulse/step response across 32 taps
        @(posedge i_clk);
        i_data = 12'sd10;
        
        // Run simulation long enough to let the data propagate through all 32 stages
        #1000;
        
        // Finish simulation
        $finish;
    end

endmodule
