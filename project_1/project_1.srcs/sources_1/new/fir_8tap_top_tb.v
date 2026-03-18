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

// -------------------------------------------------
// Testbench signals
// -------------------------------------------------

reg         i_clk;
reg         i_rst_n;
reg  [7:0]  i_x;
wire [7:0]  o_y;


// -------------------------------------------------
// DUT
// -------------------------------------------------

fir_8tap_top dut (
    .i_clk  (i_clk),
    .i_rst_n(i_rst_n),
    .i_x    (i_x),
    .o_y    (o_y)
);


// -------------------------------------------------
// Clock generation
// -------------------------------------------------

initial i_clk = 0;
always #5 i_clk = ~i_clk;


// -------------------------------------------------
// FIR reference model (expected value)
// -------------------------------------------------

integer k;

reg [7:0] ref_delay [0:7];

integer coeff [0:7];

integer expected;

reg [7:0] expected_d1, expected_d2;


// coefficients
initial begin
    coeff[0] = 7;
    coeff[1] = 17;
    coeff[2] = 32;
    coeff[3] = 46;
    coeff[4] = 52;
    coeff[5] = 46;
    coeff[6] = 32;
    coeff[7] = 17;
end


// shift register for reference model
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        for(k = 0; k < 8; k = k + 1)
            ref_delay[k] <= 0;
    end
    else begin
        ref_delay[0] <= i_x;
        for(k = 1; k < 8; k = k + 1)
            ref_delay[k] <= ref_delay[k-1];
    end
end


// expected FIR calculation
always @(*) begin
    expected = 0;
    for(k = 0; k < 8; k = k + 1)
        expected = expected + ref_delay[k] * coeff[k];
end


// -------------------------------------------------
// Stimulus
// -------------------------------------------------

initial begin

    i_rst_n = 0;
    i_x     = 0;

    #20;
    i_rst_n = 1;

    // impulse test
    @(posedge i_clk) i_x = 1;
    @(posedge i_clk) i_x = 0;

    repeat(10) @(posedge i_clk);

    // ramp test
    repeat(20) begin
        @(posedge i_clk);
        i_x = i_x + 1;
    end

    // random test
    repeat(20) begin
        @(posedge i_clk);
        i_x = $random;
    end

    #100 $finish;

end



always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        expected_d1 <= 0;
        expected_d2 <= 0;
    end else begin
        expected_d1 <= expected[7:0];
        expected_d2 <= expected_d1;
    end
end

// -------------------------------------------------
// Display comparison
// -------------------------------------------------

always @(posedge i_clk) begin
    if(i_rst_n) begin
        $display("time=%0t  x=%0d  DUT=%0d  EXPECTED=%0d  %s",
                 $time,
                 i_x,
                 o_y,
                 expected,
                 (o_y==expected_d2) ? "PASS" : "FAIL");
    end
end


endmodule