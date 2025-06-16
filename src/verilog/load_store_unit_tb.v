`include "constants.vh"
`timescale 1ns / 1ps

module load_store_unit_tb;

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

    // Accelerator interface
    wire accelerator_start;
    wire [DATA_WIDTH-1:0] accelerator_data_out;
    wire [DATA_WIDTH-1:0] accelerator_data_in;
    wire accelerator_done;

    // Instantiate the load_store_unit
    load_store_unit dut (
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
        .store_complete(store_complete),
        .accelerator_start(accelerator_start),
        .accelerator_done(accelerator_done),
        .accelerator_data_out(accelerator_data_out),
        .accelerator_data_in(accelerator_data_in)
    );

    // Instantiate the accelerator
    accelerator acc (
        .clk_i(clk),
        .arst_i(reset),
        .start(accelerator_start),
        .data_in(accelerator_data_in),
        .data_out(accelerator_data_out),
        .done(accelerator_done)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Memory response simulation
    reg [DATA_WIDTH-1:0] memory [0:10000]; // Small memory array for testing
    integer i;

    // Variables for verification (moved to module level)
    reg [7:0] byte0;
    reg [7:0] byte1;
    reg [7:0] byte2;
    reg [7:0] byte3;
    reg [9:0] sum;
    reg [DATA_WIDTH-1:0] result;
    reg [31:0] expected;
    reg [5:0] clock_count;

    initial begin
        $dumpfile("wave_lsu.vcd"); // Set the VCD file name
        $dumpvars(0, load_store_unit_tb); // Dump all signals in the testbench
    end

    always @(posedge clk) begin
        if (load_req) begin
            $display("Requested load from address 0x%h at time %t", load_addr, $time);
            load_data <= memory[load_addr[3:0]]; // Also fix data source, addressed below
            load_complete <= 1;
            #(CLK_PERIOD); // Simulate load delay
            load_complete <= 0;
        end else begin
            load_complete <= 0;
        end
    end

    
    // Simulate memory write (store)
    always @(posedge clk) begin
        if (store_req) begin
            $display("Stored data at address 0x%h: 0x%h (at time %t) and store_req=%b", 
                     store_addr, store_data, $time, store_req);
            memory[store_addr[5:0]] <= store_data[31:0];
            $display("Memory[0x%h] = 0x%h", store_addr[5:0], memory[store_addr[5:0]]);
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
        memory[0] = 32'h01020000;
        memory[1] = 32'h01010101;
        memory[2] = 32'hFFFFFFFF;
        memory[3] = 32'h80808080;
        memory[16] = 32'h00000000; // Placeholder for store results
        memory[17] = 32'h00000000;
        memory[18] = 32'h00000000;
        memory[19] = 32'h00000000;

        // Reset sequence
        #(2*CLK_PERIOD);
        reset = 0;
        #(2*CLK_PERIOD);

        // Start the load-store operation
        $display("Starting load-store operation...");
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // Wait for completion
        wait (done);
        $display("Load-store operation completed at time %t", $time);

        // Verify stored data
        $display("Verifying stored data...");
        for (i = 0; i < count; i = i + 1) begin
            byte0 = memory[i][7:0];
            byte1 = memory[i][15:8];
            byte2 = memory[i][23:16];
            byte3 = memory[i][31:24];
            result = memory[store_base_addr[5:0]+i];
            sum = byte0 + byte1 + byte2 + byte3;
            expected = {24'b0, sum};
            $display("Checking memory[0x%h]: byte0=%h, byte1=%h, byte2=%h, byte3=%h, sum=%h, expected=%h", 
                     store_base_addr + i, byte0, byte1, byte2, byte3, result, expected);
            // if (memory[store_base_addr + i] == expected) begin
            //     $display("PASS: memory[0x%h] = 0x%h", store_base_addr + i*4, memory[4 + i]);
            // end else begin
            //     $display("FAIL: memory[0x%h] = 0x%h, expected 0x%h", 
            //              store_base_addr + i*4, memory[4 + i], expected);
            // end
        end

        // Check accelerator activation counts
        // $display("Accelerator start count: %d", acc_start_count);
        // $display("Accelerator done count: %d", acc_done_count);
        // if (acc_start_count == count && acc_done_count == count) begin
        //     $display("PASS: Accelerator activated correctly.");
        // end else begin
        //     $display("FAIL: Accelerator activation mismatch.");
        // end

        // End simulation
        #(5*CLK_PERIOD);
        $display("Simulation finished.");
        $finish;
    end

    // Counters for accelerator start and done
    integer acc_start_count = 0;
    integer acc_done_count = 0;
    always @(posedge clk) begin
        if (accelerator_start) acc_start_count <= acc_start_count + 1;
        if (accelerator_done) acc_done_count <= acc_done_count + 1;
    end

    // Monitor signals for debugging
    // initial begin
    //     $monitor("Time=%t | State: loader=%0d, storer=%0d | load_req=%b, store_req=%b, acc_start=%b, done=%b",
    //              $time, dut.loader_state, dut.storer_state, load_req, store_req, accelerator_start, done);
    // end


endmodule