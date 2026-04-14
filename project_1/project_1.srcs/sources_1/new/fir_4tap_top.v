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
    input  signed      [7:0]  i_data,   // Q8.7
    output reg signed  [7:0]  o_data    // Q8.7 (Final Truncated/Saturated)
);

    // Coefficients (Unsigned as requested: 2, 3, 4, 3, 2)
    // Even though coefficients are unsigned, we treat them as Q8.7 
    // to maintain consistent fractional alignment.
    wire [7:0] h0 = 8'd2;
    wire [7:0] h1 = 8'd3;
    wire [7:0] h2 = 8'd4;
    wire [7:0] h3 = 8'd3;
    wire [7:0] h4 = 8'd2;

    // Delay Line for Input Data (X0 to X4)
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

    // Intermediate Solution Wires (Full Precision based on your table)
    wire signed [14:0] m0; // Q15.14
    wire signed [15:0] m1; // Q16.14
    wire signed [16:0] m2; // Q17.14
    wire signed [17:0] m3; // Q18.14
    wire signed [18:0] m4; // Q19.14

    // --- MAC Chain Implementation ---
    // Note: To match your full-precision table, these instances assume 
    // a version of mac_u that supports the specific widths m0-m4.
    
    // Step 1: m0 = x0 * h0 + 0
    mac_u_p15 dut_m0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x0),
        .i_b(h0),
        .i_c(8'd0), 
        .o_y(m0)
    );

    // Step 2: m1 = x1 * h1 + m0
    mac_u_p16 dut_m1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x1),
        .i_b(h1),
        .i_c(m0),
        .o_y(m1)
    );

    // Step 3: m2 = x2 * h2 + m1
    mac_u_p17 dut_m2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x2),
        .i_b(h2),
        .i_c(m1),
        .o_y(m2)
    );

    // Step 4: m3 = x3 * h3 + m2
    mac_u_p18 dut_m3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x3),
        .i_b(h3),
        .i_c(m2),
        .o_y(m3)
    );

    // Step 5: m4 = x4 * h4 + m3
    mac_u_p19 dut_m4 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(x4),
        .i_b(h4),
        .i_c(m3),
        .o_y(m4)
    );

    // --- Final Output Processing ---
    // Convert Q19.14 back to Q8.7 (Truncation and Saturation)
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_data <= 8'd0;
        end else begin
            // Check bits [18:14] for overflow relative to 8-bit signed range
            if (m4[18:14] > 5'b00000 && m4[18] == 1'b0) begin
                o_data <= 8'b01111111; // Positive Saturation
            end else if (m4[18:14] < 5'b11111 && m4[18] == 1'b1) begin
                o_data <= 8'b10000000; // Negative Saturation
            end else begin
                o_data <= m4[14:7];    // Slice the Q8.7 portion
            end
        end
    end

endmodule