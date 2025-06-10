`include "constants.vh"

module load_store_unit (
    input clk,
    input reset,
    input start,
    output reg done,

    // Configuration inputs
    input [`FE_ADDR_W-1:0] load_base_addr,
    input [`FE_ADDR_W-1:0] store_base_addr,
    input [`FE_ADDR_W-1:0] count,

    // Memory interface
    output reg load_req,
    output reg [`FE_ADDR_W-1:0] load_addr,
    input [`FE_DATA_W-1:0] load_data,
    input load_complete,
    output reg store_req,
    output reg [`FE_ADDR_W-1:0] store_addr,
    output reg [`FE_DATA_W-1:0] store_data,
    input store_complete,

    // Accelerator interface
    output reg accelerator_start,
    input accelerator_done,
    input [`FE_DATA_W-1:0] accelerator_data_out,
    output [`FE_DATA_W-1:0] accelerator_data_in
);

    // FIFO signals
    reg load_fifo_write_en;
    reg [`FE_DATA_W-1:0] load_fifo_data_in;
    wire load_fifo_full;
    wire load_fifo_empty;
    reg load_fifo_read_en;
    wire [`FE_DATA_W-1:0] load_fifo_data_out;

    reg store_fifo_write_en;
    reg [`FE_DATA_W-1:0] store_fifo_data_in;
    wire store_fifo_full;
    wire store_fifo_empty;
    reg store_fifo_read_en;
    wire [`FE_DATA_W-1:0] store_fifo_data_out;

    // Instantiate load and store FIFOs
    fifo load_fifo (
        .clk(clk),
        .rst_n(~reset),
        .w_en(load_fifo_write_en),
        .data_in(load_fifo_data_in),
        .r_en(load_fifo_read_en),
        .data_out(load_fifo_data_out),
        .empty(load_fifo_empty),
        .full(load_fifo_full)
    );

    fifo store_fifo (
        .clk(clk),
        .rst_n(~reset),
        .w_en(store_fifo_write_en),
        .data_in(store_fifo_data_in),
        .r_en(store_fifo_read_en),
        .data_out(store_fifo_data_out),
        .empty(store_fifo_empty),
        .full(store_fifo_full)
    );

    // Loader state machine states
    localparam LOADER_IDLE      = 2'd0;
    localparam LOADER_LOAD_REQ  = 2'd1;
    localparam LOADER_LOAD_WAIT = 2'd2;

    // Storer state machine states
    localparam STORER_IDLE      = 2'd0;
    localparam STORER_DEQUEUE   = 2'd1;
    localparam STORER_STORE_REQ = 2'd2;
    localparam STORER_STORE_WAIT= 2'd3;

    reg [1:0] loader_state, storer_state;
    reg [31:0] load_counter, store_counter;
    reg [`FE_ADDR_W-1:0] current_load_addr, current_store_addr;

    // Loader state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            loader_state <= LOADER_IDLE;
            load_req <= 0;
            load_counter <= 0;
            current_load_addr <= 0;
            load_fifo_write_en <= 0;
        end else begin
            case (loader_state)
                LOADER_IDLE: begin
                    if (start && load_counter < count) begin
                        current_load_addr <= load_base_addr;
                        loader_state <= LOADER_LOAD_REQ;
                    end
                    load_fifo_write_en <= 0;
                end
                LOADER_LOAD_REQ: begin
                    if (!load_fifo_full) begin
                        load_req <= 1;
                        load_addr <= current_load_addr;
                        loader_state <= LOADER_LOAD_WAIT;
                    end
                end
                LOADER_LOAD_WAIT: begin
                    if (load_complete) begin
                        load_req <= 0;
                        load_fifo_data_in <= load_data;
                        load_fifo_write_en <= 1;
                        if (load_counter < count - 1) begin
                            current_load_addr <= current_load_addr + 1;
                            load_counter <= load_counter + 1;
                            loader_state <= LOADER_LOAD_REQ;
                        end else begin
                            load_counter <= load_counter + 1;
                            loader_state <= LOADER_IDLE;
                        end
                    end else begin
                        load_fifo_write_en <= 0;
                    end
                end
                default: loader_state <= LOADER_IDLE;
            endcase
        end
    end

    // Storer state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            storer_state <= STORER_IDLE;
            store_req <= 0;
            store_counter <= 0;
            current_store_addr <= 0;
            store_fifo_read_en <= 0;
            done <= 0;
        end else begin
            case (storer_state)
                STORER_IDLE: begin
                    if (!store_fifo_empty && store_counter < count) begin
                        storer_state <= STORER_DEQUEUE;
                        if (store_counter == 0) begin
                            current_store_addr <= store_base_addr;
                        end
                    end
                end
                STORER_DEQUEUE: begin
                    store_fifo_read_en <= 1;
                    storer_state <= STORER_STORE_REQ;
                end
                STORER_STORE_REQ: begin
                    store_fifo_read_en <= 0;
                    store_data <= store_fifo_data_out;
                    store_addr <= current_store_addr;
                    store_req <= 1;
                    storer_state <= STORER_STORE_WAIT;
                end
                STORER_STORE_WAIT: begin
                    if (store_complete) begin
                        store_req <= 0;
                        current_store_addr <= current_store_addr + 1;
                        store_counter <= store_counter + 1;
                        if (store_counter < count - 1) begin
                            storer_state <= STORER_IDLE;
                        end else begin
                            done <= 1;
                            storer_state <= STORER_IDLE;
                        end
                    end
                end
                default: storer_state <= STORER_IDLE;
            endcase
        end
    end

    // Accelerator control logic
    reg accelerator_active;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accelerator_start <= 0;
            load_fifo_read_en <= 0;
            store_fifo_write_en <= 0;
            accelerator_active <= 0;
        end else begin
            load_fifo_read_en <= 0;
            store_fifo_write_en <= 0;

            if (!load_fifo_empty && !accelerator_active) begin
                load_fifo_read_en <= 1;
                accelerator_start <= 1;
                accelerator_active <= 1;
            end else if (accelerator_active && accelerator_done) begin
                store_fifo_data_in <= accelerator_data_out;
                store_fifo_write_en <= 1;
                accelerator_start <= 0;
                accelerator_active <= 0;
            end
        end
    end

    // Connect load FIFO output to accelerator input
    assign accelerator_data_in = load_fifo_data_out;

endmodule