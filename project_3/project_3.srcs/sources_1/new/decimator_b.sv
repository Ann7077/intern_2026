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
    parameter TAPS       = 7,   // 32
    parameter DEC_FACTOR = 3    // 10
)(
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire signed [DATA_W-1:0]  i_data,
    input  wire signed [COEFF_W-1:0] i_coeffs [0:TAPS-1],
    
    output reg  signed [CAS_W-1:0]   o_decimated_data,
    output reg                       o_data_valid  
);

    localparam TAPS_PER_BRANCH = (TAPS + DEC_FACTOR - 1) / DEC_FACTOR;

    // 1. Fast Domain: Delay line to feed the phase switches
    reg signed [DATA_W-1:0] fast_reg [0:DEC_FACTOR-1];   // array of registers operating at the full input clock rate (100 MHz)

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (int i = 0; i < DEC_FACTOR; i = i + 1) begin
                fast_reg[i] <= 0;
            end
        end else begin
            fast_reg[0] <= i_data;
            for (int i = 1; i < DEC_FACTOR; i = i + 1) begin
                fast_reg[i] <= fast_reg[i-1];
            end
        end
    end

    // 2. Sample Counter for Downsampling
    // Downsampling countdown timer. Slow down the data rate by a factor of N (DEC_FACTOR)
    reg [$clog2(DEC_FACTOR)-1:0] sample_cnt;  // $clog2 is "ceiling of log base 2"

    // 3. Symmetric 2D Matrix Storage for Balanced Polyphase Processing
    reg signed [DATA_W-1:0]  poly_reg_2d    [0:DEC_FACTOR-1][0:TAPS_PER_BRANCH-1];  // 2D array representing the state/delay registers inside each polyphase branch
    reg signed [COEFF_W-1:0] poly_coeffs_2d [0:DEC_FACTOR-1][0:TAPS_PER_BRANCH-1];  // 2D array storing the FIR filter coefficients redistributed across parallel sub-filter branches.
    
    reg signed [CAS_W-1:0]   acc;

    // 4. Generates the virtual zeros (ex: h7=0, h8=0) automatically if TAPS isn't a multiple of DEC_FACTOR
    // poly_coeffs_2d [b][k]: b is branches, from 0 to DEC_FACTOR - 1; k is taps, from 0 to TAPS_PER_BRANCH - 1
    // flat_idx = b + (k * DEC_FACTOR) is what figures out what's the coefficient subscript and if zero need to added
    always_comb begin
        for (int b = 0; b < DEC_FACTOR; b = b + 1) begin
            for (int k = 0; k < TAPS_PER_BRANCH; k = k + 1) begin
                automatic int flat_idx = b + (k * DEC_FACTOR);
                
                if (flat_idx < TAPS) begin
                    poly_coeffs_2d[b][k] = i_coeffs[flat_idx];
                end else begin
                    poly_coeffs_2d[b][k] = {COEFF_W{1'b0}}; // zero padding
                end
            end
        end
    end

    // 5. Downsampling, Shifting, and Accumulation 
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            sample_cnt       <= 2; 
            o_decimated_data <= 0;
            o_data_valid     <= 1'b0;
            
            for (int b = 0; b < DEC_FACTOR; b = b + 1) begin
                for (int k = 0; k < TAPS_PER_BRANCH; k = k + 1) begin
                    poly_reg_2d[b][k] <= 0;
                end
            end
        end else begin
            if (sample_cnt == (DEC_FACTOR - 1)) begin
                sample_cnt   <= 0;
                o_data_valid <= 1'b1;
                
                // The Symmetrical 2D Shift Register Line
                for (int b = 0; b < DEC_FACTOR; b = b + 1) begin
                    // Shift the older values down the specific branch delay line
                    for (int k = TAPS_PER_BRANCH - 1; k > 0; k = k - 1) begin
                        poly_reg_2d[b][k] <= poly_reg_2d[b][k-1];
                    end
                    // Load the newly caught fast-domain phase sample into the head of the branch
                    poly_reg_2d[b][0] <= fast_reg[b];
                end

                // MAC
                acc = 0;
                for (int b = 0; b < DEC_FACTOR; b = b + 1) begin
                    for (int k = 0; k < TAPS_PER_BRANCH; k = k + 1) begin
                        acc = acc + (poly_reg_2d[b][k] * poly_coeffs_2d[b][k]);
                    end
                end
                o_decimated_data <= acc;

            end else begin
                sample_cnt   <= sample_cnt + 1;
                o_data_valid <= 1'b0;
            end
        end
    end

endmodule