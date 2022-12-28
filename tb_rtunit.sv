`timescale 1ns / 1ps

module tb_rtunit;
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
  
  initial begin
    localparam shortreal origin_x_r = 0.00001;
    localparam shortreal origin_y_r = 0.10001;
    localparam shortreal origin_z_r = 1.0;
    localparam shortreal horizontal_r = 0.2;
    localparam shortreal vertical_r = 0.2;
    localparam shortreal left_r = -0.1;
    localparam shortreal top_r = 0.2;
    localparam shortreal dir_z_r = -1.0;
    shortreal tmp;
    shortreal r;
    shortreal g;
    shortreal b;
    integer f;
    
    clk = 1;
    reset = 1;
    #10;
    reset = 0;
    
    f = $fopen("image.ppm", "w");
    if (f) $display("file open success");
    $fdisplay(f, "P3");
    $fdisplay(f, "100 100");
    $fdisplay(f, "255");
    
    for (int i = 0; i < 100; i++) begin
      for (int j = 0; j < 100; j++) begin
        $display("generating pixel (%3d, %3d)", i, j);
        repeat(5) @(negedge clk);
        valid = 1;
        origin_x = $shortrealtobits(origin_x_r);
        origin_y = $shortrealtobits(origin_y_r);
        origin_z = $shortrealtobits(origin_z_r);
        tmp = (left_r + horizontal_r * j / 100.0) - origin_x_r;
        dir_x = $shortrealtobits(tmp);
        tmp = (top_r - vertical_r * i / 100.0) - origin_y_r;
        dir_y = $shortrealtobits(tmp);
        dir_z = $shortrealtobits(dir_z_r);
        tmax = 32'd2139095039;  // +inf
        @(negedge clk);
        valid = 0;
        @(posedge done);
        @(negedge clk);
        tmp = $sqrt($bitstoshortreal(n_x)*$bitstoshortreal(n_x)+$bitstoshortreal(n_y)*$bitstoshortreal(n_y)+$bitstoshortreal(n_z)*$bitstoshortreal(n_z));
        r = ($bitstoshortreal(n_x)/tmp+1.0)/2.0;
        g = ($bitstoshortreal(n_y)/tmp+1.0)/2.0;
        b = ($bitstoshortreal(n_z)/tmp+1.0)/2.0;
        if (intersected) $fdisplay(f, "%d %d %d", $floor(255*r), $floor(255*g), $floor(255*b));
        else $fdisplay(f, "0 0 0");
      end
    end
    
    $fclose(f);
    $finish;
  end
endmodule
