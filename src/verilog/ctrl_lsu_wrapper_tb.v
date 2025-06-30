`timescale 1ns/1ps

`include "constants.vh"

module ctrl_lsu_wrapper_tb;
    // Testbench signals
    reg clk;
    reg arst;
    reg cpu_valid;
    reg [`FE_ADDR_W-1:0] cpu_addr;
    reg [`FE_DATA_W-1:0] cpu_wdata;
    reg [`FE_STRB_W-1:0] cpu_wstrb;
    reg start;
    reg [`FE_ADDR_W-1:0] input_addr;
    reg [`FE_ADDR_W-1:0] output_addr;
    reg [`FE_ADDR_W-1:0] N;
    reg [`FE_DATA_W-1:0] mem_rdata;
    reg mem_rvalid;
    reg mem_ready;

    wire [`FE_DATA_W-1:0] cpu_rdata;
    wire cpu_rvalid;
    wire cpu_ready;
    wire done;
    wire mem_valid;
    wire [`FE_ADDR_W-1:0] mem_addr;
    wire [`FE_DATA_W-1:0] mem_wdata;
    wire [`FE_STRB_W-1:0] mem_wstrb;
    wire error_flag;

    // Memory model parameters
    parameter MEM_SIZE = 1024;
    parameter CLK_PERIOD = 10; // 10ns clock period
    reg [`FE_DATA_W-1:0] memory [0:MEM_SIZE-1];
    reg [`FE_ADDR_W-1:0] read_addr;
    reg read_pending;

    integer i;

    // Instantiate the DUT
    ctrl_lsu_wrapper dut (
        .clk(clk),
        .arst(arst),
        .wire_valid_out(cpu_valid),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_wstrb(cpu_wstrb),
        .cpu_rdata(cpu_rdata),
        .cpu_rvalid(cpu_rvalid),
        .cpu_ready(cpu_ready),
        .start(start),
        .input_addr(input_addr),
        .output_addr(output_addr),
        .N(N),
        .done(done),
        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_rvalid(mem_rvalid),
        .mem_ready(mem_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk; // 10ns period
    end

    // Reset and stimulus
    initial begin
        // Initialize signals
        arst = 1;
        cpu_valid = 0;
        cpu_addr = 0;
        cpu_wdata = 0;
        cpu_wstrb = 0;
        start = 0;
        input_addr = 0;
        output_addr = 0;
        N = 0;
        mem_rdata = 0;
        mem_rvalid = 0;
        mem_ready = 1; // Memory always ready
        read_pending = 0;

        // Initialize memory with some data
        for (i = 0; i < MEM_SIZE; i=i+1) begin
            memory[i] = i; // Simple pattern
        end

        // Apply reset
        #(CLK_PERIOD*2);
        arst = 0;

        // Test 1: CPU write
        @(posedge clk);
        cpu_valid = 1;
        cpu_addr = 32'h00000010;
        cpu_wdata = 32'hDEADBEEF;
        cpu_wstrb = 4'b1111;
        wait (cpu_ready);
        @(posedge clk);
        cpu_valid = 0;

        // Test 2: CPU read
        #(CLK_PERIOD);
        @(posedge clk);
        cpu_valid = 1;
        cpu_addr = 32'h00000010;
        cpu_wstrb = 4'b0000;
        wait (cpu_rvalid);
        @(posedge clk);
        if (cpu_rdata == 32'hDEADBEEF)
            $display("CPU read test passed: rdata = %h", cpu_rdata);
        else
            $display("CPU read test failed: rdata = %h", cpu_rdata);
        cpu_valid = 0;

        // Test 3: Accelerator operation
        #(CLK_PERIOD*2);
        @(posedge clk);
        input_addr = 32'h00000020;
        output_addr = 32'h00000040;
        N = 4; // Process 4 words
        start = 1;
        @(posedge clk);
        start = 0;
        wait (done);
        $display("Accelerator operation completed");

        // Check accelerator results
        @(posedge clk);
        if (memory[32'h00000040>>2] == memory[32'h00000020>>2] &&
            memory[32'h00000044>>2] == memory[32'h00000024>>2] &&
            memory[32'h00000048>>2] == memory[32'h00000028>>2] &&
            memory[32'h0000004C>>2] == memory[32'h0000002C>>2])
            $display("Accelerator data transfer test passed");
        else
            $display("Accelerator data transfer test failed");

        // End simulation
        #(CLK_PERIOD);
        if (error_flag)
            $display("Simulation ended with errors");
        else
            $display("Simulation completed successfully");
        $finish;
    end

    // Memory model
    always @(posedge clk) begin
        if (arst) begin
            mem_rvalid <= 0;
            read_pending <= 0;
        end else begin
            // Handle read requests
            if (mem_valid && mem_ready && mem_wstrb == 0) begin
                if (mem_addr >> 2 < MEM_SIZE) begin
                    read_addr <= mem_addr;
                    read_pending <= 1;
                end else begin
                    $display("ERROR: Read address %h out of bounds", mem_addr);
                end
            end else begin
                read_pending <= 0;
            end

            // Provide read data
            if (read_pending) begin
                mem_rvalid <= 1;
                mem_rdata <= memory[read_addr >> 2];
            end else begin
                mem_rvalid <= 0;
            end

            // Handle write requests
            if (mem_valid && mem_ready && mem_wstrb != 0) begin
                if (mem_addr >> 2 < MEM_SIZE) begin
                    for (i = 0; i < `FE_STRB_W; i=i+1) begin
                        if (mem_wstrb[i]) begin
                            memory[mem_addr >> 2][i*8 +: 8] <= mem_wdata[i*8 +: 8];
                        end
                    end
                    $display("Memory write: addr=%h, data=%h, wstrb=%b", mem_addr, mem_wdata, mem_wstrb);
                end else begin
                    $display("ERROR: Write address %h out of bounds", mem_addr);
                end
            end
        end
    end

    // // Monitor for debugging
    // initial begin
    //     $monitor("[@%0t] CPU: valid=%b ready=%b rvalid=%b addr=%h rdata=%h ACC: done=%b MEM: valid=%b ready=%b rvalid=%b addr=%h",
    //              $time, cpu_valid, cpu_ready, cpu_rvalid, cpu_addr, cpu_rdata, done,
    //              mem_valid, mem_ready, mem_rvalid, mem_addr);
    // end

endmodule