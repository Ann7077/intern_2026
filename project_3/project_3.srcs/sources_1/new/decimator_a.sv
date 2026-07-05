`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2026 04:08:16 PM
// Design Name: 
// Module Name: decimator_a
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


module decimator_a # (
    parameter DATA_W     = 12,  
    parameter COEFF_W    = 12,  
    parameter CAS_W      = 32,  
    parameter TAPS       = 7,  
    parameter DEC_FACTOR = 3   
)(
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire signed [DATA_W-1:0]  i_data,
    input  wire signed [COEFF_W-1:0] i_coeffs [0:TAPS-1],
    
    output reg  signed [CAS_W-1:0]   o_decimated_data,
    output reg                       o_data_valid  
);

    // 1. Fast Clock Domain: Shift Register Chain
    reg signed [DATA_W-1:0] shift_reg [0:TAPS-1];
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (int i = 0; i < TAPS; i = i + 1) begin
                shift_reg[i] <= 0;
            end
        end else begin
            shift_reg[0] <= i_data;
            for (int i = 1; i < TAPS; i = i + 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    // 2. Downsampling & Processing (The 3:1 Switch Boundary)
    reg [3:0] sample_cnt;
    
    // Variables for the combinational MAC math
    reg signed [CAS_W-1:0] acc;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sample_cnt       <= 0;
            o_decimated_data <= 0;
            o_data_valid     <= 1'b0;
        end else begin
            if (sample_cnt == (DEC_FACTOR - 1)) begin
                sample_cnt   <= 0;
                o_data_valid <= 1'b1;
                
                // 3. Slow Domain Math: Loops execute ONLY once every DEC_FACTOR cycles
                acc = 0; 
                for (int j = 0; j < TAPS; j = j + 1) begin
                    acc = acc + (shift_reg[j] * i_coeffs[j]);
                end
                o_decimated_data <= acc;
                
            end else begin
                sample_cnt   <= sample_cnt + 1;
                o_data_valid <= 1'b0;
            end
        end
    end

endmodule