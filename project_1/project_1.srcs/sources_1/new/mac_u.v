`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/23/2026 08:24:12 PM
// Design Name: 
// Module Name: mac_u
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


module mac_u(
    input             i_clk,
    input             i_rst_n,
    input      [13:0]  i_a,
    input      [13:0]  i_b,
    input      [13:0]  i_c,
    output reg [27:0]  o_y,
    output reg         o_cout
);

    // stage-1 regs (pipeline after multiply / align C)
    reg [27:0] p_r;     // registered product
    reg [13:0] c_r;     // registered C (aligned with p_r)

    // stage-2 comb (only adder in this stage)
    wire [28:0] sum_w = {1'b0, p_r} + {15'b0, c_r};

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            p_r    <= 28'd0;
            c_r    <= 14'd0;
            o_y    <= 28'd0;
            o_cout <= 1'b0;
        end else begin
            // -------- stage 1: multiply only --------
            p_r <= i_a * i_b;
            c_r <= i_c;

            // -------- stage 2: add only (uses previous p_r/c_r) --------
            o_y    <= sum_w[27:0];
            o_cout <= sum_w[28];
        end
    end

endmodule




