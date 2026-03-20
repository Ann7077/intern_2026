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
    reg signed [A_W-1:0] i_a;
    reg signed [B_W-1:0] i_b;
    reg signed [C_W-1:0] i_c;
    wire [Y_W-1:0] o_y;
    wire o_cout;
    
    reg signed [A_W-1:0] a_prev, b_prev, c_prev;

    initial i_clk = 1'b0;
    always begin
        #(10.000/2) i_clk = ~i_clk;   // 5ns toggle
    end

    initial begin
        a_prev = 0;
        b_prev = 0;
        c_prev = 0;
    
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
        $fdisplay(fd, "time,a,b,c,y_got,cout_got,exp_y,pass");
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
        input signed [A_W-1:0] a;
        input signed [B_W-1:0] b;
        input signed [C_W-1:0] c_in;
        
        reg signed [15:0] exp_mult;
        reg signed [8:0]  exp_sum;
        reg signed [7:0]  exp_y;
        reg               exp_cout;
        

        begin
            i_a = a;
            i_b = b;
            i_c = c_in;
             
            // mac_u latency:
            // posedge 1: stage1 captures (a*b) and c
            // posedge 2: stage2 outputs sum from previous stage1 regs
            @(posedge i_clk);
            @(posedge i_clk);
            #1;
            
            // golden reference (matches DUT: 16-bit product + zero-extended 8-bit c)        
            begin
                // signed multiply
                exp_mult = a_prev * b_prev;
            
                // arithmetic shift (Q16.14 ¡ú Q9.7)
                exp_sum = (exp_mult >>> 7) + c_prev;
            
                // overflow detection
                exp_cout = (exp_sum[8] != exp_sum[7]);
            
                // saturation
                if (exp_cout) begin
                    exp_y = exp_sum[8] ? -8'sd128 : 8'sd127;
                end else begin
                    exp_y = exp_sum[7:0];
                end
            end
            

            if ((o_y !== exp_y) || (o_cout !== exp_cout)) begin
                $display("MAC FAIL: a=%0d b=%0d c=%0d y_got=%0d cout_got=%0d exp_y=%0d",
                         a, b, c_in, o_y, o_cout, exp_y);
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,0",
                          $time, a, b, c_in, o_y, o_cout, exp_y);
            end else begin
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,1",
                          $time, a, b, c_in, o_y,o_cout,exp_y);
            end
            
            a_prev = a;
            b_prev = b;
            c_prev = c_in;
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
        check(127, 127, 127);                          // positive overflow
        check(-128, -128, -128);                       // negative overflow
        check(127, -128, 0);                           // mixed signs

        // random tests
        for (k = 0; k < 100; k = k + 1) begin
            check($random, $random, $random);
        end
        
        $display("num_tb PASS");
        $fclose(fd);
        $finish;
    end

endmodule




