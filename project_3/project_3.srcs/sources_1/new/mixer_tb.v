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
    
    wire signed [OUT_W-1:0] i_out;
    wire signed [OUT_W-1:0] q_out;


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
    reg signed [OUT_W-1:0] exp_i_out;
    reg signed [OUT_W-1:0] exp_q_out;
    
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
    
    // DUT
    mixer dut (   
        .clk(clk),
        .rst_n(rst_n),
        .adc_data(adc_data),  
        .dds_cos(dds_cos),  
        .dds_sin(dds_sin),
        .i_out(i_out),
        .q_out(q_out)
    );
    
    // task named "check" for self-check
    task check;  
        input signed [IN_W-1:0] c_adc_data;
        input signed [IN_W-1:0] c_dds_cos; 
        input signed [IN_W-1:0] c_dds_sin;  
        
        begin
            @(posedge clk);  // apply inputs after the clock edge
            #1;
        
            adc_data <= c_adc_data;  // set DUT input adc_data as task input c_adc_data
            dds_cos  <= c_dds_cos;   // set DUT input dds_cos as task input c_dds_cos
            dds_sin  <= c_dds_sin;   // set DUT input dds_sin as task input c_dds_sin
            #1;                      // wait to stabilize the logic
            
            // expected output 
            exp_i_out = c_adc_data * c_dds_cos;   
            exp_q_out = c_adc_data * c_dds_sin;
            
            @(posedge clk);  // wait for registered output to update
            #1;         
            
            if (i_out !== exp_i_out || q_out !== exp_q_out) begin
                $display("MIXER FAIL: c_adc_data=%0d c_dds_cos=%0d c_dds_sin=%0d i_out=%0d q_out=%0d exp_i_out=%0d exp_q_out=%0d", 
                          c_adc_data, c_dds_cos, c_dds_sin, i_out, q_out, exp_i_out, exp_q_out);
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,%0d,0", $time, c_adc_data, c_dds_cos, c_dds_sin, i_out, q_out, exp_i_out, exp_q_out);
            end else begin
                $fdisplay(fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,%0d,1", $time, c_adc_data, c_dds_cos, c_dds_sin, i_out, q_out, exp_i_out, exp_q_out);
            end
        end
    endtask
    
    // case tests
    integer k;
    initial begin
        adc_data = {IN_W{1'b0}};   // initialize adc_data as 0 
        dds_cos  = {IN_W{1'b0}};   // initialize dds_cos as 0 
        dds_sin  = {IN_W{1'b0}};   // initialize dds_sin as 0 
        #1;                        // wait for initialization to take effect
        
        @(posedge rst_n);
        @(posedge clk);
        
        // specific case tests
        check(0,0,0);  // test: 0 * 0 = 0, 0 * 0 = 0
        
            // positive: all 1 except first place is 0
        check({1'b0, {(IN_W-1){1'b1}}}, 0, 0);  // test: max pos adc_data * 0, max pos adc_data * 0
        check(1, {1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}});  // test: 1 * max pas dds_cos, 1 * max pas dds_sin
        check(0, {1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}});  // test: 0 * pos max dds_cos, 0 * max pos dds_sin
        check({1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}});  // test: max pos adc_data * max pos dds_cos, max pos adc_data * max pos dds_sin
        
            // negative: all 0 except first place is 1
        check({1'b1, {(IN_W-1){1'b0}}}, 0, 0);  // test: max neg adc_data * 0, max neg adc_data * 0
        check(1, {1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}});  // test: 1 * max neg dds_cos, 1 * max neg dds_sin
        check(0, {1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}});  // test: 0 * max neg dds_cos, 0 * max neg dds_sin
        check({1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}});  // test: max neg adc_data * max neg dds_cos, max neg adc_data * max neg dds_sin
        
        // random case tests * 1000
        for (k = 0; k < 1000; k = k + 1) begin   
            check ($random, $random, $random);  
        end
        
        $display("PASS"); // if all tests passed, print PASS
        $fclose(fd);
        $finish;
    end

endmodule
