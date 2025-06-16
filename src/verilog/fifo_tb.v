`timescale 1ns/1ps

module sync_fifo_tb;
  parameter DATA_WIDTH = 32;
  
  reg clk, rst_n;
  reg w_en, r_en;
  reg [DATA_WIDTH-1:0] data_in;
  wire [DATA_WIDTH-1:0] data_out;
  wire full, empty;
  
  // Array to hold written data for verification
  reg [DATA_WIDTH-1:0] wdata_array [0:1023];
  integer wr_ptr;
  integer rd_ptr;
  
  // Instantiate the FIFO
  fifo s_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .w_en(w_en),
    .r_en(r_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
  );
  
  // Clock generation: 10 ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Reset and initialization
  initial begin
    rst_n = 0;
    w_en = 0;
    r_en = 0;
    data_in = 0;
    wr_ptr = 0;
    rd_ptr = 0;
    #100;
    rst_n = 1;
  end
  
  // Write process with short enable pulse
  initial begin
    wait(rst_n == 1);
    repeat(2) begin
      for (integer i = 0; i < 30; i++) begin
        @(posedge clk);
        if (i % 2 == 0) begin
          if (!full) begin
            data_in = $random;
            wdata_array[wr_ptr] = data_in;
            wr_ptr = wr_ptr + 1;
            w_en = 1;  // Assert w_en
            #5;        // Hold for 2 ns
            w_en = 0;  // Deassert w_en
          end
        end
        @(negedge clk); // Wait until end of clock cycle
      end
      #50; // Delay between rounds
    end
  end
  
  // Read process with short enable pulse
  initial begin
    wait(rst_n == 1);
    repeat(10) @(posedge clk); // Delay before starting reads
    repeat(2) begin
      for (integer i = 0; i < 30; i++) begin
        @(posedge clk);
        if (i % 2 == 0) begin
          if (!empty) begin
            r_en = 1;  // Assert r_en
            #5;        // Hold for 2 ns
            r_en = 0;  // Deassert r_en
            // #1;        // Small delay to ensure data_out is stable
            if (data_out !== wdata_array[rd_ptr]) begin
              $display("Time = %0t: Comparison Failed: expected %h, got %h", $time, wdata_array[rd_ptr], data_out);
            end else begin
              $display("Time = %0t: Comparison Passed: expected %h, got %h", $time, wdata_array[rd_ptr], data_out);
            end
            rd_ptr = rd_ptr + 1;
          end
        end
        @(negedge clk); // Wait until end of clock cycle
      end
      #50; // Delay between rounds
    end
    $finish;
  end
  
  // Waveform dump
  initial begin
    $dumpfile("wave_fifo.vcd");
    $dumpvars;
  end
endmodule