`include "constants.vh"

module lsu_wrapper (
    input clk,
    input reset,
    input start,
    output done,
    input [`FE_ADDR_W-1:0] load_base_addr,
    input [`FE_ADDR_W-1:0] store_base_addr,
    input [`FE_ADDR_W-1:0] count,
    output load_req,
    output [`FE_ADDR_W-1:0] load_addr,
    input [`FE_DATA_W-1:0] load_data,
    input load_complete,
    output store_req,
    output [`FE_ADDR_W-1:0] store_addr,
    output [`FE_DATA_W-1:0] store_data,
    input store_complete
);

    // Internal wires for accelerator interface
    wire accelerator_start;
    wire accelerator_done;
    wire [`FE_DATA_W-1:0] accelerator_data_in;
    wire [`FE_DATA_W-1:0] accelerator_data_out;

    // Instantiate load_store_unit
    load_store_unit lsu (
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
        .accelerator_data_in(accelerator_data_in),
        .accelerator_data_out(accelerator_data_out)
    );

    // Instantiate accelerator
    accelerator acc (
        .clk_i(clk),
        .arst_i(reset),
        .start(accelerator_start),
        .data_in(accelerator_data_in),
        .data_out(accelerator_data_out),
        .done(accelerator_done)
    );

endmodule