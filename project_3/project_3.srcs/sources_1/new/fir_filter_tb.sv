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
    parameter DATA_W  = 12;  // 12
    parameter COEFF_W = 12;  // 12
    parameter CAS_W   = 32;  // 32
    parameter TAPS = 5;

    // Inputs
    reg i_clk;
    reg i_rst_n;
    reg signed [DATA_W-1:0] i_data;
    
    reg signed [COEFF_W-1:0] tb_coeffs [0:TAPS-1];

    // Outputs
    wire signed [CAS_W-1:0]  o_data;

    // Unit Under Test
    fir_filter #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .CAS_W(CAS_W),
        .TAPS(TAPS)
    ) uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_data(i_data),
        .i_coeffs(tb_coeffs),
        .o_data(o_data)
    );

    // Clock Generation 
    always begin
        #5 i_clk = ~i_clk; // 100MHz clock
    end
    
    real pi = 3.14159265358979323846;
    real frequency = 5000000;         // Desired Sine Wave Frequency: 5 MHz
    real sampling_rate = 100000000;   // Your Clock Rate: 100 MHz (10ns period)
    real amplitude = 2047.0;          // Max amplitude for 12-bit signed integer (2^11 - 1)
    integer step = 0;

    // Stimulus Block
    initial begin
        // Initialize Inputs
        i_clk   = 1'b0;
        i_rst_n = 1'b0;
        i_data  = {DATA_W{1'b0}};
        
        // coefficients
        tb_coeffs[0] = 12'sd2;  
        tb_coeffs[1] = 12'sd4;  
        tb_coeffs[2] = 12'sd6;  
        tb_coeffs[3] = 12'sd4;  
        tb_coeffs[4] = 12'sd2;

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
    
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            i_data <= {DATA_W{1'b0}};
            step   <= 0;
        end else begin
            // Amplitude * sin(2 * pi * f * t)
            i_data <= $rtoi(amplitude * $sin(2.0 * pi * frequency * step / sampling_rate));
            step   <= step + 1;
        end
    end

endmodule
