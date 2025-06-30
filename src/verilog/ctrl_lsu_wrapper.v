`include "constants.vh"

module ctrl_lsu_wrapper (
    // Clock and reset
    input  wire              clk,
    input  wire              arst,       // Active-high asynchronous reset
    // CPU-like interface (to be driven by testbench)
    input  wire              wire_valid_out,
    input  wire [`FE_ADDR_W-1:0] cpu_addr,
    input  wire [`FE_DATA_W-1:0] cpu_wdata,
    input  wire [`FE_STRB_W-1:0] cpu_wstrb,
    output wire [`FE_DATA_W-1:0] cpu_rdata,
    output wire              cpu_rvalid,
    output wire              cpu_ready,
    // Accelerator control signals
    input  wire              start,
    input  wire [`FE_ADDR_W-1:0] input_addr,
    input  wire [`FE_ADDR_W-1:0] output_addr,
    input  wire [`FE_ADDR_W-1:0] N,
    output wire              done,
    // Memory interface (to be driven by testbench)
    output wire              mem_valid,
    output wire [`FE_ADDR_W-1:0] mem_addr,
    output wire [`FE_DATA_W-1:0] mem_wdata,
    output wire [`FE_STRB_W-1:0] mem_wstrb,
    input  wire [`FE_DATA_W-1:0] mem_rdata,
    input  wire              mem_rvalid,
    input  wire              mem_ready
);

    // Internal wires to connect between bus controller and accelerator (LSU)
    wire              acc_valid;
    wire [`FE_ADDR_W-1:0] acc_addr;
    wire [`FE_DATA_W-1:0] acc_wdata;
    wire [`FE_STRB_W-1:0] acc_wstrb;
    wire [`FE_DATA_W-1:0] acc_rdata;
    wire              acc_rvalid;
    wire              acc_ready;

    // LSU interface wires
    wire              lsu_load_req;
    wire [`FE_ADDR_W-1:0] lsu_load_addr;
    wire [`FE_DATA_W-1:0] lsu_load_data;
    wire              lsu_load_complete;
    wire              lsu_store_req;
    wire [`FE_ADDR_W-1:0] lsu_store_addr;
    wire [`FE_DATA_W-1:0] lsu_store_data;
    wire              lsu_store_complete;

    // Map LSU signals to bus controller accelerator interface
    assign acc_valid = lsu_load_req | lsu_store_req;
    assign acc_addr = lsu_store_req ? lsu_store_addr : lsu_load_addr;
    assign acc_wdata = lsu_store_data;
    assign acc_wstrb = lsu_store_req ? 4'b1111 : 4'b0000;
    assign lsu_load_data = acc_rdata;
    assign lsu_load_complete = acc_rvalid;
    assign lsu_store_complete = acc_ready & lsu_store_req;

    // Instantiate the Bus Controller
    memory_controller mem_ctrl (
        // CPU side
        .cpu_valid   (wire_valid_out),
        .cpu_addr    (cpu_addr),
        .cpu_wdata   (cpu_wdata),
        .cpu_wstrb   (cpu_wstrb),
        .cpu_rdata   (cpu_rdata),
        .cpu_rvalid  (cpu_rvalid),
        .cpu_ready   (cpu_ready),
        // Accelerator side
        .acc_valid   (acc_valid),
        .acc_addr    (acc_addr),
        .acc_wdata   (acc_wdata),
        .acc_wstrb   (acc_wstrb),
        .acc_rdata   (acc_rdata),
        .acc_rvalid  (acc_rvalid),
        .acc_ready   (acc_ready),
        // Memory side (connected to module ports)
        .cache_valid (mem_valid),
        .cache_addr  (mem_addr),
        .cache_wdata (mem_wdata),
        .cache_wstrb (mem_wstrb),
        .cache_rdata (mem_rdata),
        .cache_rvalid(mem_rvalid),
        .cache_ready (mem_ready),
        // Clock and reset
        .clk       (clk),
        .arst_i      (arst)
    );

    // Instantiate the LSU Wrapper
    lsu_wrapper u_lsu_wrap (
        .clk(clk),
        .arst_i(arst),
        .start(start),
        .done(done),
        .load_base_addr(input_addr),
        .store_base_addr(output_addr),
        .count(N),
        .load_req(lsu_load_req),
        .load_addr(lsu_load_addr),
        .load_data(lsu_load_data),
        .load_complete(lsu_load_complete),
        .store_req(lsu_store_req),
        .store_addr(lsu_store_addr),
        .store_data(lsu_store_data),
        .store_complete(lsu_store_complete)
    );

    // // Debugging/Monitoring Logic (Simulation-only)
    // initial begin
    //     $monitor("[@%0t] CPU: valid=%b ready=%b rvalid=%b addr=%h wstrb=%h ACC: valid=%b ready=%b rvalid=%b addr=%h wstrb=%h ] done=%b",
    //             $time, wire_valid_out, cpu_ready, cpu_rvalid, cpu_addr, cpu_wstrb,
    //             acc_valid, acc_ready, acc_rvalid, acc_addr, acc_wstrb, done);
    // end

    // // Track outstanding read requests for error detection
    // integer outstanding_reads;
    // always @(posedge clk or posedge arst) begin
    //     if (arst) begin
    //         outstanding_reads <= 0;
    //         error_flag <= 0;
    //     end else begin
    //         // If a read request is accepted (valid & ready with no write strobes)
    //         if (mem_valid && mem_ready && mem_wstrb == {`FE_STRB_W{1'b0}}) begin
    //             outstanding_reads <= outstanding_reads + 1;
    //         end
    //         // If a read response is valid (memory returning data)
    //         if (mem_rvalid) begin
    //             if (outstanding_reads > 0)
    //                 outstanding_reads <= outstanding_reads - 1;
    //         end
    //         // Check for error conditions:
    //         // 1. Too many outstanding reads (overflow)
    //         if (outstanding_reads > 4) begin
    //             $display("ERROR: Outstanding read requests overflow at time %0t", $time);
    //             error_flag <= 1'b1;
    //         end
    //         // 2. Read response with no request (underflow)
    //         if (mem_rvalid && outstanding_reads == 0) begin
    //             $display("ERROR: Read response with no pending request at time %0t", $time);
    //             error_flag <= 1'b1;
    //         end
    //     end
    // end

endmodule