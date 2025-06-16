`include "constants.vh"

// Accelerator for Map/Reduce Operation (Counting Even Numbers)
module accelerator_property (
    input wire clk_i,
    input wire arst_i,
    input wire start,
    input wire [`FE_DATA_W-1:0] data_in,
    output reg [`FE_DATA_W-1:0] data_out,
    output reg done
);

    parameter NUM_WIDTH = `FE_DATA_W / 4; // Assuming 8 bits per number

    reg [31:0] count;
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam DONE = 2'b01;

    // Extract four 8-bit numbers from 32-bit input
    wire [NUM_WIDTH-1:0] num0 = data_in[NUM_WIDTH-1:0];
    wire [NUM_WIDTH-1:0] num1 = data_in[2*NUM_WIDTH-1:NUM_WIDTH];
    wire [NUM_WIDTH-1:0] num2 = data_in[3*NUM_WIDTH-1:2*NUM_WIDTH];
    wire [NUM_WIDTH-1:0] num3 = data_in[4*NUM_WIDTH-1:3*NUM_WIDTH];

    // Condition: even numbers (lsb == 0)
    // To change condition, modify these lines, e.g., for numbers > 100: is_even0 = (num0 > 8'd100);
    wire is_even0 = ~num0[0];
    wire is_even1 = ~num1[0];
    wire is_even2 = ~num2[0];
    wire is_even3 = ~num3[0];

    wire [2:0] even_count = is_even0 + is_even1 + is_even2 + is_even3;

    always @(posedge clk_i or posedge arst_i) begin
        if (arst_i) begin
            count <= 32'h0;
            state <= IDLE;
            done <= 1'b0;
            data_out <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        count <= count + even_count;
                        data_out <= count + even_count;
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
