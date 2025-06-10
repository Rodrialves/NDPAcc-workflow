`timescale 1ns / 1ps

module load_store_unit_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // Clock period in ns
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 22;

    // Signals
    reg clk;
    reg reset;
    reg start;
    reg [ADDR_WIDTH-1:0] load_base_addr;
    reg [ADDR_WIDTH-1:0] store_base_addr;
    reg [21:0] count;
    wire done;
    wire load_req;
    wire [ADDR_WIDTH-1:0] load_addr;
    reg [DATA_WIDTH-1:0] load_data;
    reg load_complete;
    wire store_req;
    wire [ADDR_WIDTH-1:0] store_addr;
    wire [DATA_WIDTH-1:0] store_data;
    reg store_complete;
    wire accelerator_start;
    wire accelerator_done;

    // Memory array (16 words, 32-bit each)
    reg [DATA_WIDTH-1:0] memory [0:15];

    // Counters for verification
    integer load_req_count = 0;
    integer store_req_count = 0;
    integer acc_start_count = 0;
    integer acc_done_count = 0;

    // Instantiate the LSU
    load_store_unit uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .load_base_addr(load_base_addr),
        .store_base_addr(store_base_addr),
        .count(count),
        .done(done),
        .load_req(load_req),
        .load_addr(load_addr),
        .load_data(load_data),
        .load_complete(load_complete),
        .store_req(store_req),
        .store_addr(store_addr),
        .store_data(store_data),
        .store_complete(store_complete),
        .accelerator_start(accelerator_start),
        .accelerator_done(accelerator_done)
    );

    // Instantiate the accelerator
    accelerator acc (
        .clk_i(clk),
        .arst_i(reset),
        .start(accelerator_start),
        .data_in(load_data),
        .data_out(store_data),
        .done(accelerator_done)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Count load requests
    always @(posedge clk)
        if (load_req)
            load_req_count <= load_req_count + 1;

    // Count store requests
    always @(posedge clk)
        if (store_req)
            store_req_count <= store_req_count + 1;

    // Count accelerator starts
    always @(posedge clk)
        if (accelerator_start)
            acc_start_count <= acc_start_count + 1;

    // Count accelerator dones
    always @(posedge clk)
        if (accelerator_done)
            acc_done_count <= acc_done_count + 1;

    // Simulate memory response for load
    always @(posedge clk) begin
        if (load_req) begin
            #(CLK_PERIOD);
            load_data <= memory[load_addr[5:2]];
            load_complete <= 1;
            #(CLK_PERIOD);
            load_complete <= 0;
        end
    end

    // Simulate memory response for store
    always @(posedge clk) begin
        if (store_req) begin
            #(CLK_PERIOD);
            memory[store_addr[5:2]] <= store_data;
            store_complete <= 1;
            #(CLK_PERIOD);
            store_complete <= 0;
        end
    end

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        start = 0;
        load_base_addr = 32'h00000000;
        store_base_addr = 32'h00000004;
        count = 1;
        load_data = 0;
        load_complete = 0;
        store_complete = 0;

        // Initialize memory
        memory[0] = 32'h01020304; // Test value: bytes 0x04, 0x03, 0x02, 0x01

        // Reset sequence
        #(CLK_PERIOD*2);
        reset = 0;

        // Start the LSU
        #(CLK_PERIOD);
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // Wait for operation to complete
        wait(done);

        // Allow time for final memory write
        #(CLK_PERIOD*2);

        // Verify the stored value (expected sum = 0x01 + 0x02 + 0x03 + 0x04 = 0x0A)
        if (memory[1] == 32'h0000000A) begin
            $display("PASS: Correct value stored at memory[1].");
        end else begin
            $display("FAIL: Incorrect value stored at memory[1]. Expected 0x0000000A, got 0x%h", memory[1]);
        end

        // Verify operation counts
        if (load_req_count == 1 && store_req_count == 1 && acc_start_count == 1 && acc_done_count == 1) begin
            $display("PASS: Correct number of operations.");
        end else begin
            $display("FAIL: Incorrect number of operations. load_req=%d, store_req=%d, acc_start=%d, acc_done=%d",
                     load_req_count, store_req_count, acc_start_count, acc_done_count);
        end

        // End simulation
        #(CLK_PERIOD*2);
        $finish;
    end

    // Optional: Dump variables for waveform viewing
    initial begin
        $dumpfile("load_store_unit_tb.vcd");
        $dumpvars(0, load_store_unit_tb);
    end

endmodule