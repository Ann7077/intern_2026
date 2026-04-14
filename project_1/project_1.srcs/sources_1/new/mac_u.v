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
    input signed      [7:0]   i_a,      // Q8.7
    input signed      [7:0]   i_b,      // Q8.7
    input signed      [7:0]   i_c,      // Q8.7
    output reg signed [7:0]   o_y,     // Q8.7
    output reg signed         o_cout   // saturation flag
);

// stage 1: full precision multiply
reg signed [15:0] mult;   // only need Q15.14, but we are using Q16.4 here
reg signed [7:0]  i_c_d;  // delay version of i_c, Q8.7

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        mult  <= 16'd0; 
        i_c_d <= 8'd0;
    end else begin
        mult  <= i_a * i_b; 
        i_c_d <= i_c;
    end
end

// stage 2: scale ONCE, then accumulate
reg signed [8:0] sum;   // Q9.7

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_y    <= 8'd0;
        o_cout <= 1'b0;
    end else begin
        // scale multiplication result ONCE
        sum <= (mult >>> 8) + i_c_d; 

        if (sum[8] != sum[7]) begin
            o_y <= sum[8] ? 8'b10000000 : 8'b01111111;   // saturated for overflow (max neg : max pos)
        end else begin
            o_y <= sum[7:0];   // no overflow, normal truncation
        end
        o_cout <= (sum[8] != sum[7]);   // indicate truncation occured
    end
end

endmodule
