`timescale 1ns / 1ps

module float_operator #(
  parameter OPERATION = "add",
  parameter LATENCY = 5
)(
  input clk,
  input valid,
  input [31:0] a,
  input [31:0] b,
  output done,
  output [31:0] result
);

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
  
  real a_real;
  real b_real;
  always @(*) begin
    a_real = bitstoreal(a);
    b_real = bitstoreal(b);
  end
  
  reg [31:0] result_reg [0:LATENCY];
  always @(*) begin
    if (OPERATION == "add")
      result_reg[0] = realtobits(a_real + b_real);
    if (OPERATION == "sub")
      result_reg[0] = realtobits(a_real - b_real);
    else if (OPERATION == "mul")
      result_reg[0] = realtobits(a_real * b_real);
    else if (OPERATION == "div")
      result_reg[0] = realtobits(a_real / b_real);
    else if (OPERATION == "less") begin
      if (a_real < b_real)
        result_reg[0] = 1;
      else
        result_reg[0] = 0;
    end
  end
  
  reg done_reg [0:LATENCY];
  always @(*)
    done_reg[0] = valid;
  
  genvar i;
  generate
    for (i = 1; i <= LATENCY; i = i+1) begin
      always @(posedge clk) begin
        result_reg[i] <= result_reg[i-1];
        done_reg[i] <= done_reg[i-1];
      end
    end
  endgenerate
  
  assign result = result_reg[LATENCY];
  assign done = done_reg[LATENCY];

endmodule