`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2026 03:24:29 PM
// Design Name: 
// Module Name: fir_filter
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


module fir_filter #(
    parameter DATA_W  = 12,  // 12
    parameter COEFF_W = 12,  // 12
    parameter CAS_W   = 32,  // 32
    parameter TAPS = 32      // 32
)(
    input i_clk,
    input i_rst_n,
    input signed [DATA_W-1:0] i_data,
    input signed [COEFF_W-1:0] i_coeffs [0:TAPS-1], // Clean 2D array port
    output reg signed [CAS_W-1:0] o_data
);

 
    // 32-Tap Coefficients 
    
    
    // Delay line for 32-tap (x0 to x30, x31 is direct input)
    reg signed [DATA_W-1:0] x [0:TAPS-2];
    integer k;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (k = 0; k < TAPS-1; k = k + 1) begin
                x[k] <= 0;
            end
        end 
        else begin
            x[0] <= i_data;
            for (k = 1; k < TAPS-1; k = k + 1) begin
                x[k] <= x[k-1];
            end
        end
    end


    // MAC Chain (From Tap 31 down to Tap 0)
    wire signed [CAS_W-1:0] m [0:TAPS-1];
    genvar i;
    
    generate
        for (i = 0; i < TAPS; i = i + 1) begin : mac_loop
            // Extract the specific coefficient from the flattened input vector
            wire signed [COEFF_W-1:0] current_coeff = i_coeffs[i];
            
            // Determine the data input for this specific tap
            wire signed [DATA_W-1:0] current_data = (i == 0) ? i_data : x[i-1];

            if (i == TAPS-1) begin : last_tap
                // First stage in the cascade chain (Tap 31 in original code)
                mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_mac (
                    .i_clk(i_clk), 
                    .i_rst_n(i_rst_n),
                    .i_data(current_data), 
                    .i_coeff(current_coeff), 
                    .i_cascade_in({CAS_W{1'b0}}), 
                    .o_cascade_out(m[i])
                );
            end 
            else begin : mid_taps
                // Middle stages and final stage (Tap 30 down to Tap 0)
                mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_mac (
                    .i_clk(i_clk), 
                    .i_rst_n(i_rst_n),
                    .i_data(current_data), 
                    .i_coeff(current_coeff), 
                    .i_cascade_in(m[i+1]), 
                    .o_cascade_out(m[i])
                );
            end
        end
    endgenerate

    // Final output registration
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            o_data <= {CAS_W{1'b0}};
        else
            o_data <= m[0]; // Final accumulated results
    end

endmodule