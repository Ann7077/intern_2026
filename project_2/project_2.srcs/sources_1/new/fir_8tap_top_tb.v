`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2026 01:46:27 PM
// Design Name: 
// Module Name: fir_8tap_top_tb
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


module data_ram (
    input             i_clk,
    input             i_rst_n, // 建议增加异步复位 
    output reg [7:0]  o_data
);
    reg [7:0] mem [0:255];
    reg [7:0] addr_cnt; // 内部地址计数器

    // 地址累加逻辑
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            addr_cnt <= 8'd0;
        else
            addr_cnt <= addr_cnt + 1'b1; // 自动循环：0->1->...->255->0
    end

    // 时钟触发读取
    always @(posedge i_clk) begin
        o_data <= mem[addr_cnt];
    end

    // 初始化保持不变 
    initial begin
        $readmemh("test_data.hex", mem); 
    end
endmodule