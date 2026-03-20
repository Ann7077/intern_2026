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
    input                     i_clk,
    input                     i_rst_n,
    input signed      [7:0]   i_a,   
    input signed      [7:0]   i_b,   
    input signed      [7:0]   i_c, 
    output reg signed [7:0]   o_y,
    output reg signed         o_cout
);

// stage 1: full precision multiply
reg signed [15:0] mult;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        mult <= 16'd0;
    else
        mult <= i_a * i_b;
end

// stage 2: scale ONCE, then accumulate
reg signed [8:0] sum;  

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_y    <= 8'd0;
        o_cout <= 1'b0;
    end else begin
        // scale multiplication result ONCE
        sum <= (mult >>> 7) + i_c;

        if (sum[8] != sum[7]) begin
            o_y <= sum[8] ? 8'b10000000 : 8'b01111111;   // saturated
        end else begin
            o_y <= sum[7:0];   // no overflow, normal truncation
        end
        o_cout <= (sum[8] != sum[7]);   // indicate truncation occured
    end
end

endmodule
