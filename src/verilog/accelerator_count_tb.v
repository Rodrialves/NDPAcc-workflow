`include "constants.vh"
`timescale 1ns / 1ps

module accelerator_count_tb;

    parameter CLK_PERIOD = 10;
    parameter NUM_WIDTH = 8;

    reg clk_i;
    reg arst_i;
    reg start;
    reg [31:0] data_in;
    wire [31:0] data_out;
    wire done;
    reg [31:0] exp_count;
    reg [NUM_WIDTH-1:0] n0, n1, n2, n3;
    reg is_even0, is_even1, is_even2, is_even3;
    integer i;
    reg [31:0] data_sets [0:2];
    integer num_sets;
    reg [31:0] din;

    // DUT
    accelerator_property dut (
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
        $dumpfile("wave_count.vcd");
        $dumpvars(0, accelerator_count_tb);
    end

    // Test procedure
    initial begin
        // Initialize
        arst_i = 1;
        start = 0;
        data_in = 0;
        #20 arst_i = 0;
        #(CLK_PERIOD);

        // Test case 1: Multiple sets
        begin
            exp_count = 0;
            data_sets[0] = 32'h01020304; // 1(odd),2(even),3(odd),4(even) -> 2 even
            data_sets[1] = 32'h05060708; // 5(odd),6(even),7(odd),8(even) -> 2 even
            data_sets[2] = 32'h090A0B0C; // 9(odd),10(even),11(odd),12(even) -> 2 even

            $display("Test case 1: Multiple sets");
            for (integer i = 0; i < 3; i++) begin
                n0 = data_sets[i][NUM_WIDTH-1:0];
                n1 = data_sets[i][2*NUM_WIDTH-1:NUM_WIDTH];
                n2 = data_sets[i][3*NUM_WIDTH-1:2*NUM_WIDTH];
                n3 = data_sets[i][4*NUM_WIDTH-1:3*NUM_WIDTH];

                is_even0 = ~n0[0];
                is_even1 = ~n1[0];
                is_even2 = ~n2[0];
                is_even3 = ~n3[0];

                exp_count = exp_count + is_even0 + is_even1 + is_even2 + is_even3;

                data_in = data_sets[i];
                start = 1;
                #(CLK_PERIOD);
                start = 0;
                wait(done == 1);
                #(CLK_PERIOD);
                if (data_out !== exp_count)
                    $display("Fail: set %d, expected count=%d, got %d", i, exp_count, data_out);
                else $display("Pass: set %d", i);
            end
        end

        // Test case 2: All even numbers
        begin
            arst_i = 1;
            #(CLK_PERIOD); arst_i = 0;
            #(CLK_PERIOD);

            exp_count = 0;
            data_in = 32'h02040608; // 2,4,6,8 -> all even

            exp_count = exp_count + 4; // All four are even

            $display("Test case 2: All even numbers");
            start = 1;
            #(CLK_PERIOD);
            start = 0;
            wait(done == 1);
            #(CLK_PERIOD);
            if (data_out !== exp_count)
                $display("Fail: expected count=4, got %d", data_out);
            else $display("Pass: all even");
        end

        // Test case 3: All odd numbers
        begin
            arst_i = 1;
            #(CLK_PERIOD); arst_i = 0;
            #(CLK_PERIOD);

            exp_count = 0;
            data_in = 32'h01030507; // 1,3,5,7 -> all odd

            exp_count = exp_count + 0; // None are even

            $display("Test case 3: All odd numbers");
            start = 1;
            #(CLK_PERIOD);
            start = 0;
            wait(done == 1);
            #(CLK_PERIOD);
            if (data_out !== exp_count)
                $display("Fail: expected count=0, got %d", data_out);
            else $display("Pass: all odd");
        end

        // Test case 4: Mid-operation reset
        begin
            arst_i = 1;
            #(CLK_PERIOD); arst_i = 0;
            #(CLK_PERIOD);

            exp_count = 0;

            $display("Test case 4: Mid-operation reset");
            // First set
            data_in = 32'h01020304; // 2 even
            start = 1;
            #(CLK_PERIOD);
            start = 0;

            exp_count = exp_count + 2;

            wait(done === 1);
            #(CLK_PERIOD);
            if (data_out !== 2)
                $display("Fail: after first set");
            else $display("Pass: first set");

            // Assert reset
            arst_i = 1;
            #(CLK_PERIOD);
            arst_i = 0;
            #(CLK_PERIOD);

            // Second set after reset
            exp_count = 0;
            data_in = 32'h05060708; // 2 even
            start = 1;
            #(CLK_PERIOD);
            start = 0;
            exp_count = exp_count + 2;

            wait(done === 1);
            #(CLK_PERIOD);
            if (data_out !== 2)
                $display("Fail: after reset and second set");
            else $display("Pass: after reset and second set");
        end

        // Test case 5: Large dataset
        begin
            arst_i = 1;
            #(CLK_PERIOD); arst_i = 0;
            #(CLK_PERIOD);

            exp_count = 0;
            num_sets = 1000;

            $display("Test case 5: Large dataset");
            for (integer i = 0; i < num_sets; i++) begin
                din = $random;
                data_in = din;

                n0 = din[NUM_WIDTH-1:0];
                n1 = din[2*NUM_WIDTH-1:NUM_WIDTH];
                n2 = din[3*NUM_WIDTH-1:2*NUM_WIDTH];
                n3 = din[4*NUM_WIDTH-1:3*NUM_WIDTH];

                is_even0 = ~n0[0];
                is_even1 = ~n1[0];
                is_even2 = ~n2[0];
                is_even3 = ~n3[0];

                exp_count = exp_count + is_even0 + is_even1 + is_even2 + is_even3;

                start = 1;
                #(CLK_PERIOD);
                start = 0;

                wait(done === 1);
                #(CLK_PERIOD);
                if (data_out !== exp_count)
                    $display("Fail: set %d, expected count=%d, got %d", i, exp_count, data_out);
                else if (i % 100 == 0) $display("Pass: set %d", i);
            end
            $display("Large dataset completed");
        end

        // Test case 6: Prolonged start signal
        begin
            arst_i = 1;
            #(CLK_PERIOD); arst_i = 0;
            #(CLK_PERIOD);

            exp_count = 0;
            data_in = 32'h01020304; // 2 even

            exp_count = exp_count + 2;

            $display("Test case 6: Prolonged start signal");
            start = 1;
            #(CLK_PERIOD);
            // Keep start high for extra cycles
            repeat (3) @(posedge clk_i);
            start = 0;


            wait(done === 1);
            #(CLK_PERIOD);
            if (data_out !== exp_count)
                $display("Fail: after prolonged start");
            else $display("Pass: prolonged start");
        end

        $display("All tests completed");
        $finish;
    end

endmodule