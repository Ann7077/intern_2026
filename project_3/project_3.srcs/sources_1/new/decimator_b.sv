`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2026 04:53:59 PM
// Design Name: 
// Module Name: decimator_b
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


module decimator_b # (
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

    // 1. Fast Domain: Delay line to feed the phase switches
    reg signed [DATA_W-1:0] fast_reg [0:DEC_FACTOR-1];

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (int i = 0; i < DEC_FACTOR; i = i + 1) begin
                fast_reg[i] <= 0;
            end
        end else begin
            fast_reg[0] <= i_data;
            for (int i = 1; i < DEC_FACTOR; i = i + 1) begin
                fast_reg[i] <= fast_reg[i-1]; // Generates x[n], x[n-1], x[n-2], etc
            end
        end
    end

    // 2. Downsampling Counter
    reg [3:0] sample_cnt;
    
    // 3. Slow Domain: Polyphase Storage
    reg signed [DATA_W-1:0] poly_reg [0:TAPS-1];
    reg signed [CAS_W-1:0]  acc;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sample_cnt       <= 0;
            o_decimated_data <= 0;
            o_data_valid     <= 1'b0;
            for (int i = 0; i < TAPS; i = i + 1) begin
                poly_reg[i]  <= 0;
            end
        end else begin
            if (sample_cnt == (DEC_FACTOR - 1)) begin
                sample_cnt   <= 0;
                o_data_valid <= 1'b1;
                
                // downsample and shift (inside branches simultaneously)
                for (int j = 0; j < TAPS; j = j + 1) begin
                    if (j < DEC_FACTOR) begin   /// 
                        // branch inputs capture the fast domain phases
                        poly_reg[j] <= fast_reg[j];
                    end else begin
                        // internal branch registers shift down by DEC_FACTOR steps
                        poly_reg[j] <= poly_reg[j - DEC_FACTOR];
                    end
                end

                // MAC across all branches
                acc = 0;
                for (int j = 0; j < TAPS; j = j + 1) begin
                    acc = acc + (poly_reg[j] * i_coeffs[j]);
                end
                o_decimated_data <= acc;

            end else begin
                sample_cnt   <= sample_cnt + 1;
                o_data_valid <= 1'b0;
            end
        end
    end

endmodule