`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/11/2026 06:00:35 PM
// Design Name: 
// Module Name: mul_u
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


module mul_u(
    input i_clk,       // clock
    input i_rst_n,     // asynchronous reset, activate on low
    input [7:0] i_a, 
        // 8 bit, can use other bit, but 8 is the simplest
    input [5:0] i_b, 
        // 6 bit, largest coefficient is 52, unsigned int at 5 bit can only express up to 31, 
        // unsigned 6 bit can express up to 63, which covers 52
    output reg [13:0] o_p
        // product width = 8 bit + 6 bit = 14 bit
        // reg is used because value is assigned in always
    );
    
    always @(negedge i_rst_n or posedge i_clk) begin    
        if (i_rst_n == 0)
            o_p <= 14'b0;       // reset
        else 
            o_p <= i_a * i_b;    // normal operation
    end
    
endmodule
