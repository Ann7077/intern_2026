`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2026 10:43:32 PM
// Design Name: 
// Module Name: ddc_top_tb
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

module ddc_top_tb;

    // Clock and System Parameters
    localparam real CLK_FREQ = 100_000_000.0; // 100 MHz
    localparam real CLK_PERIOD = 1.0e9 / CLK_FREQ; // 10 ns period

    localparam INPUT_W     = 12;
    localparam DDS_W       = 12;
    localparam MIX_W       = 24;
    localparam COEFF_W     = 12;
    localparam FIR_OUT_W   = 32;
    localparam TAPS        = 32;
    localparam DEC_FACTOR  = 10;
    localparam PHASE_ACC_W = 32;

    localparam real F_TARGET = 19_000_000.0; // 20 MHz carrier
    localparam real F_INTERF = 35_000_000.0; // 35 MHz interference
    localparam real F_SAMP   = 100_000_000.0; // 100 MHz Sampling rate
    localparam real PI       = 3.1415926535;


    // Testbench Signals
    logic                      clk;
    logic                      rst_n;
    logic signed [INPUT_W-1:0] i_if_signal;
    logic signed [COEFF_W-1:0] i_coeffs [0:TAPS-1];

    wire signed  [FIR_OUT_W-1:0]   o_i_data;
    wire signed  [FIR_OUT_W-1:0]   o_q_data;
    wire                           o_data_valid;
    
    // Signal generation math variables
    real time_ns;
    real sig_target, sig_interf, sig_combined;

    // File I/O for Python FFT Analysis
    integer file_out;


    // DUT Instantiation
    ddc_top #(
        .INPUT_W    (INPUT_W),
        .DDS_W      (DDS_W),
        .MIX_W      (MIX_W),
        .COEFF_W    (COEFF_W),
        .FIR_OUT_W  (FIR_OUT_W),
        .TAPS       (TAPS),
        .DEC_FACTOR (DEC_FACTOR),
        .PHASE_ACC_W(PHASE_ACC_W),
        .F_SAMP     (CLK_FREQ),
        .F_CARR     ( )// F_TARGET
    ) uut (
        .clk          (clk),
        .rst_n        (rst_n),
        .i_if_signal  (i_if_signal),
        .i_coeffs     (i_coeffs),
        .o_i_data     (o_i_data),
        .o_q_data     (o_q_data),
        .o_data_valid (o_data_valid)
    );
    
    // Clock Generation (100 MHz)
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2.0) clk = ~clk;
    end

    // Ideal Symmetric Lowpass FIR Coefficients (32 Taps, Q1.11 format)
    initial begin
        i_coeffs[0]  = 12'sd1;   i_coeffs[1]  = 12'sd3;   i_coeffs[2]  = 12'sd6;   i_coeffs[3]  = 12'sd11;
        i_coeffs[4]  = 12'sd19;  i_coeffs[5]  = 12'sd31;  i_coeffs[6]  = 12'sd46;  i_coeffs[7]  = 12'sd66;
        i_coeffs[8]  = 12'sd89;  i_coeffs[9]  = 12'sd115; i_coeffs[10] = 12'sd142; i_coeffs[11] = 12'sd168;
        i_coeffs[12] = 12'sd192; i_coeffs[13] = 12 'sd212; i_coeffs[14] = 12'sd226; i_coeffs[15] = 12'sd233;
        i_coeffs[16] = 12'sd233; i_coeffs[17] = 12'sd226; i_coeffs[18] = 12'sd212; i_coeffs[19] = 12'sd192;
        i_coeffs[20] = 12'sd168; i_coeffs[21] = 12'sd142; i_coeffs[22] = 12'sd115; i_coeffs[23] = 12'sd89;
        i_coeffs[24] = 12'sd66;  i_coeffs[25] = 12'sd46;  i_coeffs[26] = 12'sd31;  i_coeffs[27] = 12'sd19;
        i_coeffs[28] = 12'sd11;  i_coeffs[29] = 12'sd6;   i_coeffs[30] = 12'sd3;   i_coeffs[31] = 12'sd1;
    end

    // Signal Generation: 20 MHz Signal + 35 MHz Interference
    initial begin
        // Reset sequence
        rst_n       = 0;
        i_if_signal = 0;
        #(CLK_PERIOD * 10);
        rst_n       = 1;

        // Open output file to dump IQ data for Python model verification
        file_out = $fopen("ddc_iq_output.txt", "w");
        if (file_out == 0) begin
            $display("ERROR: Failed to open output file ddc_iq_output.txt!");
            $finish;
        end

        // Run simulation for 2000 clock cycles (20 microseconds)
        repeat (2000) @(posedge clk) begin
            time_ns = $time * 1.0e-9;
            
            // Generate combined cosine waves: Target 20MHz + Interference 35MHz
            sig_target   = 1000.0 * $cos(2.0 * PI * F_TARGET * time_ns);
            sig_interf   = 0; // 800.0 * $cos(2.0 * PI * F_INTERF * time_ns);
            sig_combined = sig_target + sig_interf;

            // Quantize to 12-bit signed
            i_if_signal  <= $rtoi(sig_combined);
        end

        $fclose(file_out);
        $display("SUCCESS: Simulation finished. Decimated IQ data exported to ddc_iq_output.txt");
        $finish;
    end


    // Data Logging when valid output is ready (at 10 MHz sample rate)
    always @(posedge clk) begin
        if (rst_n && o_data_valid) begin
            $fdisplay(file_out, "%d %d", o_i_data, o_q_data);
        end
    end

endmodule