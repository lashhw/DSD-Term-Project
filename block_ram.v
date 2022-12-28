module block_ram #(
  parameter RAM_WIDTH = 8,
  parameter RAM_DEPTH = 256,
  parameter INIT_FILE = "data.mem"
)(
  input clk,
  input we,
  input [$clog2(RAM_DEPTH-1)-1:0] addr,
  input [RAM_WIDTH-1:0] din,
  output reg [RAM_WIDTH-1:0] dout
);

  reg [RAM_WIDTH-1:0] data [RAM_DEPTH-1:0];

  initial $readmemh(INIT_FILE, data);

  always @(posedge clk) begin
    if (we)
      data[addr] <= din;
    else
      dout <= data[addr];
  end

endmodule