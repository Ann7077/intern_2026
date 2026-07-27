`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 07:44:47 PM
// Design Name: 
// Module Name: dds_tb
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

module dds_tb;

    // Parameters matching dds.v default parameters
    parameter ACC_W = 32;
    parameter LUT_W = 10;
    parameter OUT_W = 12;

    // Testbench Signals
    reg                clk;
    reg                rst_n;
    reg  [ACC_W-1:0]   ftw;
    reg  [ACC_W-1:0]   phase_offset;

    wire signed [OUT_W-1:0] dds_sin;
    wire signed [OUT_W-1:0] dds_cos;

    // File descriptors for logging output data
    integer file_sin;
    integer file_cos;

    // Instantiate Device Under Test (DUT)
    dds #(
        .ACC_W(ACC_W),
        .LUT_W(LUT_W),
        .OUT_W(OUT_W)
    ) u_dds (
        .clk(clk),
        .rst_n(rst_n),
        .ftw(ftw),
        .phase_offset(phase_offset),
        .dds_sin(dds_sin),
        .dds_cos(dds_cos)
    );

    // 100 MHz Clock Generation (Period = 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        rst_n        = 0;
        phase_offset = 32'd0;
        
        // Target: 20 MHz output with 100 MHz clock
        // FTW = (20 MHz * 2^32) / 100 MHz = 858993459 (32'h3333_3333)
        ftw = 32'h3333_3333;

        // Open files to write waveform outputs for Python FFT analysis
        file_sin = $fopen("dds_sin_out.txt", "w");
        file_cos = $fopen("dds_cos_out.txt", "w");

        // Hold Reset for 50 ns
        #50;
        rst_n = 1;

        // Run simulation for 1 microsecond (100 clock cycles / 20 full output cycles)
        #1000;

        // Close files and finish simulation
        $fclose(file_sin);
        $fclose(file_cos);
        $display("DDS Simulation completed successfully!");
        $finish;
    end

    // Log sine and cosine outputs on every positive clock edge after reset
    always @(posedge clk) begin
        if (rst_n) begin
            $fdisplay(file_sin, "%d", dds_sin);
            $fdisplay(file_cos, "%d", dds_cos);
        end
    end

endmodule