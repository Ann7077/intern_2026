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
    output reg [15:0]    o_y,
    output reg           o_cout
    );

    // --- stage registers ---
    reg [15:0] prod;                
    reg [7:0] c;


    // ----- stage 1
    always @(negedge i_rst_n or posedge i_clk) begin
        if (!i_rst_n) begin
            prod   <= 16'b0;
            c      <= 8'b0;
        end else begin
            prod <= i_a * i_b;  
            c    <= i_c;
        end
    end
    
    // ----- stage 2
    wire [16:0] sum = {1'b0, prod} + {9'b0, c};
    
    always @(negedge i_rst_n or posedge i_clk) begin
        if (!i_rst_n) begin
            o_y        <= 16'b0;
            o_cout     <= 1'b0;
        end else begin
            o_y        <= sum[15:0];
            o_cout     <= sum[16];
        end
    end

endmodule