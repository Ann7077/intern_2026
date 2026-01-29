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
    input      [13:0]    i_a,
    input      [13:0]    i_b,
    input      [13:0]    i_c,
    output reg [27:0]    o_y,
    output reg           o_cout
    );

    // --- stage registers ---
    reg  [27:0] p;                 // 原来是 wire，现在改成乘法器结果寄存器
    reg  [28:0] w_full_solution;   // 原来是 wire，现在改成加法器结果寄存器

    // 乘法器 + 加法器都“封装成寄存器”后再往下处理
    always @(negedge i_rst_n or posedge i_clk) begin
        if (!i_rst_n) begin
            p               <= 28'b0;
            w_full_solution <= 29'b0;
            o_y             <= 28'b0;
            o_cout          <= 1'b0;
        end else begin
            // stage 1: MUL -> reg
            p <= i_a * i_b;   // 14b * 14b = 28b

            // stage 2: ADD -> reg (注意这里用的是“上一拍”的 p)
            w_full_solution <= {1'b0, p} + {15'b0, i_c};

            // stage 3: output -> reg (用的是“上一拍”的 w_full_solution)
            o_y    <= w_full_solution[27:0];
            o_cout <= w_full_solution[28];
        end
    end

endmodule
