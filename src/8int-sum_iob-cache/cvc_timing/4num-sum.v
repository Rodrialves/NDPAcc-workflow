`include "constants.vh"

module accelerator # (
    parameter NUM_WIDTH = `FE_DATA_W / 4
) (
    input  wire                  clk_i,       // Clock
    input  wire                  arst_i,      // Asynchronous reset
    input  wire                  start,       // Start signal
    input  wire [`FE_DATA_W-1:0] data_in,     // 32-bit input
    output reg  [`FE_DATA_W-1:0] data_out,    // 32-bit output
    output reg                   done         // Done signal
);

    // Extract bytes
    wire [NUM_WIDTH-1:0] byte0 = data_in[NUM_WIDTH-1:0];
    wire [NUM_WIDTH-1:0] byte1 = data_in[2*NUM_WIDTH-1:NUM_WIDTH];
    wire [NUM_WIDTH-1:0] byte2 = data_in[3*NUM_WIDTH-1:2*NUM_WIDTH];
    wire [NUM_WIDTH-1:0] byte3 = data_in[4*NUM_WIDTH-1:3*NUM_WIDTH];

    // Compute sum
    wire [NUM_WIDTH+1:0] sum = byte0 + byte1 + byte2 + byte3;

    // State machine
    reg state; // 0: idle, 1: processing
    localparam IDLE = 0, DONE = 1;

    always @(posedge clk_i or posedge arst_i) begin
        if (arst_i) begin
            state <= IDLE;
            data_out <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= DONE;
                        data_out <= {{(`FE_DATA_W-NUM_WIDTH-2){1'b0}}, sum};
                    end
                end
                DONE: begin
                    done <= 1;
                    if (!start) begin
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                    done <= 0;
                end
            endcase
        end
    end
endmodule