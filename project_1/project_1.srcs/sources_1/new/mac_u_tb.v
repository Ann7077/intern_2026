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
    // Parameters updated to match your mac_u.v bit-widths
    parameter A_W    = 8;
    parameter B_W    = 8;
    parameter C_W    = 8;
    parameter Y_W    = 8;   // Output is 8-bit in your RTL
    parameter COUT_W = 1;

    reg i_clk;
    reg i_rst_n;
    reg signed [A_W-1:0] i_a;
    reg signed [B_W-1:0] i_b;
    reg signed [C_W-1:0] i_c;
    wire signed [Y_W-1:0] o_y;
    wire o_cout;

    // Clock generation (100MHz)
    initial i_clk = 1'b0;
    always begin
        #(10.000/2) i_clk = ~i_clk; // 5ns toggle
    end

    // Asynchronous Reset
    initial begin
        i_rst_n = 1'b0; // assert reset at t=0
        #8;             // keep reset low for a while
        i_rst_n = 1'b1; // deassert reset
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

    // Task to verify signed MAC with saturation
    task check;
        input signed [A_W-1:0] a;
        input signed [B_W-1:0] b;
        input signed [C_W-1:0] c_in;

        reg signed [15:0] prod;
        reg signed [8:0]  sum;
        reg signed [7:0]  exp_y;
        reg               exp_cout;

        begin
            i_a <= a;
            i_b <= b;
            i_c <= c_in;
            
            // --- Golden Reference Logic ---
            // Stage 1: Multiplication
            prod = a * b;
            // Stage 2: Scale and Add (Matching: sum <= (mult >>> 7) + i_c_d)
            sum = (prod >>> 7) + c_in;
            
            // Saturation Logic (Matching your sum[8] != sum[7] check)
            if (sum[8] != sum[7]) begin
                exp_y    = sum[8] ? 8'b10000000 : 8'b01111111;
                exp_cout = 1'b1;
            end else begin
                exp_y    = sum[7:0];
                exp_cout = 1'b0;
            end

            // Wait for 2 clock cycles (Pipeline Latency)
            @(posedge i_clk);
            @(posedge i_clk);
            @(posedge i_clk);
            #1; // Small offset to sample after output changes

            if ((o_y !== exp_y) || (o_cout !== exp_cout)) begin
                $display("MAC FAIL: a=%0d b=%0d c=%0d | Got: y=%d cout=%b | Exp: y=%d cout=%b",
                         a, b, c_in, o_y, o_cout, exp_y, exp_cout);
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,0",
                          $time, a, b, c_in, o_y, o_cout, exp_y);
            end else begin
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,1",
                          $time, a, b, c_in, o_y, o_cout, exp_y);
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

        // --- Directed Tests ---
        check(0, 0, 0);
        check(1, 1, 1);
        check(100, 100, 100);    // max positive, o_y = 127, o_cout = 1
        check(120, -120, -50);   // max negative, o_y = -128, o_cout = 1
        check(127, 1, 127);      // edge case, o_y = 127, o_cout = 0
        check(127, 2, 127);      // just over, o_y = 127, o_cout = 1
        
        check({A_W{1'b1}}, 0, 0);
        check(0, {B_W{1'b1}}, {C_W{1'b1}});
        check({A_W{1'b1}}, {B_W{1'b1}}, 0);
        check({A_W{1'b1}}, {B_W{1'b1}}, 1);
        check({A_W{1'b1}}, {B_W{1'b1}}, {C_W{1'b1}});

        // --- Random Tests ---
        for (k = 0; k < 100; k = k + 1) begin
            // $random generates 32-bit signed; truncated to 8-bit signed
            check($random, $random, $random);
        end
        
        $display("num_tb DONE - Check mac_log.csv for details");
        $fclose(fd);
        $finish;
    end

endmodule



