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
    
    //real theta;
    //real pi = 3.14159;
    integer amp = 2000; // Amplitude scaling factor for 12-bit signed
    
    integer tone_amp = 1000; // 1000 + 1000 = 2000 max, staying safely within 12-bit signed 
    
    // phase accumulators (represent continuous time t = nT)
    real phase_f1  = 0.0;  // Phase tracker for 20MHz desired signal
    real phase_f2  = 0.0;  // Phase tracker for 35MHz interference signal
    real phase_dds = 0.0;  // Phase tracker for 20MHz Local Oscillator (DDS)
    
    // Phase steps per clock cycle derived from: 2 * pi * (f / Fs)
    real step_f1   = 2.0 * 3.14159 * (20.0 / 100.0);  // 20MHz target signal step: 2 * pi * (20M / 100M) = 0.4 * pi
    real step_f2   = 2.0 * 3.14159 * (35.0 / 100.0);  // 35MHz interference step: 2 * pi * (35M / 100M) = 0.7 * pi
    real step_dds  = 2.0 * 3.14159 * (20.0 / 100.0);  // 20MHz Local Oscillator step: 2 * pi * (20M / 100M) = 0.4 * pi
    
    initial begin
        adc_data = {IN_W{1'b0}};   // initialize adc_data as 0 
        dds_cos  = {IN_W{1'b0}};   // initialize dds_cos as 0 
        dds_sin  = {IN_W{1'b0}};   // initialize dds_sin as 0 
        #1;                        // wait for initialization to take effect
        
        @(posedge rst_n);
        @(posedge clk);
        
        // specific case tests
        //check(0,0,0);  // test: 0 * 0 = 0, 0 * 0 = 0
        
            // positive: all 1 except first place is 0
        //check({1'b0, {(IN_W-1){1'b1}}}, 0, 0);  // test: max pos adc_data * 0, max pos adc_data * 0
        //check(1, {1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}});  // test: 1 * max pas dds_cos, 1 * max pas dds_sin
        //check(0, {1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}});  // test: 0 * pos max dds_cos, 0 * max pos dds_sin
        //check({1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}}, {1'b0, {(IN_W-1){1'b1}}});  // test: max pos adc_data * max pos dds_cos, max pos adc_data * max pos dds_sin
        
            // negative: all 0 except first place is 1
        //check({1'b1, {(IN_W-1){1'b0}}}, 0, 0);  // test: max neg adc_data * 0, max neg adc_data * 0
        //check(1, {1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}});  // test: 1 * max neg dds_cos, 1 * max neg dds_sin
        //check(0, {1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}});  // test: 0 * max neg dds_cos, 0 * max neg dds_sin
        //check({1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}}, {1'b1, {(IN_W-1){1'b0}}});  // test: max neg adc_data * max neg dds_cos, max neg adc_data * max neg dds_sin
        
        // 
        for (k = 0; k < 200; k = k + 1) begin   
            //theta = (k * 5.0) * (pi / 180.0);   
            // (k * 5) is angles in degrees, loop 72 times is 360 degrees. theta is convert from degrees to radians
            
            check(  // amplitude scale up to 12 bits., $rtoi is real to integer
                $rtoi(tone_amp * $sin(phase_f1) + tone_amp * $sin(phase_f2)),  // sum of 2 tones (20MHz + 35 MHz)
                
                // Local Oscillator 
                $rtoi(amp * $cos(phase_dds)),  // 20MHz cos
                $rtoi(amp * $sin(phase_dds))   // 20MHz sin
            );  
            
            phase_f1  = phase_f1  + step_f1;
            phase_f2  = phase_f2  + step_f2;
            phase_dds = phase_dds + step_dds;
        end       
        
        $display("PASS"); // if all tests passed, print PASS
        $fclose(fd);
        $finish;
    end

endmodule
