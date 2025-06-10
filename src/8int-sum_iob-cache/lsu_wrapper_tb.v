`include "constants.vh"
`timescale 1ns / 1ps

module lsu_wrapper_tb;

    // Testbench parameters
    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz)
    parameter DATA_WIDTH = `FE_DATA_W;
    parameter ADDR_WIDTH = `FE_ADDR_W;
    parameter FIFO_DEPTH = `FIFO_DEPTH;

    // Testbench signals
    reg clk;
    reg reset;
    reg start;
    wire done;

    // Configuration inputs
    reg [ADDR_WIDTH-1:0] load_base_addr;
    reg [ADDR_WIDTH-1:0] store_base_addr;
    reg [ADDR_WIDTH-1:0] count;

    // Memory interface
    wire load_req;
    wire [ADDR_WIDTH-1:0] load_addr;
    reg [DATA_WIDTH-1:0] load_data;
    reg load_complete;
    wire store_req;
    wire [ADDR_WIDTH-1:0] store_addr;
    wire [DATA_WIDTH-1:0] store_data;
    reg store_complete;

    // Variables for verification
    reg [7:0] byte0;
    reg [7:0] byte1;
    reg [7:0] byte2;
    reg [7:0] byte3;
    reg [9:0] sum;
    reg [31:0] expected;

    // Instantiate the system_wrapper
    lsu_wrapper dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done),
        .load_base_addr(load_base_addr),
        .store_base_addr(store_base_addr),
        .count(count),
        .load_req(load_req),
        .load_addr(load_addr),
        .load_data(load_data),
        .load_complete(load_complete),
        .store_req(store_req),
        .store_addr(store_addr),
        .store_data(store_data),
        .store_complete(store_complete)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Memory response simulation
    reg [DATA_WIDTH-1:0] memory [0:10000]; // Small memory array for testing
    integer i;

    initial begin
        $dumpfile("lsu_wrapper_tb.vcd");
        $dumpvars(0, lsu_wrapper_tb);
    end
    
    always @(posedge clk) begin
        if (load_req) begin
            $display("Requested load from address 0x%h at time %t", load_addr, $time);
            load_data <= memory[load_addr[3:0]];
            load_complete <= 1;
            #(CLK_PERIOD);
            load_complete <= 0;
        end else begin
            load_complete <= 0;
        end
    end

    always @(posedge clk) begin
        if (store_req) begin
            $display("Stored data at address 0x%h: 0x%h (at time %t)", 
                     store_addr, store_data, $time);
            memory[store_addr[5:0]] <= store_data;
            store_complete <= 1;
        end else begin
            store_complete <= 0;
        end
    end

    // Test procedure
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        start = 0;
        load_base_addr = 22'h000000;
        store_base_addr = 22'h000010;
        count = 4;
        load_data = 0;
        load_complete = 0;
        store_complete = 0;

        // Initialize memory with test data
        memory[0] = 32'h01020000; // Sum = 0x03
        memory[1] = 32'h01010101; // Sum = 0x04
        memory[2] = 32'hFFFFFFFF; // Sum = 0xFF
        memory[3] = 32'h80808080; // Sum = 0x00 (overflow)
        memory[16] = 32'h00000000;
        memory[17] = 32'h00000000;
        memory[18] = 32'h00000000;
        memory[19] = 32'h00000000;

        // Reset sequence
        #(2*CLK_PERIOD);
        reset = 0;
        #(2*CLK_PERIOD);

        // Start the operation
        $display("Starting operation...");
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // Wait for completion
        wait (done);
        $display("Operation completed at time %t", $time);

        // Verify stored data
        $display("Verifying stored data...");
        for (i = 0; i < count; i = i + 1) begin
            byte0 = memory[i][7:0];
            byte1 = memory[i][15:8];
            byte2 = memory[i][23:16];
            byte3 = memory[i][31:24];
            sum = byte0 + byte1 + byte2 + byte3;
            expected = {22'b0, sum[9:0]}; // Matches accelerator output
            $display("Checking memory[0x%h]: expected 0x%h, got 0x%h", 
                     store_base_addr[5:0] + i, expected, memory[store_base_addr[5:0] + i]);
            if (memory[store_base_addr[5:0] + i] == expected) begin
                $display("PASS");
            end else begin
                $display("FAIL");
            end
        end

        // End simulation
        #(5*CLK_PERIOD);
        $display("Simulation finished.");
        $finish;
    end

endmodule