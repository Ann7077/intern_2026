`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/11/2026 07:12:11 PM
// Design Name: 
// Module Name: mul_u_tb
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


module mul_u_tb;

    parameter A_W = 8;           // Define the bit width parameter of input A of the multiplier 
    parameter B_W = 6;           // Define the bit width parameter of input B of the multiplier 
    parameter P_W = A_W + B_W;   // Define the bit width parameter of output P 
    
    // DUT = Device Under Test
    reg i_clk;
    reg i_rst_n;
    reg [A_W-1:0] i_a;   // The DUT input is declared as A (reg is used because value need to be assigned in tb)
    reg [B_W-1:0] i_b;   // The DUT input is declared as B
    wire [P_W-1:0] o_p;  // Declare DUT output product P (wire is driven using DUT
    
    initial i_clk = 1'b0;
    always begin 
        #(10.000/2) i_clk = ~i_clk;   // 5ns toggle
    end
    
    initial begin
        i_rst_n = 1'b0;   // assert reset at t=0
        #8;               // keep reset low for a while
        i_rst_n = 1'b1;   // deassert reset before the 2nd check samples
    end
    
    reg [P_W-1:0] exp_p;  // Declare expected output for reference
    
    mul_u dut (    // Instantiate the DUT
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_a(i_a),  // Connect the tb's i_a port to the DUT's i_a port
        .i_b(i_b),  // Connect the tb's i_b port to the DUT's i_b port
        .o_p(o_p)   // Connect the DUT output o_p to the tb o_p signal
    );
    
    task check;  // define a task named "check" for a one time test/self-check
        input [A_W-1:0] a;  // task input: value for A
        input [B_W-1:0] b;  // tast input: value for B
        begin
            i_a <= a;  // set DUT input i_a as task input a
            i_b <= b;  // set DUT input i_b as task input b
            #1;       // wait to stabilize the logic
            exp_p = a * b;   // expected output (golden reference)
            
            @(posedge i_clk);  // wait for registered output to update
            #1;                // small delay to avoid sampling in same time slot 
            
            if (o_p !== exp_p) begin
                $display("MUL FAIL: a=%0d b=%0d got=%0d exp=%0d", a, b, o_p, exp_p);
                    // display the error message and values found 
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
        
        check(0,0);                       // test: 0 * 0 = 0
        check({A_W{1'b1}},0);             // test: max A * 0 = 0
        check(0,{B_W{1'b1}});             // test: 0 * max B = 0
        check({A_W{1'b1}},{B_W{1'b1}});   // test: max A * max B
        
        for (k = 0; k < 1000; k = k + 1) begin   // do 1000 random test 
            check ($random, $random);   // use task to test for correctness while inputs are randomized
        end
        
        $display("num_tb PASS");    // if all tests passed, print PASS
        $finish;                      // end simulation
    end

endmodule

/*
1. Start with defining the parameters
2. Declare DUT values of input and output
3. Declare expected output value
4. Instantiate the DUT
5. Self-check
    5.1 Create input values for test
    5.2 Set DUT input as corresponding task input
    5.3 Calculate 
    5.4 Check if actual vaule matched expected value, if not, report error
6. initial block for simulation
    6.1 initialize DUT inputs
    6.2 Set cases to be tested
    6.3 Loop random cases to be tested
    6.4 If simulation passed, print "PASS"
*/


