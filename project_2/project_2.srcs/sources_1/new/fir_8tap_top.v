`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2026 09:15:00 PM
// Design Name: 
// Module Name: fir_8tap_top
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
//   coefficient: {7, 17, 32, 46, 52, 46, 32, 17, 7}
//////////////////////////////////////////////////////////////////////////////////


module fir_8tap_top (
    input i_clk,
    input i_rst_n,
    input signed [7:0] i_data,
    output reg signed [7:0] o_data,

    output signed [7:0] m0_out, m1_out, m2_out, m3_out, m4_out,
    output signed [7:0] m5_out, m6_out, m7_out, m8_out
);

    // --------------------------------------------------
    // Coefficients (Q8.7)
    // --------------------------------------------------
    wire signed [7:0] h0 = 8'd7;
    wire signed [7:0] h1 = 8'd17;
    wire signed [7:0] h2 = 8'd32;
    wire signed [7:0] h3 = 8'd46;
    wire signed [7:0] h4 = 8'd52;
    wire signed [7:0] h5 = 8'd46;
    wire signed [7:0] h6 = 8'd32;
    wire signed [7:0] h7 = 8'd17;
    wire signed [7:0] h8 = 8'd7;

    // --------------------------------------------------
    // Delay line
    // --------------------------------------------------
    reg signed [7:0] x0, x1, x2, x3, x4, x5, x6, x7;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0;
            x4 <= 0; x5 <= 0; x6 <= 0; x7 <= 0;
        end else begin
            x0 <= i_data;
            x1 <= x0;
            x2 <= x1;
            x3 <= x2;
            x4 <= x3;
            x5 <= x4;
            x6 <= x5;
            x7 <= x6;
        end
    end

    // --------------------------------------------------
    // MAC outputs
    // --------------------------------------------------
    wire signed [7:0] m0, m1, m2, m3, m4, m5, m6, m7, m8;

    assign m0_out = m0;
    assign m1_out = m1;
    assign m2_out = m2;
    assign m3_out = m3;
    assign m4_out = m4;
    assign m5_out = m5;
    assign m6_out = m6;
    assign m7_out = m7;
    assign m8_out = m8;

    // --------------------------------------------------
    // CORRECT MAC CHAIN (matches Python)
    // --------------------------------------------------

    // M8 (first stage - DIRECT INPUT)
    mac_u dut_m8 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(i_data),   //  critical fix
        .i_b(h8),
        .i_c(8'sd0),
        .o_y(m8)
    );

    mac_u dut_m7 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x0),
        .i_b(h7),
        .i_c(m8),
        .o_y(m7)
    );

    mac_u dut_m6 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x1),
        .i_b(h6),
        .i_c(m7),
        .o_y(m6)
    );

    mac_u dut_m5 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x2),
        .i_b(h5),
        .i_c(m6),
        .o_y(m5)
    );

    mac_u dut_m4 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x3),
        .i_b(h4),
        .i_c(m5),
        .o_y(m4)
    );

    mac_u dut_m3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x4),
        .i_b(h3),
        .i_c(m4),
        .o_y(m3)
    );

    mac_u dut_m2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x5),
        .i_b(h2),
        .i_c(m3),
        .o_y(m2)
    );

    mac_u dut_m1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x6),
        .i_b(h1),
        .i_c(m2),
        .o_y(m1)
    );

    mac_u dut_m0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x7),
        .i_b(h0),
        .i_c(m1),
        .o_y(m0)
    );

    // --------------------------------------------------
    // Final output (NO saturation - matches Python)
    // --------------------------------------------------
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            o_data <= 0;
        else
            o_data <= m0;   // final result
    end

endmodule

