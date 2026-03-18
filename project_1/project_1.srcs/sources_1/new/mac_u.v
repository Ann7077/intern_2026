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
    input               i_clk,
    input               i_rst_n,   // async active-low reset
    input      [7:0]    i_a,
    input      [7:0]    i_b,
    input      [7:0]    i_c,
    output reg [7:0]    o_y,    // i_a * i_b + i_c
    output reg          o_cout 
    );

    // --- stage registers ---
    reg [7:0] prod;                
    reg [7:0] c;

    // ----- stage 1
    wire [15:0] mult;
    assign mult = i_a * i_b;
    
    always @(negedge i_rst_n or posedge i_clk) begin
        if (!i_rst_n) begin
            prod <= 8'b0;
            c    <= 8'b0;
        end else begin
            prod <= mult[15:8]; 
            c    <= i_c;
        end
    end
    
    // ----- stage 2  
    wire [8:0] sum;
    assign sum = {1'b0, prod[7:0]} + {1'b0, c};
    
    always @(negedge i_rst_n or posedge i_clk) begin
        if (!i_rst_n) begin
            o_y        <= 8'b0;
            o_cout     <= 1'b0;
        end else begin
            o_y        <= sum[7:0];
            o_cout     <= sum[8];
        end
    end

    
endmodule

// no reset (no negedge)
// cout is unnecessary, no overflow exists
// mac_u is fine, mac_u_tb is not correct (use excel to do calculation)