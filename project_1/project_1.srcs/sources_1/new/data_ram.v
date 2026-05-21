`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2026 09:09:33 PM
// Design Name: 
// Module Name: data_ram
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
    input      [7:0]  i_addr,  // 8位地址，对应256个存储单元
    output reg [7:0]  o_data   // 输出给滤波器的输入端
);

    // 定义存储阵列：8位宽，256个深度
    reg [7:0] mem [0:255];

    // 初始化 RAM 内容 (这里是关键)
    // 在上板子前，我们需要把测试数据“塞”进去
    initial begin
        // 你可以手动赋值，或者使用 $readmemh 读取一个 hex 文件
        // 这里先随便填点数据作为示例：
        mem[0] = 8'd10;  mem[1] = 8'd20;  mem[2] = 8'd30;  mem[3] = 8'd40;
        mem[4] = 8'd50;  mem[5] = 8'd60;  mem[6] = 8'd70;  mem[7] = 8'd80;
        // ... 剩下的可以使用 $readmemh("test_data.hex", mem);
    end

    // 时序读取：给地址，出数据
    always @(posedge i_clk) begin
        o_data <= mem[i_addr];
    end

endmodule