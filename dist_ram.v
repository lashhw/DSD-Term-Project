`timescale 1ns / 1ps

module dist_ram #(
  parameter RAM_WIDTH = 8,
  parameter RAM_DEPTH = 256
)(
  input clk,
  input we,
  input [$clog2(RAM_DEPTH-1)-1:0] addr,
  input [RAM_WIDTH-1:0] din,
  output [RAM_WIDTH-1:0] dout
);

  reg [RAM_WIDTH-1:0] data [RAM_DEPTH-1:0];

  always @(posedge clk) begin
    if (we)
      data[addr] <= din;
  end

  assign dout = data[addr];

endmodule