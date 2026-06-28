`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 05:25:28 AM
// Design Name: 
// Module Name: tb_fft_top
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


module tb_fft_top;

    // 1. 定义信号 (根据你 xfft_0 的配置，位宽可能需要微调)
    reg aclk;
    reg aresetn;
    
    // 配置接口 (Config)
    reg [15:0] s_axis_config_tdata;
    reg        s_axis_config_tvalid;
    wire       s_axis_config_tready;
    
    // 输入数据接口 (Data Input)
    reg  [31:0] s_axis_data_tdata;   // 高16位虚部，低16位实部
    reg         s_axis_data_tvalid;
    wire        s_axis_data_tready;
    reg         s_axis_data_tlast;   // 一帧数据的最后一个点拉高
    
    // 输出数据接口 (Data Output)
    wire [47:0] m_axis_data_tdata;   // 输出位宽通常比输入宽，以保留精度
    wire [15:0] m_axis_data_tuser;   // 包含 XK_INDEX (频点索引) 等信息
    wire        m_axis_data_tvalid;
    reg         m_axis_data_tready;  // TB中通常直接拉高，表示时刻准备接收
    wire        m_axis_data_tlast;

    // 2. 实例化你的 FFT IP 核 (xfft_0)
    // 强烈建议：在 Vivado 左侧 Sources -> IP -> xfft_0 -> 右键 -> Show Instantiation Template
    // 把自动生成的端口直接复制过来替换下面的内容，保证端口名 100% 匹配
    xfft_0 your_instance_name (
      .aclk(aclk),                                                        // input wire aclk
      .aresetn(aresetn),                                                  // input wire aresetn
      
      .s_axis_config_tdata(s_axis_config_tdata),                          // input wire [15:0] s_axis_config_tdata
      .s_axis_config_tvalid(s_axis_config_tvalid),                        // input wire s_axis_config_tvalid
      .s_axis_config_tready(s_axis_config_tready),                        // output wire s_axis_config_tready
      
      .s_axis_data_tdata(s_axis_data_tdata),                              // input wire [31:0] s_axis_data_tdata
      .s_axis_data_tvalid(s_axis_data_tvalid),                            // input wire s_axis_data_tvalid
      .s_axis_data_tready(s_axis_data_tready),                            // output wire s_axis_data_tready
      .s_axis_data_tlast(s_axis_data_tlast),                              // input wire s_axis_data_tlast
      
      .m_axis_data_tdata(m_axis_data_tdata),                              // output wire [47:0] m_axis_data_tdata
      .m_axis_data_tvalid(m_axis_data_tvalid),                            // output wire m_axis_data_tvalid
      .m_axis_data_tready(m_axis_data_tready),                            // input wire m_axis_data_tready
      .m_axis_data_tlast(m_axis_data_tlast),                              // output wire m_axis_data_tlast
      
      .event_frame_started(),                                             // output wire event_frame_started
      .event_tlast_unexpected(),                                          // output wire event_tlast_unexpected
      .event_tlast_missing(),                                             // output wire event_tlast_missing
      .event_status_channel_halt(),                                       // output wire event_status_channel_halt
      .event_data_in_channel_halt(),                                      // output wire event_data_in_channel_halt
      .event_data_out_channel_halt()                                      // output wire event_data_out_channel_halt
    );

    // 3. 生成 100MHz 时钟
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // 10ns 周期
    end

    // 4. 仿真激励逻辑
    initial begin
        // --- 初始化信号 ---
        aresetn = 0;
        s_axis_config_tdata = 16'h0001; // 0x0001 表示正向 FFT，0x0000 表示 IFFT
        s_axis_config_tvalid = 0;
        s_axis_data_tdata = 0;
        s_axis_data_tvalid = 0;
        s_axis_data_tlast = 0;
        m_axis_data_tready = 1;         // TB 时刻准备接收输出数据
        
        // --- 复位 ---
        #20;
        aresetn = 1; // 释放复位
        
        // --- 发送配置 ---
        // 必须等复位释放后，再拉高 config_tvalid
        @(posedge aclk);
        s_axis_config_tvalid = 1;
        
        // 等 IP 核准备好接收配置 (握手成功)
        wait(s_axis_config_tready);
        @(posedge aclk);
        s_axis_config_tvalid = 0; // 配置发送完毕，拉低
        
        // --- 发送 64 个模拟输入数据 (你可以替换成从文件读取或连接你的 DDS) ---
        // 这里模拟一个简单的正弦波实部，虚部补 0
        @(posedge aclk);
        
        // 注意：一定要等配置接口握手完成后，再开始发数据
        for (integer i = 0; i < 64; i = i + 1) begin
            @(posedge aclk);
            // 必须等待 IP 核的 tready 拉高，才能发下一个数据（标准 AXI-Stream 握手）
            wait(s_axis_data_tready);
            
            s_axis_data_tvalid <= 1;
            // 模拟数据：实部(i*100)，虚部(0)。{高16位虚部, 低16位实部}
            s_axis_data_tdata <= {16'd0, i * 100}; 
            
            // 最后一个数据拉高 tlast
            if (i == 63) 
                s_axis_data_tlast <= 1;
            else 
                s_axis_data_tlast <= 0;
        end
        
        // --- 发送完毕，拉低信号 ---
        @(posedge aclk);
        s_axis_data_tvalid <= 0;
        s_axis_data_tlast <= 0;

        // --- 等待输出处理完成 (FFT 运算有延迟，多等一会) ---
        #2000; 
        
        $display("Simulation Finished.");
        $finish;
    end

endmodule
