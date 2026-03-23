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
    input                i_clk,
    input                i_rst_n,
    input  signed [7:0]  i_data,    // X0 (Signed to match mac_u)
    output signed [7:0]  o_data     // Final Output (Signed)
);

    // --- Coefficients (Unsigned) ---
    wire [7:0] h0 = 8'd2;
    wire [7:0] h1 = 8'd3;
    wire [7:0] h2 = 8'd4;
    wire [7:0] h3 = 8'd3;
    wire [7:0] h4 = 8'd2;

    // --- Layer 0: Input Delay Line ---
    // Top row of 'D' blocks from the diagram
    reg signed [7:0] x0, x1, x2, x3, x4;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            {x0, x1, x2, x3, x4} <= 40'd0;
        end else begin
            x0 <= i_data;   
            x1 <= x0;       // X0 -> X1
            x2 <= x1;       // X1 -> X2
            x3 <= x2;       // X2 -> X3   
            x4 <= x3;       // X03 -> X4
        end
    end

    // --- Layer 1 & 2: Multiplication and m0-m4 Registers ---
    // Instances for each tap as shown in Layer 1/2 of the drawing
    wire signed [7:0] m0, m1, m2, m3, m4;

    mac_u u_mac0 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (x0), 
        .i_b     (h0),
        .i_c     (8'd0), // No accumulation yet
        .o_y     (m0),
        .o_cout  ()
    );

    mac_u u_mac1 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (x1),
        .i_b     (h1),
        .i_c     (8'd0),
        .o_y     (m1),
        .o_cout  ()
    );

    mac_u u_mac2 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (x2),
        .i_b     (h2),
        .i_c     (8'd0),
        .o_y     (m2),
        .o_cout  ()
    );

    mac_u u_mac3 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (x3),
        .i_b     (h3),
        .i_c     (8'd0),
        .o_y     (m3),
        .o_cout  ()
    );

    mac_u u_mac4 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (x4),
        .i_b     (h4),
        .i_c     (8'd0),
        .o_y     (m4),
        .o_cout  ()
    );

    // --- Layer 3: Addition Tree Stage 1 (sum00, sum01) ---
    // Using mac_u as an adder: i_a*i_b is set to 0
    // First Stage Sums: sum00 = m0 + m1, sum01 = m2 + m3
    wire signed [7:0] sum00, sum01;

    mac_u u_add_sum00 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (m0 + m1), // Adds m0 and m1
        .o_y     (sum00),
        .o_cout  ()
    );

    mac_u u_add_sum01 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (m2 + m3),
        .o_y     (sum01),
        .o_cout  ()
    );

    // --- Final Layer: Accumulation (final0, final1) ---
    // Final Stage Sums: final1 = final0 + m4
    wire signed [7:0] final0, final1;

    mac_u u_add_final0 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (sum00 + sum01),
        .o_y     (final0),
        .o_cout  ()
    );

    mac_u u_add_final1 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (final0 + m4),
        .o_y     (final1),
        .o_cout  ()
    );

    // --- Final Output Delay ---
    // Last 'D' block before the filter output
    reg signed [7:0] out_reg;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            out_reg <= 8'd0;
        end else begin
            out_reg <= final1;
        end
    end

    assign o_data = out_reg;

endmodule