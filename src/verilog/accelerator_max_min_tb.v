`include "constants.vh"
`timescale 1ns / 1ps

module accelerator_max_min_tb;

    parameter CLK_PERIOD = 10;
    parameter NUM_WIDTH = 8;

    reg clk_i;
    reg arst_i;
    reg start;
    reg [31:0] data_sets [0:2];
    reg [NUM_WIDTH-1:0] exp_max, exp_min;
    reg [NUM_WIDTH-1:0] n0, n1, n2, n3;
    reg [NUM_WIDTH-1:0] temp_max, temp_min;
    reg [NUM_WIDTH-1:0] new_exp_max, new_exp_min;
    reg [31:0] data_in_local;
    integer num_sets;
    reg [31:0] data_in;
    wire [31:0] data_out;
    wire done;

    // DUT
    accelerator_max_min dut (
        .clk_i(clk_i),
        .arst_i(arst_i),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .done(done)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever # (CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    // Waveform dumping
    initial begin
        $dumpfile("wave_max_min.vcd");
        $dumpvars(0, accelerator_max_min_tb);
    end

    // Functions
    function [NUM_WIDTH-1:0] max_of_four;
        input [NUM_WIDTH-1:0] a, b, c, d;
        begin
            max_of_four = (a > b) ? a : b;
            max_of_four = (max_of_four > c) ? max_of_four : c;
            max_of_four = (max_of_four > d) ? max_of_four : d;
        end
    endfunction

    function [NUM_WIDTH-1:0] min_of_four;
        input [NUM_WIDTH-1:0] a, b, c, d;
        begin
            min_of_four = (a < b) ? a : b;
            min_of_four = (min_of_four < c) ? min_of_four : c;
            min_of_four = (min_of_four < d) ? min_of_four : d;
        end
    endfunction

    // Test procedure
    initial begin
        // Initialize
        data_in = 0;
        start = 0;
        arst_i = 1;
        #20;
        arst_i = 0;
        #(CLK_PERIOD);

        // Test case 1: Multiple sets
        $display("Test case 1: Multiple sets");
        data_sets[0] = 32'h01020304;
        data_sets[1] = 32'h05060708;
        data_sets[2] = 32'h090A0B0C;
        exp_max = 0;
        exp_min = {NUM_WIDTH{1'b1}};
        for (integer i = 0; i < 3; i = i + 1) begin
            data_in_local = data_sets[i];
            n0 = data_in_local[7:0];
            n1 = data_in_local[15:8];
            n2 = data_in_local[23:16];
            n3 = data_in_local[31:24];
            temp_max = max_of_four(n0, n1, n2, n3);
            temp_min = min_of_four(n0, n1, n2, n3);
            new_exp_max = (exp_max > temp_max) ? exp_max : temp_max;
            new_exp_min = (exp_min < temp_min) ? exp_min : temp_min;
            data_in = data_in_local;
            start = 1;
            #(CLK_PERIOD);
            start = 0;
            wait(done == 1);
            #(CLK_PERIOD);
            if (data_out[15:8] !== new_exp_max || data_out[7:0] !== new_exp_min)
                $display("Fail: set %d, expected max=%d, min=%d, got max=%d, min=%d", i, new_exp_max, new_exp_min, data_out[15:8], data_out[7:0]);
            else $display("Pass: set %d", i);
            exp_max = new_exp_max;
            exp_min = new_exp_min;
        end

        // Test case 2: All zeros
        $display("Test case 2: All zeros");
        arst_i = 1;
        #(CLK_PERIOD);
        arst_i = 0;
        #(CLK_PERIOD);
        exp_max = 0;
        exp_min = {NUM_WIDTH{1'b1}};
        data_in_local = 32'h00000000;
        n0 = data_in_local[7:0];
        n1 = data_in_local[15:8];
        n2 = data_in_local[23:16];
        n3 = data_in_local[31:24];
        temp_max = max_of_four(n0, n1, n2, n3);
        temp_min = min_of_four(n0, n1, n2, n3);
        new_exp_max = (exp_max > temp_max) ? exp_max : temp_max;
        new_exp_min = (exp_min < temp_min) ? exp_min : temp_min;
        data_in = data_in_local;
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        if (data_out[15:8] !== new_exp_max || data_out[7:0] !== new_exp_min)
            $display("Fail: all zeros, expected max=0, min=0, got max=%d, min=%d", data_out[15:8], data_out[7:0]);
        else $display("Pass: all zeros");

        // Test case 3: All maximum values (255)
        $display("Test case 3: All 255");
        arst_i = 1;
        #(CLK_PERIOD);
        arst_i = 0;
        #(CLK_PERIOD);
        exp_max = 0;
        exp_min = {NUM_WIDTH{1'b1}};
        data_in_local = 32'hFFFFFFFF;
        n0 = data_in_local[7:0];
        n1 = data_in_local[15:8];
        n2 = data_in_local[23:16];
        n3 = data_in_local[31:24];
        temp_max = max_of_four(n0, n1, n2, n3);
        temp_min = min_of_four(n0, n1, n2, n3);
        new_exp_max = (exp_max > temp_max) ? exp_max : temp_max;
        new_exp_min = (exp_min < temp_min) ? exp_min : temp_min;
        data_in = data_in_local;
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        if (data_out[15:8] !== 255 || data_out[7:0] !== 255)
            $display("Fail: all 255, expected max=255, min=255, got max=%d, min=%d", data_out[15:8], data_out[7:0]);
        else $display("Pass: all 255");

        // Test case 4: Mid-operation reset
        $display("Test case 4: Mid-operation reset");
        arst_i = 1;
        #(CLK_PERIOD);
        arst_i = 0;
        #(CLK_PERIOD);
        exp_max = 0;
        exp_min = {NUM_WIDTH{1'b1}};
        // First set
        data_in_local = 32'h01020304;
        n0 = data_in_local[7:0];
        n1 = data_in_local[15:8];
        n2 = data_in_local[23:16];
        n3 = data_in_local[31:24];
        temp_max = max_of_four(n0, n1, n2, n3);
        temp_min = min_of_four(n0, n1, n2, n3);
        new_exp_max = (exp_max > temp_max) ? exp_max : temp_max;
        new_exp_min = (exp_min < temp_min) ? exp_min : temp_min;
        data_in = data_in_local;
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        if (data_out[15:8] !== new_exp_max || data_out[7:0] !== new_exp_min)
            $display("Fail: after first set");
        else $display("Pass: first set");
        // Assert reset
        arst_i = 1;
        #(CLK_PERIOD);
        arst_i = 0;
        #(CLK_PERIOD);
        // Second set after reset
        exp_max = 0;
        exp_min = {NUM_WIDTH{1'b1}};
        data_in_local = 32'h05060708;
        n0 = data_in_local[7:0];
        n1 = data_in_local[15:8];
        n2 = data_in_local[23:16];
        n3 = data_in_local[31:24];
        temp_max = max_of_four(n0, n1, n2, n3);
        temp_min = min_of_four(n0, n1, n2, n3);
        new_exp_max = (exp_max > temp_max) ? exp_max : temp_max;
        new_exp_min = (exp_min < temp_min) ? exp_min : temp_min;
        data_in = data_in_local;
        start = 1;
        #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        if (data_out[15:8] !== new_exp_max || data_out[7:0] !== new_exp_min)
            $display("Fail: after reset and second set");
        else $display("Pass: after reset and second set");

        // Test case 5: Large dataset
        $display("Test case 5: Large dataset");
        arst_i = 1;
        #(CLK_PERIOD);
        arst_i = 0;
        #(CLK_PERIOD);
        exp_max = 0;
        exp_min = {NUM_WIDTH{1'b1}};
        num_sets = 1000;
        for (integer i = 0; i < num_sets; i = i + 1) begin
            data_in_local = $random;
            n0 = data_in_local[7:0];
            n1 = data_in_local[15:8];
            n2 = data_in_local[23:16];
            n3 = data_in_local[31:24];
            temp_max = max_of_four(n0, n1, n2, n3);
            temp_min = min_of_four(n0, n1, n2, n3);
            new_exp_max = (exp_max > temp_max) ? exp_max : temp_max;
            new_exp_min = (exp_min < temp_min) ? exp_min : temp_min;
            data_in = data_in_local;
            start = 1;
            #(CLK_PERIOD);
            start = 0;
            wait(done == 1);
            #(CLK_PERIOD);
            if (data_out[15:8] !== new_exp_max || data_out[7:0] !== new_exp_min)
                $display("Fail: set %d, expected max=%d, min=%d, got max=%d, min=%d", i, new_exp_max, new_exp_min, data_out[15:8], data_out[7:0]);
            else if (i % 100 == 0) $display("Pass: set %d", i);
            exp_max = new_exp_max;
            exp_min = new_exp_min;
        end
        $display("Large dataset completed");

        // Test case 6: Prolonged start signal
        $display("Test case 6: Prolonged start signal");
        arst_i = 1;
        #(CLK_PERIOD);
        arst_i = 0;
        #(CLK_PERIOD);
        exp_max = 0;
        exp_min = {NUM_WIDTH{1'b1}};
        data_in_local = 32'h01020304;
        n0 = data_in_local[7:0];
        n1 = data_in_local[15:8];
        n2 = data_in_local[23:16];
        n3 = data_in_local[31:24];
        temp_max = max_of_four(n0, n1, n2, n3);
        temp_min = min_of_four(n0, n1, n2, n3);
        new_exp_max = (exp_max > temp_max) ? exp_max : temp_max;
        new_exp_min = (exp_min < temp_min) ? exp_min : temp_min;
        data_in = data_in_local;
        start = 1;
        #(CLK_PERIOD); // first cycle
        // keep start high for extra cycles
        repeat (3) #(CLK_PERIOD);
        start = 0;
        wait(done == 1);
        #(CLK_PERIOD);
        if (data_out[15:8] !== new_exp_max || data_out[7:0] !== new_exp_min)
            $display("Fail: prolonged start");
        else $display("Pass: prolonged start");

        $display("All tests completed");
        $finish;
    end
endmodule