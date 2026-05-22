`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2026 03:38:38 AM
// Design Name: 
// Module Name: tb_dds
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

// data 0 to 15 is cos, 16 to 31 is sin

module tb_dds;

// 时钟信号（testbench里自己产生）
reg clk;

// DDS输出的数据线（32位）
// 很多DDS默认：
// [31:16] = cosine
// [15:0]  = sine
wire [31:0] data;
wire [31:0] m_axis_phase_tdata ;
// 数据有效信号
// =1 表示DDS当前输出有效
wire valid;


// 实例化DDS IP核
// uut = unit under test（被测试模块）
//dds_compiler_0 uut (

//    // 给DDS输入时钟
//    .aclk(clk),

//    // DDS输出有效标志
//    .m_axis_data_tvalid(valid),

//    // DDS输出数据
//    .m_axis_data_tdata(data)
//);
dds_compiler_0 your_instance_name (
  .aclk(clk),                                  // input wire aclk
  .s_axis_config_tvalid(1'b1),  // input wire s_axis_config_tvalid
  .s_axis_config_tdata(32'd4000),    // input wire [31 : 0] s_axis_config_tdata
  .m_axis_data_tvalid(m_axis_data_tvalid),      // output wire m_axis_data_tvalid
  .m_axis_data_tdata(data),        // output wire [15 : 0] m_axis_data_tdata
  .m_axis_phase_tvalid(m_axis_phase_tvalid),    // output wire m_axis_phase_tvalid
  .m_axis_phase_tdata(m_axis_phase_tdata)      // output wire [31 : 0] m_axis_phase_tdata
);

// initial：仿真开始时执行一次
initial begin

    // 初始时钟为0
    clk = 0;

    // forever = 无限循环
    // 每5ns翻转一次时钟
    // 所以一个完整周期 = 10ns
    // 时钟频率 = 100MHz
    forever #5 clk = ~clk;

end


// 第二个initial block
// 用来控制仿真运行时间
initial begin

    // 仿真运行5000000ns
    #5000000;

    // 结束仿真
    $finish;

end

endmodule

