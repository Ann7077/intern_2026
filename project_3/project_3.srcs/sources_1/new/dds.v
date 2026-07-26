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
    parameter ACC_W  = 32,  // Phase accumulator bit-width (32 bits)
    parameter LUT_W  = 10,  // LUT address bit-width (1024 entries)
    parameter OUT_W  = 12   // Output waveform bit-width (12 bits signed)
)(
    input  wire                 clk,          // System clock (100 MHz)
    input  wire                 rst_n,        // Active-low asynchronous reset
    input  wire [ACC_W-1:0]     ftw,          // Frequency Tuning Word (p_s)
    input  wire [ACC_W-1:0]     phase_offset, // Initial Phase / Phase Offset (p_0)
    
    output reg  signed [OUT_W-1:0] dds_sin,   // 12-bit signed sine wave output
    output reg  signed [OUT_W-1:0] dds_cos    // 12-bit signed cosine wave output
);

    // 1. Phase Accumulator
    reg [ACC_W-1:0] phase_acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 32'd0;
        end else begin
            phase_acc <= phase_acc + ftw;
        end
    end

endmodule