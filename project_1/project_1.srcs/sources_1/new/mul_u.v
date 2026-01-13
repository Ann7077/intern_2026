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
    input [7:0] i_a, 
        // 8 bit, can use other bit, but 8 is the simplest
    input [5:0] i_b, 
        // 6 bit, largest coefficient is 52, unsigned int at 5 bit can only express up to 31, 
        // unsigned 6 bit can express up to 63, which covers 52
    output [13:0] o_p
        // product width = 8 bit + 6 bit = 14 bit
    );
    
    assign o_p = i_a * i_b;
    
endmodule
