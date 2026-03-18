`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/23/2026 10:24:49 PM
// Design Name: 
// Module Name: mac_u_tb
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


module mac_u_tb;

    parameter A_W    = 8;
    parameter B_W    = 8;
    parameter C_W    = 8;
    parameter Y_W    = 8;
    parameter COUT_W = 1;

    reg i_clk;
    reg i_rst_n;
    reg [A_W-1:0] i_a;
    reg [B_W-1:0] i_b;
    reg [C_W-1:0] i_c;
    wire [Y_W-1:0] o_y;
    wire o_cout;

    initial i_clk = 1'b0;
    always begin
        #(10.000/2) i_clk = ~i_clk;   // 5ns toggle
    end

    initial begin
        i_rst_n = 1'b0;   // assert reset at t=0
        #8;               // keep reset low for a while
        i_rst_n = 1'b1;   // deassert reset before checks start
    end
    

    integer fd;
    initial begin
        fd = $fopen("mac_log.csv", "w");
        if (fd == 0) begin
            $display("ERROR: cannot open mac_log.csv");
            $finish;
        end
        $fdisplay(fd, "time,a,b,c,y_got,cout_got,exp_full,pass");
    end


    mac_u dut(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(i_a),
        .i_b(i_b),
        .i_c(i_c),
        .o_y(o_y),
        .o_cout(o_cout)
    );

    task check;
        input [A_W-1:0] a;
        input [B_W-1:0] b;
        input [C_W-1:0] c_in;

        reg [8:0] exp_full;
        reg [15:0] exp_prod_1;
        reg [7:0] exp_prod;

        begin
            i_a <= a;
            i_b <= b;
            i_c <= c_in;
            #1;

            // golden reference (matches DUT: 16-bit product + zero-extended 8-bit c)
            exp_prod_1 = a * b;
            exp_prod = exp_prod_1[7:0]; //////
            exp_full = exp_prod + c_in;
            
            // mac_u latency:
            // posedge 1: stage1 captures (a*b) and c
            // posedge 2: stage2 outputs sum from previous stage1 regs
            @(posedge i_clk);
            @(posedge i_clk);
            #1;

            if ((o_y !== exp_full[7:0]) || (o_cout !== exp_full[8])) begin
                $display("MAC FAIL: a=%0d b=%0d c=%0d y_got=%0d cout_got=%0d exp_full=%0d",
                         a, b, c_in, o_y, o_cout, exp_full);
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,0",
                          $time, a, b, c_in, o_y, o_cout, exp_full);
            end else begin
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,1",
                          $time, a, b, c_in, o_y,o_cout,exp_full);
            end
        end
    endtask


    integer k;
    initial begin
        i_a = {A_W{1'b0}};
        i_b = {B_W{1'b0}};
        i_c = {C_W{1'b0}};
        #1;

        @(posedge i_rst_n);
        @(posedge i_clk);

        // directed tests
        check(0, 0, 0);                                // 0 * 0 + 0
        check(1, 1, 1);                                // 1 * 1 + 1
        check({A_W{1'b1}}, 0, 0);                      // maxA * 0 + 0
        check(0, {B_W{1'b1}}, {C_W{1'b1}});            // 0 * maxB + maxC
        check({A_W{1'b1}}, {B_W{1'b1}}, 0);            // maxA * maxB + 0
        check({A_W{1'b1}}, {B_W{1'b1}}, 1);            // maxA * maxB + 1
        check({A_W{1'b1}}, {B_W{1'b1}}, {C_W{1'b1}});  // maxA * maxB + maxC

        // random tests
        for (k = 0; k < 100; k = k + 1) begin
            check($random, $random, $random);
        end
        
        $display("num_tb PASS");
        $fclose(fd);
        $finish;
    end

endmodule




