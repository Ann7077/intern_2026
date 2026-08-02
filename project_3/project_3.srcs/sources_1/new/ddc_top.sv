`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2026 10:16:28 PM
// Design Name: 
// Module Name: ddc_top
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

module ddc_top #(
    parameter INPUT_W      = 12,              // Bit width of incoming IF signal
    parameter DDS_W        = 12,              // Bit width of DDS sine/cosine outputs
    parameter MIX_W        = 24,              // Mixer output bit width (INPUT_W + DDS_W)
    parameter FIR_COEFF_W  = 12,              // FIR coefficient bit width
    parameter FIR_OUT_W    = 32,              // Final output bit width
    parameter FIR_TAPS     = 32,              // Number of FIR taps
    parameter DECI_COEFF_W = 12,              // Decimator coefficient bit width
    parameter DECI_TAPS    = 32,              // Number of decimator taps
    parameter DEC_FACTOR   = 10,              // Downsampling ratio (100MHz -> 10MHz)
    parameter PHASE_ACC_W  = 32,              // DDS Phase accumulator bit width 
    parameter real F_SAMP = 100_000_000.0,   // System clock / sampling rate (100 MHz) 
    parameter real F_CARR = 20_000_000.0     // Desired NCO center frequency (20 MHz) 
)(
    input  wire clk, 
    input  wire rst_n, // active-low 
    
    // Top-Level Input Signal (from testbench)
    input  wire signed [INPUT_W-1:0] i_if_signal,   
    
    // FIR Coefficients Array Port
    input  wire signed [FIR_COEFF_W-1:0] fir_coeffs [0:FIR_TAPS-1],

    // Decimator Coefficients Array Port
    input  wire signed [DECI_COEFF_W-1:0] deci_coeffs [0:DECI_TAPS-1],

    // Baseband IQ Outputs (10 MHz rate)
    output wire signed [FIR_OUT_W-1:0]   o_i_data,
    output wire signed [FIR_OUT_W-1:0]   o_q_data,
    output wire                          o_data_valid
);

    // 1. DDS / NCO Local Oscillator (20 MHz Output)
    localparam [PHASE_ACC_W-1:0] FTW = $rtoi(2.0 * $floor((F_CARR * 1.0) / (F_SAMP * 1.0) * (2.0**(PHASE_ACC_W - 1)) + 0.5));

    wire signed [DDS_W-1:0] dds_sin;
    wire signed [DDS_W-1:0] dds_cos;

    dds #(
        .PHASE_ACC_W (PHASE_ACC_W),
        .LUT_ADDR_W  (10),
        .LUT_OUT_W   (DDS_W)
    ) u_dds (
        .clk        (clk),
        .rst_n      (rst_n),
        .ftw        (FTW),
        .init_phase ({PHASE_ACC_W{1'b0}}),
        .dds_sin    (dds_sin),
        .dds_cos    (dds_cos)
    );

    // 2. Digital Quadrature Mixer
    wire signed [MIX_W-1:0] i_mix;
    wire signed [MIX_W-1:0] q_mix;

    mixer #(
        .IN_W  (INPUT_W),
        .OUT_W (MIX_W)
    ) u_mixer (
        .clk      (clk),
        .rst_n    (rst_n),
        .adc_data (i_if_signal), // Mapping i_if_signal to mixer's input port
        .dds_cos  (dds_cos),
        .dds_sin  (dds_sin),
        .i_out    (i_mix),
        .q_out    (q_mix)
    );
    
    // 3. FIR Filters
    wire signed [FIR_OUT_W-1:0] i_fir;
    wire signed [FIR_OUT_W-1:0] q_fir;

    fir_filter #(
        .DATA_W  (MIX_W),
        .COEFF_W (FIR_COEFF_W),
        .CAS_W   (FIR_OUT_W),
        .TAPS    (FIR_TAPS)
    ) u_fir_i (
        .i_clk    (clk),
        .i_rst_n  (rst_n),
        .i_data   (i_mix),
        .i_coeffs (fir_coeffs),
        .o_data   (i_fir)
    );

    fir_filter #(
        .DATA_W  (MIX_W),
        .COEFF_W (FIR_COEFF_W),
        .CAS_W   (FIR_OUT_W),
        .TAPS    (FIR_TAPS)
    ) u_fir_q (
        .i_clk    (clk),
        .i_rst_n  (rst_n),
        .i_data   (q_mix),
        .i_coeffs (fir_coeffs),
        .o_data   (q_fir)
    );

    // 4. Polyphase Decimator & FIR Filter - I Branch
    decimator_b #(
        .DATA_W     (MIX_W),
        .COEFF_W    (DECI_COEFF_W),
        .CAS_W      (FIR_OUT_W),
        .TAPS       (DECI_TAPS),
        .DEC_FACTOR (DEC_FACTOR)
    ) u_decimator_i (
        .i_clk            (clk),
        .i_rst_n          (rst_n),
        .i_data           (i_mix),
        .i_coeffs         (deci_coeffs),
        .o_decimated_data (o_i_data),
        .o_data_valid     (o_data_valid)
    );

    // 5. Polyphase Decimator & FIR Filter - Q Branch
    decimator_b #(
        .DATA_W     (MIX_W),
        .COEFF_W    (DECI_COEFF_W),
        .CAS_W      (FIR_OUT_W),
        .TAPS       (DECI_TAPS),
        .DEC_FACTOR (DEC_FACTOR)
    ) u_decimator_q (
        .i_clk            (clk),
        .i_rst_n          (rst_n),
        .i_data           (q_mix),
        .i_coeffs         (deci_coeffs),
        .o_decimated_data (o_q_data),
        .o_data_valid     ( ) 
    );

endmodule
