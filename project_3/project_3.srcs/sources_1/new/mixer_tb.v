`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2026 01:10:25 PM
// Design Name: 
// Module Name: mixer_tb
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


module mixer_tb;
    
    parameter IN_W = 12;
    parameter OUT_W = 24;
    
    reg clk;
    reg rst_n;
    reg signed [IN_W-1:0] adc_data;
    reg signed [IN_W-1:0] dds_cos;
    reg signed [IN_W-1:0] dds_sin;
    
    wire signed [OUT_W:0] i_out;
    wire signed [OUT_W:0] q_out;


    // clock generator
    initial clk = 1'b0;
    always begin 
        #(10.000/2) clk = ~clk;   
    end
    
    // reset generator
    initial begin
        rst_n = 1'b0;   // assert reset at t=0
        #8;               // keep reset low for a while
        rst_n = 1'b1;   // deassert reset before the 2nd check samples
    end
    
    // expected outputs
    reg signed [OUT_W:0] exp_i_out;
    reg signed [OUT_W:0] exp_q_out;
    
    // generate csv file 
    integer fd;
    initial begin
        fd = $fopen("mixer_log.csv", "w");
        $display("LOG fd=%0d", fd);
        if (fd == 0) begin
            $display("ERROR: cannot open mixer_log.csv");
            $finish;
        end
        $fdisplay(fd, "time,adc_data,dds_cos,dds_sin,i_out,q_out,exp_i_out,exp_q_out,pass"); 
    end
    
    

endmodule
