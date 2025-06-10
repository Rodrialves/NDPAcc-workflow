`timescale 1ns / 1ps

`include "constants.vh"

module accelerator_tb;

    // Parameters
    localparam NUM_WIDTH = `FE_DATA_W / 4; // 8 bits
    localparam CLK_PERIOD = 10; // 10ns clock period

    // Signals
    reg                  clk_i;
    reg                  arst_i;
    reg                  start;
    reg  [`FE_DATA_W-1:0] data_in;
    wire [`FE_DATA_W-1:0] data_out;
    wire                 done;

    // Instantiate the accelerator
    accelerator dut (
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
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    initial begin
        
        $dumpfile("wave_acc.vcd"); // Set the VCD file name
        $dumpvars(0, accelerator_tb); // Dump all signals in the testbench
    end

    initial begin
        $display("Annotating SDF file for timing simulation");
        $sdf_annotate("acc.sdf", dut);
    end

    // Test procedure
    initial begin
        // Initialize signals
        arst_i = 1;
        start = 0;
        data_in = 0;
        #20;
        arst_i = 0;
        #10;

        // Test case 1: Small numbers (1 + 2 + 3 + 4 = 10)
        $display("Test Case 1: Small numbers (1 + 2 + 3 + 4 = 10)");
        data_in = {8'd4, 8'd3, 8'd2, 8'd1}; // byte3, byte2, byte1, byte0
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done == 1);
        #CLK_PERIOD;
        if (data_out[9:0] == 10 && data_out[31:10] == 0) begin
            $display("PASS: Sum = %d, data_out = %h", data_out[9:0], data_out);
        end else begin
            $display("FAIL: Expected sum = 10, got %d, data_out = %h", data_out[9:0], data_out);
        end
        #10;

        // Test case 2: Overflow case (255 + 255 + 255 + 255 = 1020)
        $display("Test Case 2: Overflow (255 + 255 + 255 + 255 = 1020)");
        data_in = {8'd255, 8'd255, 8'd255, 8'd255};
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done == 1);
        #CLK_PERIOD;
        if (data_out[9:0] == 1020 && data_out[31:10] == 0) begin
            $display("PASS: Sum = %d, data_out = %h", data_out[9:0], data_out);
        end else begin
            $display("FAIL: Expected sum = 1020, got %d, data_out = %h", data_out[9:0], data_out);
        end
        #10;

        // Test case 3: Zeros (0 + 0 + 0 + 0 = 0)
        $display("Test Case 3: Zeros (0 + 0 + 0 + 0 = 0)");
        data_in = {8'd0, 8'd0, 8'd0, 8'd0};
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done == 1);
        #CLK_PERIOD;
        if (data_out[9:0] == 0 && data_out[31:10] == 0) begin
            $display("PASS: Sum = %d, data_out = %h", data_out[9:0], data_out);
        end else begin
            $display("FAIL: Expected sum = 0, got %d, data_out = %h", data_out[9:0], data_out);
        end
        #10;

        // Test case 4: Mixed values (100 + 50 + 25 + 75 = 250)
        $display("Test Case 4: Mixed (100 + 50 + 25 + 75 = 250)");
        data_in = {8'd75, 8'd25, 8'd50, 8'd100};
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done == 1);
        #CLK_PERIOD;
        if (data_out[9:0] == 250 && data_out[31:10] == 0) begin
            $display("PASS: Sum = %d, data_out = %h", data_out[9:0], data_out);
        end else begin
            $display("FAIL: Expected sum = 250, got %d, data_out = %h", data_out[9:0], data_out);
        end
        #10;

        // End simulation
        $display("All tests completed");
        $finish;
    end

endmodule