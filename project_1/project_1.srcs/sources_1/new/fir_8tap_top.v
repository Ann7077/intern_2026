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
    input                     i_clk,
    input                     i_rst_n,
    input  signed      [7:0]  i_data,   // Q8.7
    output reg signed  [7:0]  o_data    // Q8.7 (Final Truncated/Saturated)
);
    // Coefficients (Unsigned as requested: 7, 17, 32, 46, 52, 46, 32, 17, 7) 
    // Even though coefficients are unsigned, we treat them as Q8.7 
    // to maintain consistent fractional alignment. 
    wire [7:0] h0 = 8'd7;
    wire [7:0] h1 = 8'd17;
    wire [7:0] h2 = 8'd32;
    wire [7:0] h3 = 8'd46;
    wire [7:0] h4 = 8'd52;
    wire [7:0] h5 = 8'd46;
    wire [7:0] h6 = 8'd32;
    wire [7:0] h7 = 8'd17;
    wire [7:0] h8 = 8'd7;

    // Delay Line for Input Data (X0 to X8) 
    reg signed [7:0] x0, x1, x2, x3, x4, x5, x6, x7, x8;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            x0 <= 8'd0; x1 <= 8'd0; x2 <= 8'd0; 
            x3 <= 8'd0; x4 <= 8'd0; x5 <= 8'd0; 
            x6 <= 8'd0; x7 <= 8'd0; x8 <= 8'd0; 
        end else begin
            x0 <= i_data; 
            x1 <= x0; 
            x2 <= x1; 
            x3 <= x2; 
            x4 <= x3; 
            x5 <= x4;
            x6 <= x5;
            x7 <= x6;
            x8 <= x7;
        end
    end

    // Intermediate Solution Wires (Truncated to 8-bit to match mac_u ports)
    
    
    // --- MAC Chain Implementation ---
    // Note: These instances use the existing mac_u module 
    wire signed [7:0] m0, m1, m2, m3, m4, m5, m6, m7, m8;
    
    // Step 1: m0 = x0 * h0 + 0
    mac_u dut_m0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x0),
        .i_b(h0),
        .i_c(8'd0), 
        .o_y(m0) 
    );

    // Step 2: m1 = x1 * h1 + m0
    mac_u dut_m1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x1),
        .i_b(h1),
        .i_c(m0),
        .o_y(m1) 
    );

    // Step 3: m2 = x2 * h2 + m1
    mac_u dut_m2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x2),
        .i_b(h2),
        .i_c(m1),
        .o_y(m2) 
    );

    // Step 4: m3 = x3 * h3 + m2
    mac_u dut_m3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x3),
        .i_b(h3),
        .i_c(m2),
        .o_y(m3) 
    );

    // Step 5: m4 = x4 * h4 + m3
    mac_u dut_m4 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x4),
        .i_b(h4),
        .i_c(m3),
        .o_y(m4) 
    );

    // Step 6: m5 = x5 * h5 + m4
    mac_u dut_m5 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x5),
        .i_b(h5),
        .i_c(m4),
        .o_y(m5)
    );

    // Step 7: m6 = x6 * h6 + m5
    mac_u dut_m6 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x6),
        .i_b(h6),
        .i_c(m5),
        .o_y(m6)
    );

    // Step 8: m7 = x7 * h7 + m6
    mac_u dut_m7 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x7),
        .i_b(h7),
        .i_c(m6),
        .o_y(m7)
    );

    // Step 9: m8 = x8 * h8 + m7
    mac_u dut_m8 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x8),
        .i_b(h8),
        .i_c(m7),
        .o_y(m8)
    );

    // --- Step 5: Final Output (Saturation & Truncation) ---
    // Note: Since mac_u is signed, the range is -128 to 127.
    // m8 is our 8-bit signed input from the last MAC stage.

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_data <= 8'd0;
        end else begin
            // Since m8 is already 8 bits from the MAC, 
            // 'Truncation' is inherent. We implement saturation 
            // logic here as a final boundary check.
            
            if (m8 > 8'sd127) begin
                o_data <= 8'sd127;          // Positive Saturation
            end else if (m8 < -8'sd128) begin
                o_data <= -8'sd128;         // Negative Saturation
            end else begin
                o_data <= m8;               // Normal Truncated Output
            end
        end
    end

endmodule