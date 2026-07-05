`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 08:22:17 PM
// Design Name: 
// Module Name: decimator
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


module decimator # (
    parameter DATA_W     = 12,  // 12
    parameter COEFF_W    = 12,  // 12
    parameter CAS_W      = 32,  // 32
    parameter TAPS       = 7,  // 32
    parameter DEC_FACTOR = 3   // 10
)(
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire signed [DATA_W-1:0]  i_data,
    input  wire signed [COEFF_W-1:0] i_coeffs [0:TAPS-1],
    
    output reg  signed [CAS_W-1:0]   o_decimated_data,
    output reg                       o_data_valid  // Pulsed high at 10MHz
);

    // Instantiate original cascaded structural FIR filter core
    wire signed [CAS_W-1:0] raw_fir_out;
    
    fir_filter #(DATA_W, COEFF_W, CAS_W, TAPS) fir_core (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_data(i_data),
        .i_coeffs(i_coeffs),
        .o_data(raw_fir_out)
    );

    // Downsampling / Decimation Counter
    reg [3:0] sample_cnt;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sample_cnt       <= 0;
            o_decimated_data <= 0;
            o_data_valid     <= 1'b0;
        end else begin
            if (sample_cnt == (DEC_FACTOR - 1)) begin
                sample_cnt       <= 0;
                o_decimated_data <= raw_fir_out; // Capture every 10th sample
                o_data_valid     <= 1'b1;        // Signal that 10MHz data is ready
            end else begin
                sample_cnt       <= sample_cnt + 1;
                o_data_valid     <= 1'b0;
            end
        end
    end
endmodule