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
    parameter DATA_W  = 12,
    parameter COEFF_W = 12,
    parameter CAS_W   = 32
)(
    input i_clk,
    input i_rst_n,
    input signed [DATA_W-1:0] i_data,
    output reg signed [CAS_W-1:0] o_data
);

 
    // 32-Tap Coefficients 
    /*
    parameter signed [COEFF_W-1:0] H0  = 12'd1,  H1  = 12'd2,  H2  = 12'd3,  H3  = 12'd4,
                                    H4  = 12'd5,  H5  = 12'd6,  H6  = 12'd7,  H7  = 12'd8,
                                    H8  = 12'd9,  H9  = 12'd10, H10 = 12'd11, H11 = 12'd12,
                                    H12 = 12'd13, H13 = 12'd14, H14 = 12'd15, H15 = 12'd16,
                                    H16 = 12'd16, H17 = 12'd15, H18 = 12'd14, H19 = 12'd13,
                                    H20 = 12'd12, H21 = 12'd11, H22 = 12'd10, H23 = 12'd9,
                                    H24 = 12'd8,  H25 = 12'd7,  H26 = 12'd6,  H27 = 12'd5,
                                    H28 = 12'd4,  H29 = 12'd3,  H30 = 12'd2,  H31 = 12'd1;
    
    write coefficients in testbench
    */


    // Delay line for 32-tap (x0 to x30, x31 is direct input)
    reg signed [DATA_W-1:0] x0,  x1,  x2,  x3,  x4,  x5,  x6,  x7,
                            x8,  x9,  x10, x11, x12, x13, x14, x15,
                            x16, x17, x18, x19, x20, x21, x22, x23,
                            x24, x25, x26, x27, x28, x29, x30;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            x0  <= 0; 
            x1  <= 0; 
            x2  <= 0; 
            x3  <= 0; 
            x4  <= 0; 
            x5  <= 0; 
            x6  <= 0; 
            x7  <= 0;
            x8  <= 0; 
            x9  <= 0; 
            x10 <= 0; 
            x11 <= 0; 
            x12 <= 0; 
            x13 <= 0; 
            x14 <= 0; 
            x15 <= 0;
            x16 <= 0; 
            x17 <= 0; 
            x18 <= 0; 
            x19 <= 0; 
            x20 <= 0; 
            x21 <= 0; 
            x22 <= 0; 
            x23 <= 0;
            x24 <= 0; 
            x25 <= 0; 
            x26 <= 0; 
            x27 <= 0; 
            x28 <= 0; 
            x29 <= 0; 
            x30 <= 0;
        end 
        else begin
            x0  <= i_data;
            x1  <= x0;  
            x2  <= x1;  
            x3  <= x2;  
            x4  <= x3;  
            x5  <= x4;  
            x6  <= x5;  
            x7  <= x6;
            x8  <= x7;  
            x9  <= x8;  
            x10 <= x9;  
            x11 <= x10; 
            x12 <= x11; 
            x13 <= x12; 
            x14 <= x13; 
            x15 <= x14;
            x16 <= x15; 
            x17 <= x16; 
            x18 <= x17; 
            x19 <= x18; 
            x20 <= x19; 
            x21 <= x20; 
            x22 <= x21; 
            x23 <= x22;
            x24 <= x23; 
            x25 <= x24; 
            x26 <= x25; 
            x27 <= x26; 
            x28 <= x27; 
            x29 <= x28; 
            x30 <= x29;
        end
    end


    wire signed [CAS_W-1:0] m [0:31];

    // MAC Chain (From Tap 31 down to Tap 0)
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m31 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n),
        .i_data(i_data), 
        .i_coeff(H31), 
        .i_cascade_in({CAS_W{1'b0}}), 
        .o_cascade_out(m[31])
    );

    // Mid stages: Tap 30 down to Tap 1
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m30 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x0),   .i_coeff(H30), .i_cascade_in(m[31]), .o_cascade_out(m[30]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m29 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x1),   .i_coeff(H29), .i_cascade_in(m[30]), .o_cascade_out(m[29]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m28 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x2),   .i_coeff(H28), .i_cascade_in(m[29]), .o_cascade_out(m[28]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m27 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x3),   .i_coeff(H27), .i_cascade_in(m[28]), .o_cascade_out(m[27]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m26 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x4),   .i_coeff(H26), .i_cascade_in(m[27]), .o_cascade_out(m[26]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m25 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x5),   .i_coeff(H25), .i_cascade_in(m[26]), .o_cascade_out(m[25]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m24 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x6),   .i_coeff(H24), .i_cascade_in(m[25]), .o_cascade_out(m[24]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m23 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x7),   .i_coeff(H23), .i_cascade_in(m[24]), .o_cascade_out(m[23]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m22 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x8),   .i_coeff(H22), .i_cascade_in(m[23]), .o_cascade_out(m[22]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m21 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x9),   .i_coeff(H21), .i_cascade_in(m[22]), .o_cascade_out(m[21]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m20 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x10),  .i_coeff(H20), .i_cascade_in(m[21]), .o_cascade_out(m[20]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m19 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x11),  .i_coeff(H19), .i_cascade_in(m[20]), .o_cascade_out(m[19]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m18 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x12),  .i_coeff(H18), .i_cascade_in(m[19]), .o_cascade_out(m[18]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m17 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x13),  .i_coeff(H17), .i_cascade_in(m[18]), .o_cascade_out(m[17]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m16 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x14),  .i_coeff(H16), .i_cascade_in(m[17]), .o_cascade_out(m[16]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m15 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x15),  .i_coeff(H15), .i_cascade_in(m[16]), .o_cascade_out(m[15]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m14 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x16),  .i_coeff(H14), .i_cascade_in(m[15]), .o_cascade_out(m[14]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m13 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x17),  .i_coeff(H13), .i_cascade_in(m[14]), .o_cascade_out(m[13]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m12 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x18),  .i_coeff(H12), .i_cascade_in(m[13]), .o_cascade_out(m[12]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m11 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x19),  .i_coeff(H11), .i_cascade_in(m[12]), .o_cascade_out(m[11]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m10 (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x20),  .i_coeff(H10), .i_cascade_in(m[11]), .o_cascade_out(m[10]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m9  (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x21),  .i_coeff(H9),  .i_cascade_in(m[10]), .o_cascade_out(m[9]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m8  (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x22),  .i_coeff(H8),  .i_cascade_in(m[9]),  .o_cascade_out(m[8]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m7  (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x23),  .i_coeff(H7),  .i_cascade_in(m[8]),  .o_cascade_out(m[7]));
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m6  (.i_clk(i_clk), .i_rst_n(i_rst_n), .i_data(x24),  .i_coeff(H6),  .i_cascade_in(m[7]),  .o_cascade_out(m[6]));
    
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m5 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n), 
        .i_data(x25),  
        .i_coeff(H5),  
        .i_cascade_in(m[6]),  
        .o_cascade_out(m[5])
    );
    
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m4 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n), 
        .i_data(x26),  
        .i_coeff(H4),  
        .i_cascade_in(m[5]),  
        .o_cascade_out(m[4])
    );
    
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m3 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n), 
        .i_data(x27),  
        .i_coeff(H3),  
        .i_cascade_in(m[4]),  
        .o_cascade_out(m[3])
    );
    
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m2 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n), 
        .i_data(x28),  
        .i_coeff(H2),  
        .i_cascade_in(m[3]),  
        .o_cascade_out(m[2])
    );
    
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m1 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n), 
        .i_data(x29),  
        .i_coeff(H1),  
        .i_cascade_in(m[2]),  
        .o_cascade_out(m[1])
    );

    // Last stage: Tap 0 (Output produces final accumulated result)
    mac_fir #(DATA_W, COEFF_W, CAS_W, CAS_W) dut_m0 (
        .i_clk(i_clk), 
        .i_rst_n(i_rst_n),
        .i_data(x30), 
        .i_coeff(H0), 
        .i_cascade_in(m[1]), 
        .o_cascade_out(m[0])
    );

    // Final output registration
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            o_data <= {CAS_W{1'b0}};
        else
            o_data <= m[0]; // Final accumulated results
    end

endmodule