`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2026 04:00:04 PM
// Design Name: 
// Module Name: mac_fir_tb
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


module mac_fir_tb;

    parameter DATA_W = 12;
    parameter COEFF_W = 12;
    parameter CAS_IN_W = 24;
    parameter CAS_OUT_W = 24;
    
    reg i_clk;
    reg i_rst_n;
    reg signed   [DATA_W-1:0]     i_data;
    reg signed   [COEFF_W-1:0]    i_coeff;
    
    reg signed   [CAS_IN_W-1:0]   i_cascade_in;
    wire signed  [CAS_OUT_W-1:0]  o_cascade_out;
   
    
endmodule
