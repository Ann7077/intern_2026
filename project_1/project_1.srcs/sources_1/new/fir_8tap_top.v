`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2026 01:45:22 PM
// Design Name: 
// Module Name: fir_8tap_top
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


module fir_8tap_top(
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire [7:0]  i_x,
    output reg  [7:0]  o_y
);

// delay line
reg [7:0] x0,x1,x2,x3,x4,x5,x6,x7;

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        x0 <= 0; 
        x1 <= 0; 
        x2 <= 0; 
        x3 <= 0;
        x4 <= 0; 
        x5 <= 0; 
        x6 <= 0; 
        x7 <= 0;
    end
    else begin
        x0 <= i_x;
        x1 <= x0;
        x2 <= x1;
        x3 <= x2;
        x4 <= x3;
        x5 <= x4;
        x6 <= x5;
        x7 <= x6;
    end
end


// coefficients
localparam B0 = 7;
localparam B1 = 17;
localparam B2 = 32;
localparam B3 = 46;
localparam B4 = 52;
localparam B5 = 46;
localparam B6 = 32;
localparam B7 = 17;


// MAC outputs
wire [7:0] y0,y1,y2,y3,y4,y5,y6,y7;
wire       c0,c1,c2,c3,c4,c5,c6,c7;

mac_u m0(i_clk, i_rst_n, x0, B0, 8'd0, y0, c0);
mac_u m1(i_clk, i_rst_n, x1, B1, y0,   y1, c1);
mac_u m2(i_clk, i_rst_n, x2, B2, y1,   y2, c2);
mac_u m3(i_clk, i_rst_n, x3, B3, y2,   y3, c3);
mac_u m4(i_clk, i_rst_n, x4, B4, y3,   y4, c4);
mac_u m5(i_clk, i_rst_n, x5, B5, y4,   y5, c5);
mac_u m6(i_clk, i_rst_n, x6, B6, y5,   y6, c6);
mac_u m7(i_clk, i_rst_n, x7, B7, y6,   y7, c7);


// output register (final stage)
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        o_y <= 0;
    else
        o_y <= y7;
end

endmodule