`timescale 1ns / 1ps

module tb_ist;
  
  reg valid;
  reg [31:0] origin_x;
  reg [31:0] origin_y;
  reg [31:0] origin_z;
  reg [31:0] dir_x;
  reg [31:0] dir_y;
  reg [31:0] dir_z;
  reg [31:0] tmax;
  reg [31:0] p0_x;
  reg [31:0] p0_y;
  reg [31:0] p0_z;
  reg [31:0] e1_x;
  reg [31:0] e1_y;
  reg [31:0] e1_z;
  reg [31:0] e2_x;
  reg [31:0] e2_y;
  reg [31:0] e2_z;
  reg [31:0] n_x;
  reg [31:0] n_y;
  reg [31:0] n_z;
  reg clk;
  reg reset_n;
  wire done;
  wire isected;
  wire t;
  wire u;
  wire v;

  ist ist_0(
    .valid(valid),
    .origin_x(origin_x),
    .origin_y(origin_y),
    .origin_z(origin_z),
    .dir_x(dir_x),
    .dir_y(dir_y),
    .dir_z(dir_z),
    .tmax(tmax),
    .p0_x(p0_x),
    .p0_y(p0_y),
    .p0_z(p0_z),
    .e1_x(e1_x),
    .e1_y(e1_y),
    .e1_z(e1_z),
    .e2_x(e2_x),
    .e2_y(e2_y),
    .e2_z(e2_z),
    .n_x(n_x),
    .n_y(n_y),
    .n_z(n_z),
    .clk(clk),
    .reset_n(reset_n),
    .done(done),
    .isected(isected),
    .t(t),
    .u(u),
    .v(v)
  );
  
  always #0.5 clk = ~clk;
  
  initial begin
    origin_x = 32'd0;
    origin_y = 32'd1036831949;
    origin_z = 32'd1065353216;
    dir_x = 32'd1017370380;
    dir_y = 32'd3164854028;
    dir_z = 32'd3212836864;
    tmax = 32'd2139095039;
    clk = 1;
    reset_n = 0;
    p0_x = 32'h3c84a5ed;
    p0_y = 32'h3da4d22d;
    p0_z = 32'hbcef5954;
    e1_x = 32'hbc7dd152;
    e1_y = 32'h3b012051;
    e1_z = 32'hbc23fe77;
    e2_x = 32'h3c7eb2f9;
    e2_y = 32'hbc4c7bda;
    e2_z = 32'h3c31ffc2;
    n_x = 32'hb8d91857;
    n_y = 32'h375522d6;
    n_z = 32'h392a9f8d;
    #10.1;
    reset_n = 1;
    valid = 1;
    #5;
    valid = 0;
  end

endmodule
