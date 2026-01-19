`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/12/2026 08:18:49 PM
// Design Name: 
// Module Name: add_u
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


module add_u(
    input i_clk,       // clock
    input i_rst_n,     // asynchronous reset, activate on low
    input [13:0] i_a,
    input [13:0] i_b,
    output reg [13:0] o_sum,
    output reg o_cout
    );
    
    wire [14:0] w_full_sum;   // one extra bit for carry bit
    assign w_full_sum = {1'b0, i_a} + {1'b0, i_b};   // add zero to front of i_a and i_b
    
    always @(negedge i_rst_n or posedge i_clk) begin    
        if (i_rst_n == 0) begin
            o_sum <= 14'b0;
            o_cout <= 1'b0;
        end else begin
            o_sum <= w_full_sum[13:0];   // sum without carried bit
            o_cout <= w_full_sum[14];    // carried bit goes here
        end
    end
    
    
/*    
    assign w_full_sum = {0'b0, i_a} + {0'b0, i_b};   // add zero to front of i_a and i_b
        // this is so if there is a carried bit, it would be kept and not abandoned
    assign o_sum = w_full_sum[13:0];   // sum without carried bit
    assign o_cout = w_full_sum[14];    // carried bit goes here
*/

endmodule


/*
The "assign w_full_sum" line is 
*/