`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2026 03:48:28 PM
// Design Name: 
// Module Name: mac_fir
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


module mac_fir #(

    parameter DATA_W = 12,  // 12
    parameter COEFF_W = 12,  // 12
    parameter CAS_IN_W = 32,  // 32
    parameter CAS_OUT_W = 32  // 32
    
)(
    input i_clk,
    input i_rst_n,
    
    input signed      [DATA_W-1:0]  i_data,           // 12-bit input data from the delay line
    input signed      [COEFF_W-1:0]  i_coeff,         // 12-bit filter coefficient
    
    input signed      [CAS_IN_W-1:0]  i_cascade_in,    // 24-bit accumulation input from the previous MAC stage
    output reg signed [CAS_OUT_W-1:0]  o_cascade_out    // 24-bit accumulation output passed to the next MAC stage
);

    // Stage 1: Full-Precision Multiplication
    reg signed [DATA_W+COEFF_W-1:0] r_mult_res;              // 12-bit * 12-bit = 24-bit signed product register
    reg signed [CAS_IN_W-1:0] r_cascade_in_d1;         // Delay version of i_cascade_in bu 1 cycle

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_mult_res      <= 24'sd0;
            r_cascade_in_d1 <= {CAS_IN_W{1'b0}};
        end else begin
            r_mult_res      <= $signed(i_data) * $signed(i_coeff); // Signed multiplication
            r_cascade_in_d1 <= i_cascade_in;     // Pipeline alignment delay
        end
    end

    // Stage 2: Cascade Accumulation Output
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_cascade_out <= {CAS_OUT_W{1'b0}};
        end else begin
            // Adds the current product to the synchronized cascade input from the previous stage
            o_cascade_out <= r_mult_res + r_cascade_in_d1; 
        end
    end

endmodule