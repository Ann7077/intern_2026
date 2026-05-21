`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2026 09:36:04 PM
// Design Name: 
// Module Name: top_wrapper
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


module top_wrapper(
    input        SYSCLK_P,    // ZC702 板载差分时钟正极 (管脚 Y9)
    input        SYSCLK_N,    // ZC702 板载差分时钟负极 (管脚 W9)
    input        rst_n,       // 复位信号 (可以接到板子的 SW 按钮上)
    output [7:0] filter_out   // 滤波后的输出
);

    wire clk;
    reg [7:0] addr_cnt;       // 8位计数器，对应 RAM 的 256 个深度
    wire [7:0] raw_data;      // RAM 吐出来的原始数据

    // 1. 差分时钟转单端 (ZC702 硬件要求)
    IBUFDS #(
        .DIFF_TERM("FALSE"), 
        .IBUF_LOW_PWR("TRUE"), 
        .IOSTANDARD("DEFAULT")
    ) ibufds_inst (
        .O(clk),  
        .I(SYSCLK_P),  
        .IB(SYSCLK_N) 
    );

    // 2. 地址计数器：每个时钟周期加 1，循环读取 RAM 数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_cnt <= 8'd0;
        end else begin
            addr_cnt <= addr_cnt + 1'b1;
        end
    end

    // 3. 实例化你刚才写的 RAM (数据源)
    data_ram your_ram_inst (
        .i_clk(clk),
        .i_addr(addr_cnt),
        .o_data(raw_data)     // 输出的数据给 raw_data
    );

    // 4. 实例化你的 8 阶 FIR 滤波器 (核心逻辑)
    fir_8tap_top your_filter_inst (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_data(raw_data),    // 把 RAM 的数据喂给滤波器
        .o_data(filter_out)   // 滤波结果输出给顶层端口
    );

endmodule