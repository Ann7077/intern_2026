`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/27/2026 06:46:43 PM
// Design Name: 
// Module Name: mixer
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


module mixer (

    input  wire clk,
    input  wire rst_n,

    input  wire signed [11:0] adc_data,   // single raw mixed signal from the ADC (12-bit signed)

    input  wire signed [11:0] dds_cos,    // cosine wave to extract the I-branch (12-bit signed) 
    input  wire signed [11:0] dds_sin,    // sine wave to extract the Q-branch (12-bit signed) 

    output reg  signed [23:0] i_out,      // separated In-Phase (I) baseband path data (24-bit signed)  
    output reg  signed [23:0] q_out       // separated Quadrature (Q) baseband path data (24-bit signed) 
);
  


endmodule
