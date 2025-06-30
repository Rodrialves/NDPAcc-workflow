`timescale 1ns/1ps
`include "constants.vh"

module fs_wrapper_tb;

    // Clock and reset
    reg clk;
    reg arst_i;

    // CPU interface
    reg cpu_valid;
    reg [`FE_ADDR_W-1:0] cpu_addr;
    reg [`FE_DATA_W-1:0] cpu_wdata;
    reg [`FE_STRB_W-1:0] cpu_wstrb;
    wire [`FE_DATA_W-1:0] cpu_rdata;
    wire cpu_rvalid;
    wire cpu_ready;

    // Accelerator control
    reg start;
    reg [`FE_ADDR_W-1:0] input_addr;
    reg [`FE_ADDR_W-1:0] output_addr;
    reg [`FE_ADDR_W-1:0] N;
    wire done;

    // Error flag
    wire error_flag;

    // Performance counters
    integer cpu_reads;
    integer acc_starts;
    integer cpu_read_requests;
    integer acc_read_requests;

    // Address ranges
    parameter CPU_READ_START = 22'h000000;
    parameter CPU_READ_END = 22'h07FFFF;
    parameter ACC_INPUT_START = 22'h080000;
    parameter ACC_OUTPUT_START = 22'h100000;

    // Instantiate DUT
    fs_wrapper u_dut (
        .clk(clk),
        .arst_i(arst_i),
        .cpu_valid(cpu_valid),
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
        .error_flag(error_flag)
    );

    // Clock generation (100MHz, 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset sequence
    initial begin
        arst_i = 1;
        #20;
        arst_i = 0;
    end

    // Waveform dumping
    initial begin
        $dumpfile("wave_fs_wrapper.vcd");
        $dumpvars(0, fs_wrapper_tb);
    end

    // CPU read process
    reg [31:0] rand_addr;
    reg [31:0] delay;
    initial begin
        cpu_valid = 0;
        cpu_addr = 0;
        cpu_wdata = 0;
        cpu_wstrb = 0;
        cpu_reads = 0;
        cpu_read_requests = 0;
        wait (!arst_i);
        forever begin
            delay = ($random % 4) + 7; // Random delay 7-10 cycles
            repeat (delay) @(posedge clk);
            rand_addr = ($random % (CPU_READ_END - CPU_READ_START + 1)) + CPU_READ_START;
            @(posedge clk);
            cpu_valid = 1;
            cpu_addr = rand_addr[`FE_ADDR_W-1:0];
            cpu_wstrb = 0;
            while (!cpu_ready) @(posedge clk);
            @(posedge clk);
            cpu_valid = 0;
            while (!cpu_rvalid) @(posedge clk);
            $display("CPU read from %h: %h at time %0t", cpu_addr, cpu_rdata, $time);
            cpu_reads = cpu_reads + 1;
        end
    end

    // Accelerator control process
    reg [31:0] offset;
    initial begin
        start = 0;
        input_addr = 0;
        output_addr = 0;
        N = 0;
        acc_starts = 0;
        acc_read_requests = 0;
        offset = 0;
        wait (!arst_i);
        forever begin
            input_addr = (ACC_INPUT_START + offset);
            output_addr = (ACC_OUTPUT_START + offset);
            N = 1;
            start = 1;
            acc_starts = acc_starts + 1;
            @(posedge clk);
            start = 0;
            wait (done);
            $display("Accelerator completed operation %0d at time %0t", acc_starts, $time);
            offset = offset + 4;
            if (offset >= (CPU_READ_END - CPU_READ_START)) offset = 0;
        end
    end

    // Monitor error_flag
    always @(posedge clk) begin
        if (error_flag) begin
            $display("ERROR: error_flag asserted at time %0t", $time);
            $display("Final counts: CPU reads=%0d, Accelerator starts=%0d", cpu_reads, acc_starts);
            $display("CPU read requests: %0d, Accelerator read requests: %0d", cpu_read_requests, acc_read_requests);
            $finish;
        end
    end

    // Count read requests
    always @(posedge clk) begin
        if (cpu_valid && cpu_ready && cpu_wstrb == 0) cpu_read_requests = cpu_read_requests + 1;
        if (u_dut.acc_valid && u_dut.acc_ready && u_dut.acc_wstrb == 0) acc_read_requests = acc_read_requests + 1;
    end

    // Run for a fixed duration
    initial begin
        #100000;
        $display("Simulation finished without errors.");
        $display("Final counts: CPU reads=%0d, Accelerator starts=%0d", cpu_reads, acc_starts);
        $display("CPU read requests: %0d, Accelerator read requests: %0d", cpu_read_requests, acc_read_requests);
        $finish;
    end

endmodule