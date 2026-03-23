`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2026 01:45:22 PM
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
//   Coefficients (8-tap symmetric): 7, 17, 32, 46, 52, 46, 32, 17, 7
//////////////////////////////////////////////////////////////////////////////////


module fir_8tap_top (
    input            i_clk,
    input            i_rst_n,
    input      [7:0] i_data,   // Unsigned input
    output     [7:0] o_data    // Unsigned output
);

    // --- Coefficients (Unsigned) ---
    // Using the first 8 coefficients provided in the assignment
    wire [7:0] c0 = 8'd7;
    wire [7:0] c1 = 8'd17;
    wire [7:0] c2 = 8'd32;
    wire [7:0] c3 = 8'd46;
    wire [7:0] c4 = 8'd52;
    wire [7:0] c5 = 8'd46;
    wire [7:0] c6 = 8'd32;
    wire [7:0] c7 = 8'd17;

    // --- Input Delay Line (Top row of 'D' in diagram) ---
    reg [7:0] x0, x1, x2, x3, x4, x5, x6, x7;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            {x0, x1, x2, x3, x4, x5, x6, x7} <= 64'd0;
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

    // --- Layer 1 & 2: Multiplication and First Delay ---
    // mac_u handles mult + add. For the first layer, we pass 0 as 'i_c'.
    // Port mapping: i_a (data), i_b (coeff), i_c (accumulation)
    wire [7:0] l2_m0, l2_m1, l2_m2, l2_m3, l2_m4, l2_m5, l2_m6, l2_m7;
    
    // Instance for Tap 0
    mac_u u_mac0 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x0}), // Zero-extend for unsigned
        .i_b     ({1'b0, c0}),
        .i_c     (8'd0),
        .o_y     (l2_m0),
        .o_cout  ()
    );

    // Instance for Tap 1
    mac_u u_mac1 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x1}),
        .i_b     ({1'b0, c1}),
        .i_c     (8'd0),
        .o_y     (l2_m1),
        .o_cout  ()
    );

    // Instance for Tap 2
    mac_u u_mac2 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x2}),
        .i_b     ({1'b0, c2}),
        .i_c     (8'd0),
        .o_y     (l2_m2),
        .o_cout  ()
    );

    // Instance for Tap 3
    mac_u u_mac3 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x3}),
        .i_b     ({1'b0, c3}),
        .i_c     (8'd0),
        .o_y     (l2_m3),
        .o_cout  ()
    );

    // Instance for Tap 4
    mac_u u_mac4 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x4}),
        .i_b     ({1'b0, c4}),
        .i_c     (8'd0),
        .o_y     (l2_m4),
        .o_cout  ()
    );

    // Instance for Tap 5
    mac_u u_mac5 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x5}),
        .i_b     ({1'b0, c5}),
        .i_c     (8'd0),
        .o_y     (l2_m5),
        .o_cout  ()
    );

    // Instance for Tap 6
    mac_u u_mac6 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x6}),
        .i_b     ({1'b0, c6}),
        .i_c     (8'd0),
        .o_y     (l2_m6),
        .o_cout  ()
    );

    // Instance for Tap 7
    mac_u u_mac7 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     ({1'b0, x7}),
        .i_b     ({1'b0, c7}),
        .i_c     (8'd0),
        .o_y     (l2_m7),
        .o_cout  ()
    );

    // --- Layer 3: First Stage of Addition Tree ---
    // Note: mac_u is used as an adder here by setting i_a*i_b to 0
    wire [7:0] l3_sum0, l3_sum1, l3_sum2, l3_sum3;

    mac_u u_add_l3_0 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (l2_m0 + l2_m1),
        .o_y     (l3_sum0),
        .o_cout  ()
    );

    mac_u u_add_l3_1 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (l2_m2 + l2_m3),
        .o_y     (l3_sum1),
        .o_cout  ()
    );

    mac_u u_add_l3_2 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (l2_m4 + l2_m5),
        .o_y     (l3_sum2),
        .o_cout  ()
    );

    mac_u u_add_l3_3 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (l2_m6 + l2_m7),
        .o_y     (l3_sum3),
        .o_cout  ()
    );

    // --- Layer 4: Second Stage of Addition Tree ---
    wire [7:0] l4_sum0, l4_sum1;

    mac_u u_add_l4_0 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (l3_sum0 + l3_sum1),
        .o_y     (l4_sum0),
        .o_cout  ()
    );

    mac_u u_add_l4_1 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (l3_sum2 + l3_sum3),
        .o_y     (l4_sum1),
        .o_cout  ()
    );

    // --- Layer 5: Final Addition Stage ---
    wire [7:0] l5_final;

    mac_u u_add_l5 (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_a     (8'd0),
        .i_b     (8'd0),
        .i_c     (l4_sum0 + l4_sum1),
        .o_y     (l5_final),
        .o_cout  ()
    );

    assign o_data = l5_final;

endmodule