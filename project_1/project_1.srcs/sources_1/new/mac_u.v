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


module mac_u (
    input              i_clk,
    input              i_rst_n,
    input      [7:0]   i_a,   // unsigned
    input      [7:0]   i_b,   // unsigned
    input      [7:0]   i_c,   // unsigned
    output reg [7:0]   o_y,
    output reg         o_cout
);

// stage 1: full precision multiply
reg [15:0] mult;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        mult <= 16'd0;
    else
        mult <= i_a * i_b;
end

// stage 2: scale ONCE, then accumulate
reg [8:0] sum;  // 9-bit to catch overflow

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_y    <= 8'd0;
        o_cout <= 1'b0;
    end else begin
        // scale multiplication result ONCE
        sum = (mult >> 8) + i_c;

        o_y    <= sum[7:0];
        o_cout <= sum[8];
    end
end

endmodule
// no reset (no negedge)
// cout is unnecessary, no overflow exists
// mac_u is fine, mac_u_tb is not correct (use excel to do calculation)