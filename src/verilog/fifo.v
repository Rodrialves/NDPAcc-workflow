`include "constants.vh"

module fifo (
  input clk, rst_n,
  input w_en, r_en,
  input [`FE_DATA_W-1:0] data_in,
  output reg [`FE_DATA_W-1:0] data_out,
  output full, empty
);

  parameter PTR_WIDTH = $clog2(`FIFO_DEPTH);   // log2(16) = 4

  reg [PTR_WIDTH-1:0] w_ptr, r_ptr;
  reg [`FE_DATA_W-1:0] queue[0:`FIFO_DEPTH-1];

  // Write data to FIFO
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_ptr <= 0;
    end else if (w_en && !full) begin
      w_ptr <= w_ptr + 1;
    end
  end

  always @(posedge clk) begin
    if (w_en && !full) begin
      queue[w_ptr] <= data_in;
    end
  end

  // Read data from FIFO
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_ptr <= 0;
    end else if (r_en && !empty) begin
      r_ptr <= r_ptr + 1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 0;
    end else if (r_en && !empty) begin
      data_out <= queue[r_ptr];
    end
  end

  // Full and empty logic with wrap-around
  wire [PTR_WIDTH-1:0] w_ptr_next = w_ptr + 1;
  wire [PTR_WIDTH-1:0] r_ptr_next = r_ptr + 1;
  assign full = (w_ptr_next == r_ptr) && (w_en != r_en); // Prevent false full on simultaneous wr/rd
  assign empty = (w_ptr == r_ptr);

endmodule