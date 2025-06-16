`include "constants.vh"

// Accelerator for Maximum and Minimum Calculation
module accelerator_max_min (
    input wire clk_i,
    input wire arst_i,
    input wire start,
    input wire [`FE_DATA_W-1:0] data_in,
    output reg [`FE_DATA_W-1:0] data_out,
    output reg done
);

    parameter NUM_WIDTH = `FE_DATA_W / 4; // Assuming 8 bits per number

    reg [NUM_WIDTH-1:0] current_max;
    reg [NUM_WIDTH-1:0] current_min;
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam DONE = 2'b01;

    // Extract four 8-bit numbers from 32-bit input
    wire [NUM_WIDTH-1:0] num0 = data_in[NUM_WIDTH-1:0];
    wire [NUM_WIDTH-1:0] num1 = data_in[2*NUM_WIDTH-1:NUM_WIDTH];
    wire [NUM_WIDTH-1:0] num2 = data_in[3*NUM_WIDTH-1:2*NUM_WIDTH];
    wire [NUM_WIDTH-1:0] num3 = data_in[4*NUM_WIDTH-1:3*NUM_WIDTH];

    // Compute maximum of the four numbers
    wire [NUM_WIDTH-1:0] max_temp1 = (num0 > num1) ? num0 : num1;
    wire [NUM_WIDTH-1:0] max_temp2 = (num2 > num3) ? num2 : num3;
    wire [NUM_WIDTH-1:0] max_of_four = (max_temp1 > max_temp2) ? max_temp1 : max_temp2;

    // Compute minimum of the four numbers
    wire [NUM_WIDTH-1:0] min_temp1 = (num0 < num1) ? num0 : num1;
    wire [NUM_WIDTH-1:0] min_temp2 = (num2 < num3) ? num2 : num3;
    wire [NUM_WIDTH-1:0] min_of_four = (min_temp1 < min_temp2) ? min_temp1 : min_temp2;

    // Determine new maximum and minimum
    wire [NUM_WIDTH-1:0] new_max = (max_of_four > current_max) ? max_of_four : current_max;
    wire [NUM_WIDTH-1:0] new_min = (min_of_four < current_min) ? min_of_four : current_min;

    always @(posedge clk_i or posedge arst_i) begin
        if (arst_i) begin
            current_max <= {NUM_WIDTH{1'b0}}; // Initialize to 0
            current_min <= {NUM_WIDTH{1'b1}}; // Initialize to 255
            state <= IDLE;
            done <= 1'b0;
            data_out <= {`FE_DATA_W{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        current_max <= new_max;
                        current_min <= new_min;
                        data_out <= { {(`FE_DATA_W - 2*NUM_WIDTH){1'b0}}, new_max, new_min }; // [15:8]=max, [7:0]=min
                        state <= DONE;
                        done <= 1'b1;
                    end
                end
                DONE: begin
                    if (!start) begin
                        state <= IDLE;
                        done <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule
