`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2026 07:53:29 PM
// Design Name: 
// Module Name: dds
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

module dds #(
    parameter PHASE_ACC_W  = 32,  // Phase accumulator bit-width (32 bits)
    parameter LUT_ADDR_W  = 10,   // LUT address bit-width (1024 entries)
    parameter LUT_OUT_W  = 12     // Output waveform bit-width (12 bits signed)
)(
    input  wire                 clk,          // System clock (100 MHz)
    input  wire                 rst_n,        // Active-low asynchronous reset
    input  wire [PHASE_ACC_W-1:0]     ftw,          // Frequency Tuning Word (p_s)
    input  wire [PHASE_ACC_W-1:0]     init_phase, // Initial Phase / Phase Offset (p_0)
    
    output reg  signed [LUT_OUT_W-1:0] dds_sin,   // 12-bit signed sine wave output
    output reg  signed [LUT_OUT_W-1:0] dds_cos    // 12-bit signed cosine wave output
);

    // 1. Phase Accumulator
    reg [PHASE_ACC_W-1:0] phase_acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= init_phase;
        end else begin
            phase_acc <= phase_acc + ftw;
        end
    end
    
    wire [PHASE_ACC_W-1:0] p_n = phase_acc;
     
                                                                                                                                                                            
    // 2. LUT Index Calculation
    
    // k_s = 2^(L-1) * (1 + p_n)
    // Adding 1 to a 2's complement fractional number in QN.(N-1) flips the MSB.
    wire [PHASE_ACC_W-1:0] p_sin_offset = {~p_n[PHASE_ACC_W-1], p_n[PHASE_ACC_W-2:0]};
        
    // k_c = 2^(L-1) * p_n + 2^(L-2) => p_n + 0.5 + 1
    wire [PHASE_ACC_W-1:0] p_cos_shifted = p_n + (1'b1 << (PHASE_ACC_W - 2)); // Add +0.5 (pi/2)
    wire [PHASE_ACC_W-1:0] p_cos_offset  = {~p_cos_shifted[PHASE_ACC_W-1], p_cos_shifted[PHASE_ACC_W-2:0]};

    // Extract upper L bits for LUT address integer part (k_i)
    wire [LUT_ADDR_W-1:0] k_s = p_sin_offset[PHASE_ACC_W-1 -: LUT_ADDR_W];
    wire [LUT_ADDR_W-1:0] k_c = p_cos_offset[PHASE_ACC_W-1 -: LUT_ADDR_W];
    
    
    // 3. Look-Up Table 
    reg signed [LUT_OUT_W-1:0] lut_rom [0:(1<<LUT_ADDR_W)-1];

    // Initialize LUT
    // index k maps to p = -1 + k / 2^(L-1), stored value = sin(pi * p) * (2^(M-1) - 1)
    integer unsigned k;
    real p_frac;
    real pi_val;
    initial begin
        pi_val =  3.1415926;
        for (k = 0; k < (1 << LUT_ADDR_W); k = k + 1) begin
            p_frac = -1.0 + (k / $itor(1 << (LUT_ADDR_W - 1))); // p in range [-1, 1)
            lut_rom[k] = $rtoi($sin(pi_val * p_frac) * (1 << (LUT_OUT_W - 1)));
        end
    end
    
    // 4. Register Output Signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dds_sin <= {LUT_OUT_W{1'b0}};
            dds_cos <= {LUT_OUT_W{1'b0}};
        end else begin
            dds_sin <= lut_rom[k_s];
            dds_cos <= lut_rom[k_c];
        end
    end
    
endmodule