`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2026 08:02:10 PM
// Design Name: 
// Module Name: fir_4tap_top
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
//   coefficient: {2, 3, 4, 3, 2}
//////////////////////////////////////////////////////////////////////////////////


module fir_4tap_top (
    input                     i_clk,
    input                     i_rst_n,
    input  signed      [7:0]  i_data,    // Q8.7 
    output reg signed  [7:0]  o_data     // Q8.7 
);

    // Coefficients: {2, 3, 4, 3, 2} 
    wire [7:0] h0 = 8'd2;
    wire [7:0] h1 = 8'd3;
    wire [7:0] h2 = 8'd4;
    wire [7:0] h3 = 8'd3;
    wire [7:0] h4 = 8'd2;

    // --- Horizontal Data Delay Line (X0 to X4) ---
    // Matches the top horizontal row of "D" boxes in diagram 
    reg signed [7:0] x0, x1, x2, x3, x4;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            x0 <= 8'd0; 
            x1 <= 8'd0; 
            x2 <= 8'd0; 
            x3 <= 8'd0; 
            x4 <= 8'd0;
        end else begin
            x0 <= i_data;
            x1 <= x0;
            x2 <= x1;
            x3 <= x2;
            x4 <= x3;
        end
    end

    // --- Vertical Input Delays (Matching diagram's "D" boxes for X inputs) ---
    reg signed [7:0] x1_d1;
    reg signed [7:0] x2_d1, x2_d2;
    reg signed [7:0] x3_d1, x3_d2, x3_d3;
    reg signed [7:0] x4_d1, x4_d2, x4_d3, x4_d4;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            x1_d1 <= 8'd0;
            {x2_d1, x2_d2} <= 16'd0;
            {x3_d1, x3_d2, x3_d3} <= 24'd0;
            {x4_d1, x4_d2, x4_d3, x4_d4} <= 32'd0;
        end else begin
            x1_d1 <= x1;
            x2_d1 <= x2; x2_d2 <= x2_d1;
            x3_d1 <= x3; x3_d2 <= x3_d1; x3_d3 <= x3_d2;
            x4_d1 <= x4; x4_d2 <= x4_d1; x4_d3 <= x4_d2; x4_d4 <= x4_d3;
        end
    end

    // --- Intermediate Precisions (m0-m4) ---
    wire signed [14:0] m0;   // Q15.14 
    wire signed [15:0] m1;   // Q16.14 
    wire signed [16:0] m2;   // Q17.14 
    wire signed [17:0] m3;   // Q18.14 
    wire signed [18:0] m4;   // Q19.14 

    // --- MAC Chain with Summation Delays (The intermediate "D" for m results) ---
    reg signed [14:0] m0_reg;
    reg signed [15:0] m1_reg;
    reg signed [16:0] m2_reg;
    reg signed [17:0] m3_reg;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            m0_reg <= 15'd0; 
            m1_reg <= 16'd0; 
            m2_reg <= 17'd0; 
            m3_reg <= 18'd0;
        end else begin
            m0_reg <= m0; 
            m1_reg <= m1; 
            m2_reg <= m2; 
            m3_reg <= m3;
        end
    end

    // MAC Instances (Assuming parameterized mac_u for different bit-widths)
    mac_u_p15 dut_m0 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n),
        .i_a(x0), 
        .i_b(h0), 
        .i_c(15'd0), 
        .o_y(m0)
    );

    mac_u_p16 dut_m1 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n),
        .i_a(x1_d1), 
        .i_b(h1), 
        .i_c(m0_reg), 
        .o_y(m1)
    );

    mac_u_p17 dut_m2 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n),
        .i_a(x2_d2), 
        .i_b(h2), 
        .i_c(m1_reg), 
        .o_y(m2)
    );

    mac_u_p18 dut_m3 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n),
        .i_a(x3_d3), 
        .i_b(h3), 
        .i_c(m2_reg), 
        .o_y(m3)
    );

    mac_u_p19 dut_m4 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n),
        .i_a(x4_d4), 
        .i_b(h4), 
        .i_c(m3_reg), 
        .o_y(m4)
    );

    // --- Final Saturation and Truncation to Q8.7 ---
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_data <= 8'd0; 
        end else begin
            if (m4[18:14] != 5'b00000 && m4[18:14] != 5'b11111) begin
                o_data <= m4[18] ? 8'b10000000 : 8'b01111111; 
            end else begin
                o_data <= m4[14:7]; 
            end
        end
    end

endmodule