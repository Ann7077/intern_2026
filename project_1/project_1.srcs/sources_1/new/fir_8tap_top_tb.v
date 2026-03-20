`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2026 01:46:27 PM
// Design Name: 
// Module Name: fir_8tap_top_tb
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


module fir_8tap_top_tb;

reg clk;
reg rst_n;
reg [7:0] x;
wire [7:0] y;

// DUT
fir_8tap_top dut (
    .i_clk   (clk),
    .i_rst_n (rst_n),
    .i_x     (x),
    .o_y     (y)
);

// ===============================
// CLOCK
// ===============================
always #5 clk = ~clk;

// ===============================
// COEFFICIENTS
// ===============================
reg [7:0] B [0:7];

initial begin
    B[0]=7;  B[1]=17; B[2]=32; B[3]=46;
    B[4]=52; B[5]=46; B[6]=32; B[7]=17;
end

// ===============================
// INPUT HISTORY
// ===============================
reg [7:0] x_hist [0:7];
integer i;

// ===============================
// EXPECTED (full precision)
// ===============================
reg [15:0] expected;
reg [7:0] expected_scaled;

// ===============================
// PIPELINE DELAY (IMPORTANT)
// ===============================
reg [7:0] expected_dly [0:16];   // 17 stages

// ===============================
// INITIALIZATION (CRITICAL FIX)
// ===============================
integer j;

initial begin
    clk = 0;
    rst_n = 0;
    x = 0;

    // initialize arrays to avoid 'x'
    for (j = 0; j < 8; j = j + 1)
        x_hist[j] = 0;

    for (j = 0; j < 17; j = j + 1)
        expected_dly[j] = 0;

    #20;
    rst_n = 1;
end

// ===============================
// SHIFT REGISTER (input delay line)
// ===============================
always @(posedge clk) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1)
            x_hist[i] <= 0;
    end else begin
        x_hist[0] <= x;
        for (i = 1; i < 8; i = i + 1)
            x_hist[i] <= x_hist[i-1];
    end
end



reg [7:0] exp_stage [0:7];

always @(*) begin
    exp_stage[0] = (x_hist[0]*B[0]) >> 8;
    exp_stage[1] = ((x_hist[1]*B[1]) >> 8) + exp_stage[0];
    exp_stage[2] = ((x_hist[2]*B[2]) >> 8) + exp_stage[1];
    exp_stage[3] = ((x_hist[3]*B[3]) >> 8) + exp_stage[2];
    exp_stage[4] = ((x_hist[4]*B[4]) >> 8) + exp_stage[3];
    exp_stage[5] = ((x_hist[5]*B[5]) >> 8) + exp_stage[4];
    exp_stage[6] = ((x_hist[6]*B[6]) >> 8) + exp_stage[5];
    exp_stage[7] = ((x_hist[7]*B[7]) >> 8) + exp_stage[6];
end

always @(*) begin
    expected_scaled = exp_stage[7];
end



// ===============================
// LATENCY ALIGNMENT (17 cycles)
// ===============================
always @(posedge clk) begin
    if (!rst_n) begin
        for (i = 0; i < 17; i = i + 1)
            expected_dly[i] <= 0;
    end else begin
        expected_dly[0] <= expected_scaled;
        for (i = 1; i < 17; i = i + 1)
            expected_dly[i] <= expected_dly[i-1];
    end
end

// ===============================
// STIMULUS
// ===============================
integer t;

initial begin
    @(posedge rst_n);

    for (t = 0; t < 200; t = t + 1) begin
        @(posedge clk);
        x <= t;
    end

    #200;
    $finish;
end

// ===============================
// CHECKER (skip invalid cycles)
// ===============================
integer cycle_count = 0;

always @(posedge clk) begin
    if (rst_n) begin
        cycle_count <= cycle_count + 1;

        // wait for pipeline to fill
        if (cycle_count > 25) begin
            if (y === expected_dly[16])
                $display("time=%0t x=%0d DUT=%0d EXPECTED=%0d PASS",
                         $time, x, y, expected_dly[16]);
            else
                $display("time=%0t x=%0d DUT=%0d EXPECTED=%0d FAIL",
                         $time, x, y, expected_dly[16]);
        end
    end
end

endmodule