`timescale 1ns / 1ps

module ist(
  input valid,
  input [31:0] origin_x,
  input [31:0] origin_y,
  input [31:0] origin_z,
  input [31:0] dir_x,
  input [31:0] dir_y,
  input [31:0] dir_z,
  input [31:0] tmax,
  input [31:0] p0_x,
  input [31:0] p0_y,
  input [31:0] p0_z,
  input [31:0] e1_x,
  input [31:0] e1_y,
  input [31:0] e1_z,
  input [31:0] e2_x,
  input [31:0] e2_y,
  input [31:0] e2_z,
  input [31:0] n_x,
  input [31:0] n_y,
  input [31:0] n_z,
  
  input clk,
  input reset,
  
  output reg done,
  output reg intersected,
  output reg [31:0] t,
  output reg [31:0] u,
  output reg [31:0] v
);

  localparam S_IDLE = 0,
             S_CX_SUB = 1,
             S_CY_SUB = 2,
             S_CZ_SUB = 3,
             S_RX_MUL = 4,
             S_RX_SUB = 5,
             S_RY_MUL = 6,
             S_RY_SUB = 7,
             S_RZ_MUL = 8,
             S_RZ_SUB = 9,
             S_DET_MUL_A = 10,
             S_DET_ADD_A = 11,
             S_DET_MUL_B = 12,
             S_DET_ADD_B = 13,
             S_DET_RCPL = 14,
             S_T_MUL_A = 15,
             S_T_ADD_A = 16,
             S_T_MUL_B = 17,
             S_T_ADD_B = 18,
             S_T_MUL_C = 19,
             S_U_MUL_A = 20,
             S_U_ADD_A = 21,
             S_U_MUL_B = 22,
             S_U_ADD_B = 23,
             S_U_MUL_C = 24,
             S_V_MUL_A = 25,
             S_V_ADD_A = 26,
             S_V_MUL_B = 27,
             S_V_ADD_B = 28,
             S_V_MUL_C = 29,
             S_T_LESS_A = 30,
             S_T_LESS_B = 31,
             S_U_LESS = 32,
             S_V_LESS = 33,
             S_UV_ADD = 34,
             S_UV_LESS = 35;
  
  // signals for adder/subtractor
  reg addsub_in_valid;
  reg [31:0] addsub_in_a;
  reg [31:0] addsub_in_b;
  reg addsub_op;
  wire addsub_out_valid;
  wire [31:0] addsub_out;
  
  // signals for multiplier
  reg mul_in_valid;
  reg [31:0] mul_in_a [0:1];
  reg [31:0] mul_in_b [0:1];
  wire mul_out_valid [0:1];
  wire [31:0] mul_out [0:1];
  
  // signals for reciprocal operator
  reg rcpl_in_valid;
  reg [31:0] rcpl_in;
  wire rcpl_out_valid;
  wire [31:0] rcpl_out;
  
  // signals for less operator
  reg less_in_valid;
  reg [31:0] less_in_a;
  reg [31:0] less_in_b;
  wire less_out_valid;
  wire [7:0] less_out;
  
  // nets
  reg [5:0] S_next;
  
  // registers
  reg [5:0] S = S_IDLE;
  reg [31:0] tmp;
  reg [31:0] c_x;
  reg [31:0] c_y;
  reg [31:0] c_z;
  reg [31:0] r_x;
  reg [31:0] r_y;
  reg [31:0] r_z;
  reg [31:0] inv_det;
  
  float_addsub # (
    .LATENCY(5)
  ) float_addsub_0 (
    .clk(clk),
    .valid(addsub_in_valid),
    .a(addsub_in_a),
    .b(addsub_in_b),
    .operation(addsub_op),
    .done(addsub_out_valid),
    .result(addsub_out)
  );
  
  genvar i;
  generate 
    for (i = 0; i < 2; i = i + 1) begin
      float_operator #(
        .OPERATION("mul"),
        .LATENCY(5)
      ) float_mul_0 (
        .clk(clk),
        .valid(mul_in_valid),
        .a(mul_in_a[i]),
        .b(mul_in_b[i]),
        .done(mul_out_valid[i]),
        .result(mul_out[i])
      );
    end
  endgenerate
  
  float_operator #(
    .OPERATION("div"),
    .LATENCY(5)
  ) float_rcpl_0 (
    .clk(clk),
    .valid(rcpl_in_valid),
    .a(32'h3f800000),
    .b(rcpl_in),
    .done(rcpl_out_valid),
    .result(rcpl_out)
  );
  
  float_operator #(
    .OPERATION("less"),
    .LATENCY(5)
  ) float_less_0 (
    .clk(clk),                                
    .valid(less_in_valid),          
    .a(less_in_a),            
    .b(less_in_b),            
    .done(less_out_valid),
    .result(less_out)   
  );
  
  always @(*) begin
    done = 0;
    intersected = 0;
    addsub_in_valid = 0;
    addsub_in_a = 0;
    addsub_in_b = 0;
    addsub_op = 0;
    mul_in_valid = 0;
    mul_in_a[0] = 0;
    mul_in_a[1] = 0;
    mul_in_b[0] = 0;
    mul_in_b[1] = 0;
    rcpl_in_valid = 0;
    rcpl_in = 0;
    less_in_valid = 0;
    less_in_a = 0;
    less_in_b = 0;
    S_next = S_IDLE;
    
    if (~reset) case (S)
      S_IDLE: begin
        if (valid) begin
          addsub_in_valid = 1;
          addsub_in_a = p0_x;
          addsub_in_b = origin_x;
          addsub_op = 1;
          S_next = S_CX_SUB;
        end
      end
      S_CX_SUB: begin
        if (addsub_out_valid) begin
          addsub_in_valid = 1;
          addsub_in_a = p0_y;
          addsub_in_b = origin_y;
          addsub_op = 1;
          S_next = S_CY_SUB;
        end
        else S_next = S_CX_SUB;
      end
      S_CY_SUB: begin
        if (addsub_out_valid) begin
          addsub_in_valid = 1;
          addsub_in_a = p0_z;
          addsub_in_b = origin_z;
          addsub_op = 1;
          S_next = S_CZ_SUB;
        end
        else S_next = S_CY_SUB;
      end
      S_CZ_SUB: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = dir_y;
          mul_in_b[0] = addsub_out;  // c_z
          mul_in_a[1] = dir_z;
          mul_in_b[1] = c_y;
          S_next = S_RX_MUL;
        end
        else S_next = S_CZ_SUB;
      end
      S_RX_MUL: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = mul_out[0];
          addsub_in_b = mul_out[1];
          addsub_op = 1;
          S_next = S_RX_SUB;
        end
        else S_next = S_RX_MUL;
      end
      S_RX_SUB: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = dir_z;
          mul_in_b[0] = c_x;
          mul_in_a[1] = dir_x;
          mul_in_b[1] = c_z;
          S_next = S_RY_MUL;
        end
        else S_next = S_RX_SUB;
      end
      S_RY_MUL: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = mul_out[0];
          addsub_in_b = mul_out[1];
          addsub_op = 1;
          S_next = S_RY_SUB;
        end
        else S_next = S_RY_MUL;
      end
      S_RY_SUB: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = dir_x;
          mul_in_b[0] = c_y;
          mul_in_a[1] = dir_y;
          mul_in_b[1] = c_x;
          S_next = S_RZ_MUL;
        end
        else S_next = S_RY_SUB;
      end
      S_RZ_MUL: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = mul_out[0];
          addsub_in_b = mul_out[1];
          addsub_op = 1;
          S_next = S_RZ_SUB;
        end
        else S_next = S_RZ_MUL;
      end
      S_RZ_SUB: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = dir_x;
          mul_in_b[0] = n_x;
          mul_in_a[1] = dir_y;
          mul_in_b[1] = n_y;
          S_next = S_DET_MUL_A;
        end
        else S_next = S_RZ_SUB;
      end
      S_DET_MUL_A: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = mul_out[0];
          addsub_in_b = mul_out[1];
          addsub_op = 0;
          S_next = S_DET_ADD_A;
        end
        else S_next = S_DET_MUL_A;
      end
      S_DET_ADD_A: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = dir_z;
          mul_in_b[0] = n_z;
          S_next = S_DET_MUL_B;
        end
        else S_next = S_DET_ADD_A;
      end
      S_DET_MUL_B: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = tmp;
          addsub_in_b = mul_out[0];
          addsub_op = 0;
          S_next = S_DET_ADD_B;
        end
        else S_next = S_DET_MUL_B;
      end
      S_DET_ADD_B: begin
        if (addsub_out_valid) begin
          rcpl_in_valid = 1;
          rcpl_in = addsub_out;
          S_next = S_DET_RCPL;
        end
        else S_next = S_DET_ADD_B;
      end
      S_DET_RCPL: begin
        if (rcpl_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = c_x;
          mul_in_b[0] = n_x;
          mul_in_a[1] = c_y;
          mul_in_b[1] = n_y;
          S_next = S_T_MUL_A;
        end
        else S_next = S_DET_RCPL;
      end
      S_T_MUL_A: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = mul_out[0];
          addsub_in_b = mul_out[1];
          addsub_op = 0;
          S_next = S_T_ADD_A;
        end
        else S_next = S_T_MUL_A;
      end
      S_T_ADD_A: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = c_z;
          mul_in_b[0] = n_z;
          S_next = S_T_MUL_B;
        end
        else S_next = S_T_ADD_A;
      end
      S_T_MUL_B: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = tmp;
          addsub_in_b = mul_out[0];
          addsub_op = 0;
          S_next = S_T_ADD_B;
        end
        else S_next = S_T_MUL_B;
      end
      S_T_ADD_B: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = inv_det;
          mul_in_b[0] = addsub_out;
          S_next = S_T_MUL_C;
        end
        else S_next = S_T_ADD_B;
      end
      S_T_MUL_C: begin
        if (mul_out_valid[0]) begin
          mul_in_valid = 1;
          mul_in_a[0] = e2_x;
          mul_in_b[0] = r_x;
          mul_in_a[1] = e2_y;
          mul_in_b[1] = r_y;
          S_next = S_U_MUL_A;
        end
        else S_next = S_T_MUL_C;
      end
      S_U_MUL_A: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = mul_out[0];
          addsub_in_b = mul_out[1];
          addsub_op = 0;
          S_next = S_U_ADD_A;
        end
        else S_next = S_U_MUL_A;
      end
      S_U_ADD_A: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = e2_z;
          mul_in_b[0] = r_z;
          S_next = S_U_MUL_B;
        end
        else S_next = S_U_ADD_A;
      end
      S_U_MUL_B: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = tmp;
          addsub_in_b = mul_out[0];
          addsub_op = 0;
          S_next = S_U_ADD_B;
        end
        else S_next = S_U_MUL_B;
      end
      S_U_ADD_B: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = inv_det;
          mul_in_b[0] = addsub_out;
          S_next = S_U_MUL_C;
        end
        else S_next = S_U_ADD_B;
      end
      S_U_MUL_C: begin
        if (mul_out_valid[0]) begin
          mul_in_valid = 1;
          mul_in_a[0] = e1_x;
          mul_in_b[0] = r_x;
          mul_in_a[1] = e1_y;
          mul_in_b[1] = r_y;
          S_next = S_V_MUL_A;
        end
        else S_next = S_U_MUL_C;
      end
      S_V_MUL_A: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = mul_out[0];
          addsub_in_b = mul_out[1];
          addsub_op = 0;
          S_next = S_V_ADD_A;
        end
        else S_next = S_V_MUL_A;
      end
      S_V_ADD_A: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = e1_z;
          mul_in_b[0] = r_z;
          S_next = S_V_MUL_B;
        end
        else S_next = S_V_ADD_A;
      end
      S_V_MUL_B: begin
        if (mul_out_valid[0]) begin
          addsub_in_valid = 1;
          addsub_in_a = tmp;
          addsub_in_b = mul_out[0];
          addsub_op = 0;
          S_next = S_V_ADD_B;
        end
        else S_next = S_V_MUL_B;
      end
      S_V_ADD_B: begin
        if (addsub_out_valid) begin
          mul_in_valid = 1;
          mul_in_a[0] = inv_det;
          mul_in_b[0] = addsub_out;
          S_next = S_V_MUL_C;
        end
        else S_next = S_V_ADD_B;
      end
      S_V_MUL_C: begin
        if (mul_out_valid[0]) begin
          less_in_valid = 1;
          less_in_a = 0;
          less_in_b = t;
          S_next = S_T_LESS_A;
        end
        else S_next = S_V_MUL_C;
      end
      S_T_LESS_A: begin
        if (less_out_valid) begin
          if (less_out[0]) begin
            less_in_valid = 1;
            less_in_a = t;
            less_in_b = tmax;
            S_next = S_T_LESS_B;
          end
          else begin
            done = 1;
            S_next = S_IDLE;
          end
        end
        else S_next = S_T_LESS_A;
      end
      S_T_LESS_B: begin
        if (less_out_valid) begin
          if (less_out[0]) begin
            less_in_valid = 1;
            less_in_a = 0;
            less_in_b = u;
            S_next = S_U_LESS;
          end
          else begin
            done = 1;
            S_next = S_IDLE;
          end
        end
        else S_next = S_T_LESS_B;
      end
      S_U_LESS: begin
        if (less_out_valid) begin
          if (less_out[0]) begin
            less_in_valid = 1;
            less_in_a = 0;
            less_in_b = v;
            S_next = S_V_LESS;
          end
          else begin
            done = 1;
            S_next = S_IDLE;
          end
        end
        else S_next = S_U_LESS;
      end
      S_V_LESS: begin
        if (less_out_valid) begin
          if (less_out[0]) begin
            addsub_in_valid = 1;
            addsub_in_a = u;
            addsub_in_b = v;
            addsub_op = 0;
            S_next = S_UV_ADD;
          end
          else begin
            done = 1;
            S_next = S_IDLE;
          end
        end
        else S_next = S_V_LESS;
      end
      S_UV_ADD: begin
        if (addsub_out_valid) begin
          less_in_valid = 1;
          less_in_a = addsub_out;
          less_in_b = 32'h3f800000;  // 1.0f
          S_next = S_UV_LESS;
        end
        else S_next = S_UV_ADD;
      end
      S_UV_LESS: begin
        if (less_out_valid) begin
          done = 1;
          intersected = less_out[0];
          S_next = S_IDLE;
        end
        else S_next = S_UV_LESS;
      end
    endcase
  end
  
  always @(posedge clk) begin
    S <= S_next;
  end
  
  always @(posedge clk) begin
    case (S)
      S_CX_SUB: c_x <= addsub_out;
      S_CY_SUB: c_y <= addsub_out;
      S_CZ_SUB: c_z <= addsub_out;
      S_RX_SUB: r_x <= addsub_out;
      S_RY_SUB: r_y <= addsub_out;
      S_RZ_SUB: r_z <= addsub_out;
      S_DET_ADD_A: tmp <= addsub_out;
      S_DET_RCPL: inv_det <= rcpl_out;
      S_T_ADD_A: tmp <= addsub_out;
      S_T_MUL_C: t <= mul_out[0];
      S_U_ADD_A: tmp <= addsub_out;
      S_U_MUL_C: u <= mul_out[0];
      S_V_ADD_A: tmp <= addsub_out;
      S_V_MUL_C: v <= mul_out[0];
    endcase
  end
  
endmodule
