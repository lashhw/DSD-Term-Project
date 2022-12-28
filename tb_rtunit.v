`timescale 1ns / 1ps

module tb_rtunit;

  function real bitstoreal;
    input [31:0] bits;
    reg [10:0] exp;
    begin
      exp = {{3{1'b0}}, bits[30:23]};
      exp = exp - 127 + 1023;
      bitstoreal = $bitstoreal({bits[31], exp, bits[22:0], {29{1'b0}}});
    end
  endfunction

  function [31:0] realtobits;
    input real num;
    reg [63:0] temp;
    reg [10:0] exp;
    begin
      temp = $realtobits(num);
      exp = temp[62:52];
      exp = exp - 1023 + 127;
      realtobits = {temp[63], exp[7:0], temp[51:29]};
    end
  endfunction

  reg valid;
  reg [31:0] origin_x;
  reg [31:0] origin_y;
  reg [31:0] origin_z;
  reg [31:0] dir_x;
  reg [31:0] dir_y;
  reg [31:0] dir_z;
  reg [31:0] tmax;
  reg clk;
  reg reset;
  wire done;
  wire intersected;
  wire [31:0] t;
  wire [31:0] u;
  wire [31:0] v;
  wire [31:0] n_x;
  wire [31:0] n_y;
  wire [31:0] n_z;
  
  rtunit rtunit_0 (
    .valid(valid),
    .origin_x(origin_x),
    .origin_y(origin_y),
    .origin_z(origin_z),
    .dir_x(dir_x),
    .dir_y(dir_y),
    .dir_z(dir_z),
    .tmax(tmax),
    .clk(clk),
    .reset(reset),
    .done(done),
    .intersected(intersected),
    .t(t),
    .u(u),
    .v(v),
    .n_x(n_x),
    .n_y(n_y),
    .n_z(n_z)
  );
  
  always #0.5 clk = ~clk;
  
  localparam real origin_x_r = 0.00001;
  localparam real origin_y_r = 0.10001;
  localparam real origin_z_r = 1.0;
  localparam real horizontal_r = 0.2;
  localparam real vertical_r = 0.2;
  localparam real left_r = -0.1;
  localparam real top_r = 0.2;
  localparam real dir_z_r = -1.0;
  real tmp;
  real r;
  real g;
  real b;
  integer f;
  integer i;
  integer j;
  
  initial begin
    clk = 1;
    reset = 1;
    #10;
    reset = 0;
    
    f = $fopen("image.ppm", "w");
    if (f) $display("file open success");
    $fdisplay(f, "P3");
    $fdisplay(f, "100 100");
    $fdisplay(f, "255");
    
    for (i = 0; i < 100; i = i + 1) begin
      for (j = 0; j < 100; j = j + 1) begin
        $display("generating pixel (%3d, %3d)", i, j);
        repeat(5) @(negedge clk);
        valid = 1;
        origin_x = realtobits(origin_x_r);
        origin_y = realtobits(origin_y_r);
        origin_z = realtobits(origin_z_r);
        tmp = (left_r + horizontal_r * j / 100.0) - origin_x_r;
        dir_x = realtobits(tmp);
        tmp = (top_r - vertical_r * i / 100.0) - origin_y_r;
        dir_y = realtobits(tmp);
        dir_z = realtobits(dir_z_r);
        tmax = 32'd2139095039;  // +inf
        @(negedge clk);
        valid = 0;
        @(posedge done);
        @(negedge clk);
        tmp = $sqrt(bitstoreal(n_x)*bitstoreal(n_x)+bitstoreal(n_y)*bitstoreal(n_y)+bitstoreal(n_z)*bitstoreal(n_z));
        r = (bitstoreal(n_x)/tmp+1.0)/2.0;
        g = (bitstoreal(n_y)/tmp+1.0)/2.0;
        b = (bitstoreal(n_z)/tmp+1.0)/2.0;
        if (intersected) $fdisplay(f, "%d %d %d", $floor(255*r), $floor(255*g), $floor(255*b));
        else $fdisplay(f, "0 0 0");
      end
    end
    
    $fclose(f);
    $finish;
  end
endmodule
