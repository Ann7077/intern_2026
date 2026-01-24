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

    parameter A_W = 14;
    parameter B_W = 14;
    parameter C_W = 14;
    parameter Y_W = 28;
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
        i_rst_n = 1'b1;   // deassert reset before the 2nd check samples
    end
    
    reg [Y_W-1:0] exp_y;
    reg exp_cout;
    
    integer fd;
    initial begin
        fd = $fopen("mac_log.csv", "w");
        if (fd == 0) begin
            $display("ERROR: cannot open mac_log.csv");
            $finish;
        end
        $fdisplay(fd, "time,a,b,c,got_y,exp_y,got_cout,exp_cout,pass");
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
        input [C_W-1:0] c;
        
        reg [Y_W-1:0] prod;
        reg [Y_W:0] exp_full_sol;
        
        begin 
            i_a <= a;
            i_b <= b;
            i_c <= c;
            #1;
            prod = a * b;
            exp_full_sol = {1'b0, prod} + {15'b0, c};
            exp_y = exp_full_sol[Y_W-1:0];
            exp_cout = exp_full_sol[Y_W];
            
            @(posedge i_clk);
            #1;
            
            if ((exp_y !== o_y) || (exp_cout !== o_cout)) begin
                $display("ADD FAIL: a=%0d b=%0d c=%0d got_y=%0d exp_y=%0d got_cout=%0d exp_cout=%0d", a, b, c, o_y, exp_y, o_cout, exp_cout);
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,%0d,0", $time, a, b, c, o_y, exp_y, o_cout, exp_cout);
            end else begin
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,%0d,1", $time, a, b, c, o_y, exp_y, o_cout, exp_cout);
            end
        end
    endtask
    
    integer k;
    initial begin
        i_a = {A_W{1'b0}};   // initialize i_a as 0 
        i_b = {B_W{1'b0}};   // initialize i_b as 0 
        i_c = {C_W{1'b0}};   // initialize i_c as 0 
        #1;                  // wait for initialization to take effect
        
        @(posedge i_rst_n);
        @(posedge i_clk);
        #1;
 
        check(0,0,0);                        // test: 0 * 0 + 0 = 0
        check({A_W{1'b1}},0,0);              // test: max A * 0 + 0 = 0
        check(0,{B_W{1'b1}},0);              // test: 0 * max B + 0 = 0
        check({A_W{1'b1}},{B_W{1'b1}},0);    // test: max A * max B + 0
        check(0,0,{A_W{1'b1}});              // test: 0 * 0 + max A = max A
        check(0,0,{B_W{1'b1}});              // test: 0 * 0 + max B = max B
        check(1,{A_W{1'b1}}-1,1);            // test: 1 * (max A - 1) + 1 
        check(1,{B_W{1'b1}}-1,1);            // test: 1 * (max B - 1) + 1 

     
        for (k = 0; k < 1000; k = k + 1) begin   // do 1000 random test 
            check ($random, $random, $random);   // use task to test for correctness while inputs are randomized
        end

        $display("num_tb PASS");    // if all tests passed, print PASS
        $fclose(fd);
        $finish;                      // end simulation
    end

endmodule
