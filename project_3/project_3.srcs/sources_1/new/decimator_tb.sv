`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 08:22:17 PM
// Design Name: 
// Module Name: decimator
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

module decimator_tb;

    parameter DATA_W     = 12;
    parameter COEFF_W    = 12;
    parameter CAS_W      = 32;
    parameter TAPS       = 7;   
    parameter DEC_FACTOR = 3;  // 100MHz -> 10MHz

    reg i_clk;
    reg i_rst_n;
    reg  signed [DATA_W-1:0]  i_data;
    reg  signed [COEFF_W-1:0] tb_coeffs [0:TAPS-1];
    
    wire signed [CAS_W-1:0]   o_decimated_data;
    wire                      o_data_valid;

    // Unit Under Test (UUT)
    decimator_a #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .CAS_W(CAS_W),
        .TAPS(TAPS),
        .DEC_FACTOR(DEC_FACTOR)
    ) uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_data(i_data),
        .i_coeffs(tb_coeffs),
        .o_decimated_data(o_decimated_data),
        .o_data_valid(o_data_valid)
    );

    // 100MHz Clock Generation (10ns period)
    initial begin
        i_clk = 1'b0;
    end
    always begin
        #5 i_clk = ~i_clk; 
    end
    
    // constants for sine wave generation 
    real pi = 3.14159;
    real frequency = 1000000;         // 1 MHz baseband signal
    real sampling_rate = 100000000;   // Input sampling rate: 100 MHz
    real amplitude = 2047.0;          // Max amplitude for 12-bit signed
    integer step = 0;

    // Stimulus Generation Block
    initial begin
        // 1. Initialize Inputs
        i_rst_n = 1'b0;
        i_data  = {DATA_W{1'b0}};
        
        // 2. Set up dummy coefficients (symmetric pass-through for test stability)
        tb_coeffs[0] = 12'sd1;  
        tb_coeffs[1] = 12'sd2;  
        tb_coeffs[2] = 12'sd3;  
        tb_coeffs[3] = 12'sd4;  
        tb_coeffs[4] = 12'sd3;
        tb_coeffs[5] = 12'sd2;
        tb_coeffs[6] = 12'sd1;

        #100;
        
        @(posedge i_clk);
        i_rst_n = 1'b1;
        
        $display("[TB] Starting continuous sample driving...");
        repeat(200) begin
            @(posedge i_clk);
            i_data = $rtoi(amplitude * $sin(2.0 * pi * frequency * step / sampling_rate));
            step = step + 1;
        end

        $display("[TB] Simulation Finished.");
        $finish;
    end

    // Output monitoring block,looks for the 10MHz valid pulse 
    always @(posedge i_clk) begin
        if (i_rst_n && o_data_valid) begin
            $display("[OUTPUT] Time=%0t ns | Valid Strobe Received! Decimated Out = %0d", 
                     $time, o_decimated_data);
        end
    end

endmodule