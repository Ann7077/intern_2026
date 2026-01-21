`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2026 10:07:19 PM
// Design Name: 
// Module Name: add_u_tb
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


module add_u_tb;

    parameter A_W = 14;
    parameter B_W = 14;
    parameter SUM_W = 14;
    parameter COUT_W = 1;
    
    reg i_clk;
    reg i_rst_n;
    reg [A_W-1:0] i_a;
    reg [B_W-1:0] i_b;
    wire [SUM_W-1:0] o_sum;
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
    
    reg [SUM_W-1:0] exp_sum;  
    reg exp_cout;
    
    add_u dut(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(i_a),
        .i_b(i_b),
        .o_sum(o_sum),
        .o_cout(o_cout)
    );
        
    task check;
        input [A_W-1:0] a;
        input [B_W-1:0] b;
        
        reg [SUM_W:0] exp_full_sum;
        
        begin
            i_a <= a;
            i_b <= b;
            #1;
            exp_full_sum = {1'b0, a} + {1'b0, b};
            exp_sum = exp_full_sum[SUM_W-1:0];
            exp_cout = exp_full_sum[SUM_W];
            
            @(posedge i_clk);  // wait for registered output to update
            #1;
            
            if ((exp_sum !== o_sum) || (exp_cout !== o_cout)) begin
                $display("ADD FAIL: a=%0d b=%0d sum_got=%0d sum_exp=%0d cout_got=%0d cout_exp=%0d", a, b, o_sum, exp_sum, o_cout, exp_cout);
                $stop;
            end
        end
    endtask
    
    integer k;
    initial begin
        i_a = {A_W{1'b0}};   // initialize i_a as 0 
        i_b = {B_W{1'b0}};   // initialize i_b as 0 
        #1;                  // wait for initialization to take effect
        
        @(posedge i_rst_n);
        @(posedge i_clk);
        #1;
 
        check(0,0);                       // test: 0 + 0 = 0
        check({A_W{1'b1}},0);             // test: max A + 0 = max A
        check(0,{B_W{1'b1}});             // test: 0 + max B = max B
        check({A_W{1'b1}},{B_W{1'b1}});   // test: max A + max B
        
        check({A_W{1'b1}},1);             // test: max A + 1 
        check(1,{B_W{1'b1}});             // test: 1 + max B 
        check({A_W{1'b1}}-1,1);           // test: (max A - 1) + 1 
        check(1,{B_W{1'b1}}-1);           // test: 1 + (max B - 1) 
     
        for (k = 0; k < 1000; k = k + 1) begin   // do 1000 random test 
            check ($random, $random);   // use task to test for correctness while inputs are randomized
        end

        $display("num_tb PASS");    // if all tests passed, print PASS
        $finish;                      // end simulation
    end
    
endmodule

