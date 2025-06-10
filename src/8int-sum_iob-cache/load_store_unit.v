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
    parameter LOADER_IDLE      = 3'd0;
    parameter LOADER_LOAD_REQ  = 3'd1;
    parameter LOADER_LOAD_WAIT = 3'd2;

    // Storer state machine states
    parameter STORER_IDLE      = 3'd0;
    parameter STORER_START     = 3'd1; // New state for starting the storer
    parameter STORER_DEQUEUE   = 3'd2;
    parameter STORER_STORE_REQ = 3'd3;
    parameter STORER_STORE_WAIT= 3'd4;

    reg [2:0] loader_state, storer_state, acc_state;
    reg [`FE_ADDR_W:0] load_counter, store_counter;
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
                    if (start) begin
                        current_load_addr <= load_base_addr;
                        load_counter <= 0;
                        loader_state <= LOADER_LOAD_REQ;
                    end
                    load_fifo_write_en <= 0;
                end
                LOADER_LOAD_REQ: begin
                    load_fifo_write_en <= 0;
                    if (!load_fifo_full) begin
                        $display("In LOADER_LOAD_REQ");
                        load_req <= 1;
                        load_addr <= current_load_addr;
                        loader_state <= LOADER_LOAD_WAIT;
                    end
                end
                LOADER_LOAD_WAIT: begin
                    load_req <= 0;
                    $display("In LOADER_LOAD_WAIT, load_complete = %b", load_fifo_write_en);
                    if (load_complete) begin
                        load_fifo_data_in <= load_data;
                        load_fifo_write_en <= 1;
                        if (load_counter < count - 22'b1) begin
                            current_load_addr <= current_load_addr + 1;
                            load_counter <= load_counter + 1;
                            loader_state <= LOADER_LOAD_REQ;
                        end else begin
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
        end
        else begin
            case (storer_state)
                STORER_IDLE: begin
                    if (start) begin
                        current_store_addr <= store_base_addr;
                        store_counter <= 0;
                        $display("Storer started with base address: %h", current_store_addr);
                        storer_state <= STORER_START;
                    end
                    done <= 0;
                end
                STORER_START: begin
                    if (!store_fifo_empty) begin
                        storer_state <= STORER_DEQUEUE;
                    end
                end
                STORER_DEQUEUE: begin
                    store_fifo_read_en <= 1;
                    storer_state <= STORER_STORE_REQ;
                end
                STORER_STORE_REQ: begin
                    store_fifo_read_en <= 0;
                    // store_data <= store_fifo_data_out;
                    store_addr <= current_store_addr;
                    store_req <= 1;
                    storer_state <= STORER_STORE_WAIT;
                end
                STORER_STORE_WAIT: begin
                    if (store_complete) begin
                        $display("In STORER_STORE_WAIT, store_complete = %b", store_complete);
                        store_req <= 0;
                        current_store_addr <= current_store_addr + 1;
                        store_counter <= store_counter + 1;
                        if (store_counter < count - 22'b1) begin
                            storer_state <= STORER_START;
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

    // Define state parameters
    localparam IDLE = 2'b00;
    localparam START_DELAY = 2'b01;
    localparam RUNNING = 2'b10;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc_state <= IDLE;
            accelerator_start <= 0;
            load_fifo_read_en <= 0;
            store_fifo_write_en <= 0;
        end else begin
            // Default assignments
            load_fifo_read_en <= 0;
            store_fifo_write_en <= 0;

            case (acc_state)
                IDLE: begin
                    if (!load_fifo_empty && !accelerator_done) begin
                        load_fifo_read_en <= 1;  // Read from FIFO
                        acc_state <= START_DELAY;
                    end
                end
                START_DELAY: begin
                    load_fifo_read_en <= 0;  // Stop reading
                    accelerator_start <= 1;  // Start the accelerator
                    acc_state <= RUNNING;
                end
                RUNNING: begin
                    if (accelerator_done) begin
                        store_fifo_write_en <= 1;  // Write to store FIFO
                        accelerator_start <= 0;    // Stop the accelerator
                        acc_state <= IDLE;
                    end
                end
                default: acc_state <= IDLE;
            endcase
        end
    end

    // Connect load FIFO output to accelerator input
    assign accelerator_data_in = load_fifo_data_out;
    assign store_fifo_data_in = accelerator_data_out;
    assign store_data = store_fifo_data_out;

endmodule
