`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/23/2026 08:24:12 PM
// Design Name: 
// Module Name: mac_u
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


module mac_u(
    input i_clk,
    input i_rst_n,
    input [13:0] i_a,
    input [13:0] i_b,
    input [13:0] i_c,
    output reg [27:0] o_y,
    output reg o_cout
    );
    
    reg [27:0] p;    // p = a * b, 14 bits * 14 bits = 28 bits
    reg [28:0] w_full_solution;   // one extra bit for carry bit
    
    always @(negedge i_rst_n or posedge i_clk) begin    
        if (i_rst_n == 0) begin
            o_y <= 28'b0;
            o_cout <= 1'b0;
            p <= 28'd0;
            w_full_solution <= 29'd0;
        end else begin
            p <= i_a * i_b;
            w_full_solution = {1'b0,p} + {15'b0,i_c};
            o_y <= w_full_solution[27:0];
            o_cout <= w_full_solution[28];
        end
    end
    
    
endmodule
