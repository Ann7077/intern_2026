`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2026 04:00:04 PM
// Design Name: 
// Module Name: mac_fir_tb
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


module mac_fir_tb;

    parameter DATA_W = 12;
    parameter COEFF_W = 12;
    parameter CAS_IN_W = 32;
    parameter CAS_OUT_W = 32;
    
    reg i_clk;
    reg i_rst_n;
    reg signed   [DATA_W-1:0]     i_data;
    reg signed   [COEFF_W-1:0]    i_coeff;
    reg signed   [CAS_IN_W-1:0]   i_cascade_in;
    wire signed  [CAS_OUT_W-1:0]  o_cascade_out;
   
    // clock generator
    initial i_clk = 1'b0;
    always begin
        #(10.000/2) i_clk = ~i_clk; 
    end
    
    // reset generator
    initial begin
        i_rst_n = 1'b0;
        #8;
        i_rst_n = 1'b1;
    end
    
    integer fd;
    initial begin
        fd = $fopen("mac_fir_log.csv", "w");
        if (fd == 0) begin
            $display("ERROR: cannot open mac_fir_log.csv");
            $finish;
        end
        $fdisplay(fd, "time,data,coeff,cascade_in,cascade_out,exp_cascade_out,pass");
    end
    
    mac_fir dut(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_data(i_data),
        .i_coeff(i_coeff),
        .i_cascade_in(i_cascade_in),
        .o_cascade_out(o_cascade_out)
    );
   
    // Task to verify signed MAC FIR stage
    task check;
        input signed [DATA_W-1:0]   data;
        input signed [COEFF_W-1:0]  coeff;
        input signed [CAS_IN_W-1:0] cascade_in;

        reg signed [23:0] prod;
        reg signed [CAS_OUT_W-1:0] exp_cascade_out;
        begin
            @(posedge i_clk);
            #1;
            i_data       <= data;
            i_coeff      <= coeff;
            i_cascade_in <= cascade_in;
            
            // --- Golden Reference Logic ---
            // Stage 1: Multiplication
            prod = $signed(data) * $signed(coeff);
            // Stage 2: Accumulate with cascade input
            exp_cascade_out = $signed(prod) + $signed(cascade_in);

            // Wait for clock cycles (Pipeline Latency alignment matching mac_u_tb)
            @(posedge i_clk);
            @(posedge i_clk);
            #1; // Small offset to sample after output changes

            if (o_cascade_out !== exp_cascade_out) begin
                $display("MAC_FIR FAIL: data=%0d coeff=%0d cascade_in=%0d | Got: cascade_out=%d | Exp: cascade_out=%d",
                         data, coeff, cascade_in, o_cascade_out, exp_cascade_out);
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,0",
                          $time, data, coeff, cascade_in, o_cascade_out, exp_cascade_out);
            end else begin
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,1",
                          $time, data, coeff, cascade_in, o_cascade_out, exp_cascade_out);
            end
        end
    endtask

    integer k;
    initial begin
        i_data       = {DATA_W{1'b0}};
        i_coeff      = {COEFF_W{1'b0}};
        i_cascade_in = {CAS_IN_W{1'b0}};
        #1;
        @(posedge i_rst_n);
        repeat(2) @(posedge i_clk);

        // --- Directed Tests ---
        check(0, 0, 0);
        check(1, 1, 1);
        check(10, 5, 100);
        check(-10, 5, 100);
        check(2047, 2047, 4000);   // Max positive 12-bit values
        check(-2048, 2047, -4000); // Max negative 12-bit values
        
        //check({DATA_W{1'b1}}, 0, 0);
        //check(0, {COEFF_W{1'b1}}, {CAS_IN_W{1'b1}});
        //check({DATA_W{1'b1}}, {COEFF_W{1'b1}}, 0);
        //check({DATA_W{1'b1}}, {COEFF_W{1'b1}}, 1);
        //check({DATA_W{1'b1}}, {COEFF_W{1'b1}}, {CAS_IN_W{1'b1}});

        // --- Random Tests ---
        for (k = 0; k < 100; k = k + 1) begin
            check($random % 2048, $random % 2048, $random % 65536);
        end
        
        $display("mac_fir_tb DONE - Check mac_fir_log.csv for details");
        $fclose(fd);
        $finish;
    end
    
endmodule




