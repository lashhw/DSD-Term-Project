`timescale 1ns / 1ps

module rtunit (
  input valid,
  input [31:0] origin_x,
  input [31:0] origin_y,
  input [31:0] origin_z,
  input [31:0] dir_x,
  input [31:0] dir_y,
  input [31:0] dir_z,
  input [31:0] tmax,
  
  input clk,
  input reset,
  
  output reg done,
  output intersected,
  output [31:0] t,
  output [31:0] u,
  output [31:0] v,
  output [31:0] n_x,
  output [31:0] n_y,
  output [31:0] n_z
);

  localparam S_INIT = 0,
             S_IDLE = 1,
             S_NODE_ADDR = 2,
             S_NODE_LOAD = 3,
             S_SUB = 4,
             S_DIV = 5,
             S_MINMAX_A = 6,
             S_MINMAX_B = 7,
             S_MINMAX_C = 8,
             S_HIT = 9,
             S_TRIG_LEFT_ADDR = 10,
             S_TRIG_LEFT_LOAD = 11,
             S_TRIG_LEFT_IST = 12,
             S_TRIG_RIGHT_ADDR = 13,
             S_TRIG_RIGHT_LOAD = 14,
             S_TRIG_RIGHT_IST = 15,
             S_STEP = 16;
  
  // nets
  reg [4:0] S_next;
  reg intersect_result_reg_init;
  reg intersect_result_reg_update;
  reg counter_reg_reset;
  reg counter_reg_inc;
  reg stack_size_reg_reset;
  reg stack_size_reg_inc;
  reg stack_size_reg_dec;
  reg node_data_reg_update;
  reg l_num_trigs_reg_dec;
  reg r_num_trigs_reg_dec;
  reg trig_data_reg_update;
  reg entry_exit_xyz_reg_update;
  reg [31:0] l_entry_x;
  reg [31:0] l_entry_y;
  reg [31:0] l_entry_z;
  reg [31:0] l_exit_x;
  reg [31:0] l_exit_y;
  reg [31:0] l_exit_z;
  reg [31:0] r_entry_x;
  reg [31:0] r_entry_y;
  reg [31:0] r_entry_z;
  reg [31:0] r_exit_x;
  reg [31:0] r_exit_y;
  reg [31:0] r_exit_z;
  reg entry_exit_reg_update;
  reg [31:0] l_entry;
  reg [31:0] l_exit;
  reg [31:0] r_entry;
  reg [31:0] r_exit;
  reg hit_reg_update;
  reg l_hit_reg_reset;
  reg r_hit_reg_reset;
  reg bram_node_addr_reg_init;
  reg bram_node_addr_reg_inc;
  reg bram_node_addr_reg_update_l;
  reg bram_node_addr_reg_update_r;
  reg bram_node_addr_reg_update_stack;
  reg bram_trig_addr_reg_inc;
  reg bram_trig_addr_reg_update_l;
  reg bram_trig_addr_reg_update_r;
  
  // registers
  reg [4:0] S = S_INIT;
  reg intersected_reg;
  reg [31:0] t_reg;
  reg [31:0] u_reg;
  reg [31:0] v_reg;
  reg [31:0] n_x_reg;
  reg [31:0] n_y_reg;
  reg [31:0] n_z_reg;
  reg [3:0] counter_reg;
  reg [5:0] stack_size_reg;
  reg [31:0] l_bound_x_min_reg;
  reg [31:0] l_bound_x_max_reg;
  reg [31:0] l_bound_y_min_reg;
  reg [31:0] l_bound_y_max_reg;
  reg [31:0] l_bound_z_min_reg;
  reg [31:0] l_bound_z_max_reg;
  reg [ 7:0] l_num_trigs_reg;
  reg [13:0] l_left_node_or_trig_addr_reg;
  reg [31:0] r_bound_x_min_reg;
  reg [31:0] r_bound_x_max_reg;
  reg [31:0] r_bound_y_min_reg;
  reg [31:0] r_bound_y_max_reg;
  reg [31:0] r_bound_z_min_reg;
  reg [31:0] r_bound_z_max_reg;
  reg [ 7:0] r_num_trigs_reg;
  reg [13:0] r_left_node_or_trig_addr_reg;
  reg [31:0] l_entry_x_reg;
  reg [31:0] l_entry_y_reg;
  reg [31:0] l_entry_z_reg;
  reg [31:0] l_exit_x_reg;
  reg [31:0] l_exit_y_reg;
  reg [31:0] l_exit_z_reg;
  reg [31:0] r_entry_x_reg;
  reg [31:0] r_entry_y_reg;
  reg [31:0] r_entry_z_reg;
  reg [31:0] r_exit_x_reg;
  reg [31:0] r_exit_y_reg;
  reg [31:0] r_exit_z_reg;
  reg [31:0] l_entry_reg;
  reg [31:0] l_exit_reg;
  reg [31:0] r_entry_reg;
  reg [31:0] r_exit_reg;
  reg l_hit_reg;
  reg r_hit_reg;
  reg l_first_reg;
             
  wire bram_node_we;
  reg [12:0] bram_node_addr_reg;
  wire [31:0] bram_node_din;
  wire [31:0] bram_node_dout;
  block_ram #(
    .RAM_WIDTH(32),
    .RAM_DEPTH(7448),
    .INIT_FILE("node.mem")
  ) bram_node (
    .clk(clk),   
    .we(bram_node_we),    
    .addr(bram_node_addr_reg),
    .din(bram_node_din),  
    .dout(bram_node_dout) 
  );
  
  wire bram_trig_we;
  reg [13:0] bram_trig_addr_reg;
  wire [31:0] bram_trig_din;
  wire [31:0] bram_trig_dout;
  block_ram #(
    .RAM_WIDTH(32),
    .RAM_DEPTH(11376),
    .INIT_FILE("trig.mem")
  ) bram_trig (
    .clk(clk),  
    .we(bram_trig_we),    
    .addr(bram_trig_addr_reg),
    .din(bram_trig_din),  
    .dout(bram_trig_dout) 
  );
  
  reg stack_we;
  reg [5:0] stack_addr;
  reg [12:0] stack_din;
  wire [12:0] stack_dout;
  dist_ram #(
    .RAM_WIDTH(13),
    .RAM_DEPTH(64)
  ) stack (
    .clk(clk),
    .we(stack_we),
    .addr(stack_addr),
    .din(stack_din),
    .dout(stack_dout)
  );
  
  reg ist_valid;
  reg [31:0] ist_p0_x_reg;
  reg [31:0] ist_p0_y_reg;
  reg [31:0] ist_p0_z_reg;
  reg [31:0] ist_e1_x_reg;
  reg [31:0] ist_e1_y_reg;
  reg [31:0] ist_e1_z_reg;
  reg [31:0] ist_e2_x_reg;
  reg [31:0] ist_e2_y_reg;
  reg [31:0] ist_e2_z_reg;
  reg [31:0] ist_n_x_reg;
  reg [31:0] ist_n_y_reg;
  reg [31:0] ist_n_z_reg;
  wire ist_done;
  wire ist_intersected;
  wire [31:0] ist_t;
  wire [31:0] ist_u;
  wire [31:0] ist_v;
  ist ist_0(
    .valid(ist_valid),
    .origin_x(origin_x),
    .origin_y(origin_y),
    .origin_z(origin_z),
    .dir_x(dir_x),
    .dir_y(dir_y),
    .dir_z(dir_z),
    .tmax(t_reg),
    .p0_x(ist_p0_x_reg),
    .p0_y(ist_p0_y_reg),
    .p0_z(ist_p0_z_reg),
    .e1_x(ist_e1_x_reg),
    .e1_y(ist_e1_y_reg),
    .e1_z(ist_e1_z_reg),
    .e2_x(ist_e2_x_reg),
    .e2_y(ist_e2_y_reg),
    .e2_z(ist_e2_z_reg),
    .n_x(ist_n_x_reg),
    .n_y(ist_n_y_reg),
    .n_z(ist_n_z_reg),
    .clk(clk),
    .reset(reset),
    .done(ist_done),
    .intersected(ist_intersected),
    .t(ist_t),
    .u(ist_u),
    .v(ist_v)
  );
  
  reg sub_in_valid;
  wire [31:0] sub_a [0:11];
  wire [31:0] sub_b [0:11];
  wire sub_out_valid [0:11];
  wire [31:0] sub_out [0:11];
  genvar i;
  generate
    for (i = 0; i < 12; i = i + 1) begin
      float_operator #(
        .OPERATION("sub"),
        .LATENCY(5)
      ) float_sub_i (
        .clk(clk),
        .valid(sub_in_valid),
        .a(sub_a[i]),
        .b(sub_b[i]),
        .done(sub_out_valid[i]),
        .result(sub_out[i])
      );
    end
  endgenerate
  
  reg div_in_valid;
  wire [31:0] div_a [0:11];
  wire [31:0] div_b [0:11];
  wire div_out_valid [0:11];
  wire [31:0] div_out [0:11];
  generate
    for (i = 0; i < 12; i = i + 1) begin
      float_operator #(
        .OPERATION("div"),
        .LATENCY(5)
      ) float_div_i (
        .clk(clk),
        .valid(div_in_valid),          
        .a(div_a[i]),            
        .b(div_b[i]),            
        .done(div_out_valid[i]),
        .result(div_out[i])   
      );
    end
  endgenerate
  
  reg less_in_valid;
  reg [31:0] less_a [0:3];
  reg [31:0] less_b [0:3];
  wire less_out_valid [0:3];
  wire [7:0] less_out [0:3];
  generate
    for (i = 0; i < 4; i = i + 1) begin
      float_operator #(
        .OPERATION("less"),
        .LATENCY(5)
      ) float_less_minmax_i (
        .clk(clk),
        .valid(less_in_valid),          
        .a(less_a[i]),            
        .b(less_b[i]),            
        .done(less_out_valid[i]),
        .result(less_out[i])   
      );
    end
  endgenerate
  
  assign intersected = intersected_reg;
  assign t = t_reg;
  assign u = u_reg;
  assign v = v_reg;
  assign n_x = n_x_reg;
  assign n_y = n_y_reg;
  assign n_z = n_z_reg;
  
  assign bram_node_we = 0;
  assign bram_node_din = 0;
  
  assign bram_trig_we = 0;
  assign bram_trig_din = 0;
  
  assign sub_a[ 0] = l_bound_x_min_reg;
  assign sub_a[ 1] = l_bound_x_max_reg;
  assign sub_a[ 2] = l_bound_y_min_reg;
  assign sub_a[ 3] = l_bound_y_max_reg;
  assign sub_a[ 4] = l_bound_z_min_reg;
  assign sub_a[ 5] = l_bound_z_max_reg;
  assign sub_a[ 6] = r_bound_x_min_reg;
  assign sub_a[ 7] = r_bound_x_max_reg;
  assign sub_a[ 8] = r_bound_y_min_reg;
  assign sub_a[ 9] = r_bound_y_max_reg;
  assign sub_a[10] = r_bound_z_min_reg;
  assign sub_a[11] = r_bound_z_max_reg;
  assign sub_b[ 0] = origin_x;
  assign sub_b[ 1] = origin_x;
  assign sub_b[ 2] = origin_y;
  assign sub_b[ 3] = origin_y;
  assign sub_b[ 4] = origin_z;
  assign sub_b[ 5] = origin_z;
  assign sub_b[ 6] = origin_x;
  assign sub_b[ 7] = origin_x;
  assign sub_b[ 8] = origin_y;
  assign sub_b[ 9] = origin_y;
  assign sub_b[10] = origin_z;
  assign sub_b[11] = origin_z;
  
  assign div_a[ 0] = sub_out[ 0];
  assign div_a[ 1] = sub_out[ 1];
  assign div_a[ 2] = sub_out[ 2];
  assign div_a[ 3] = sub_out[ 3];
  assign div_a[ 4] = sub_out[ 4];
  assign div_a[ 5] = sub_out[ 5];
  assign div_a[ 6] = sub_out[ 6];
  assign div_a[ 7] = sub_out[ 7];
  assign div_a[ 8] = sub_out[ 8];
  assign div_a[ 9] = sub_out[ 9];
  assign div_a[10] = sub_out[10];
  assign div_a[11] = sub_out[11];
  assign div_b[ 0] = dir_x;
  assign div_b[ 1] = dir_x;
  assign div_b[ 2] = dir_y;
  assign div_b[ 3] = dir_y;
  assign div_b[ 4] = dir_z;
  assign div_b[ 5] = dir_z;
  assign div_b[ 6] = dir_x;
  assign div_b[ 7] = dir_x;
  assign div_b[ 8] = dir_y;
  assign div_b[ 9] = dir_y;
  assign div_b[10] = dir_z;
  assign div_b[11] = dir_z;
  
  always @(*) begin
    done = 0;
    S_next = S_INIT;
    intersect_result_reg_init = 0;
    intersect_result_reg_update = 0;
    counter_reg_reset = 0;
    counter_reg_inc = 0;
    stack_size_reg_reset = 0;
    stack_size_reg_inc = 0;
    stack_size_reg_dec = 0;
    node_data_reg_update = 0;
    l_num_trigs_reg_dec = 0;
    r_num_trigs_reg_dec = 0;
    trig_data_reg_update = 0;
    entry_exit_xyz_reg_update = 0;
    l_entry_x = 0;
    l_entry_y = 0;
    l_entry_z = 0;
    l_exit_x = 0;
    l_exit_y = 0;
    l_exit_z = 0;
    r_entry_x = 0;
    r_entry_y = 0;
    r_entry_z = 0;
    r_exit_x = 0;
    r_exit_y = 0;
    r_exit_z = 0;
    entry_exit_reg_update = 0;
    l_entry = 0;
    l_exit = 0;
    r_entry = 0;
    r_exit = 0;
    hit_reg_update = 0;
    l_hit_reg_reset = 0;
    r_hit_reg_reset = 0;
    bram_node_addr_reg_init = 0;
    bram_node_addr_reg_inc = 0;
    bram_node_addr_reg_update_l = 0;
    bram_node_addr_reg_update_r = 0;
    bram_node_addr_reg_update_stack = 0;
    bram_trig_addr_reg_inc = 0;
    bram_trig_addr_reg_update_l = 0;
    bram_trig_addr_reg_update_r = 0;
    stack_addr = 0;
    stack_din = 0;
    stack_we = 0;
    ist_valid = 0;
    sub_in_valid = 0;
    div_in_valid = 0;
    less_in_valid = 0;
    less_a[0] = 0;
    less_b[0] = 0;
    less_a[1] = 0;
    less_b[1] = 0;
    less_a[2] = 0;
    less_b[2] = 0;
    less_a[3] = 0;
    less_b[3] = 0;
    
    if (~reset) case (S)
      S_INIT: begin
        intersect_result_reg_init = 1;
        stack_size_reg_reset = 1;
        bram_node_addr_reg_init = 1;
        S_next = S_IDLE;
      end
      S_IDLE: begin
        if (valid) S_next = S_NODE_ADDR;
        else S_next = S_IDLE;
      end
      S_NODE_ADDR: begin
        counter_reg_reset = 1;
        bram_node_addr_reg_inc = 1;
        S_next = S_NODE_LOAD;
      end
      S_NODE_LOAD: begin
        node_data_reg_update = 1;
        counter_reg_inc = 1;
        bram_node_addr_reg_inc = 1;
        if (counter_reg == 15) begin
          sub_in_valid = 1;
          S_next = S_SUB;
        end
        else S_next = S_NODE_LOAD;
      end
      S_SUB: begin
        if (sub_out_valid[0]) begin
          div_in_valid = 1;
          S_next = S_DIV;
        end
        else S_next = S_SUB;
      end
      S_DIV: begin
        if (div_out_valid[0]) begin
          l_entry_x = dir_x[31] ? div_out[ 1] : div_out[ 0];     
          l_entry_y = dir_y[31] ? div_out[ 3] : div_out[ 2];     
          l_entry_z = dir_z[31] ? div_out[ 5] : div_out[ 4];     
          l_exit_x  = dir_x[31] ? div_out[ 0] : div_out[ 1];     
          l_exit_y  = dir_y[31] ? div_out[ 2] : div_out[ 3];     
          l_exit_z  = dir_z[31] ? div_out[ 4] : div_out[ 5];     
          r_entry_x = dir_x[31] ? div_out[ 7] : div_out[ 6];     
          r_entry_y = dir_y[31] ? div_out[ 9] : div_out[ 8];     
          r_entry_z = dir_z[31] ? div_out[11] : div_out[10];     
          r_exit_x  = dir_x[31] ? div_out[ 6] : div_out[ 7];     
          r_exit_y  = dir_y[31] ? div_out[ 8] : div_out[ 9];     
          r_exit_z  = dir_z[31] ? div_out[10] : div_out[11];   
          entry_exit_xyz_reg_update = 1;
          less_in_valid = 1;
          less_a[0] = 0;
          less_b[0] = l_entry_x;
          less_a[1] = t_reg;
          less_b[1] = l_exit_x;
          less_a[2] = 0;
          less_b[2] = r_entry_x;
          less_a[3] = t_reg;
          less_b[3] = r_exit_x;
          S_next = S_MINMAX_A;
        end
        else S_next = S_DIV;
      end
      S_MINMAX_A: begin
        if (less_out_valid[0]) begin
          l_entry = less_out[0] ? l_entry_x_reg : 0;
          l_exit = less_out[1] ? t_reg : l_exit_x_reg;
          r_entry = less_out[2] ? r_entry_x_reg : 0;
          r_exit = less_out[3] ? t_reg : r_exit_x_reg;
          entry_exit_reg_update = 1;
          less_in_valid = 1;
          less_a[0] = l_entry;
          less_b[0] = l_entry_y_reg;
          less_a[1] = l_exit;
          less_b[1] = l_exit_y_reg;
          less_a[2] = r_entry;
          less_b[2] = r_entry_y_reg;
          less_a[3] = r_exit;
          less_b[3] = r_exit_y_reg;
          S_next = S_MINMAX_B;
        end
        else S_next = S_MINMAX_A;
      end
      S_MINMAX_B: begin
        if (less_out_valid[0]) begin
          l_entry = less_out[0] ? l_entry_y_reg : l_entry_reg;
          l_exit = less_out[1] ? l_exit_reg : l_exit_y_reg;
          r_entry = less_out[2] ? r_entry_y_reg : r_entry_reg;
          r_exit = less_out[3] ? r_exit_reg : r_exit_y_reg;
          entry_exit_reg_update = 1;
          less_in_valid = 1;
          less_a[0] = l_entry;
          less_b[0] = l_entry_z_reg;
          less_a[1] = l_exit;
          less_b[1] = l_exit_z_reg;
          less_a[2] = r_entry;
          less_b[2] = r_entry_z_reg;
          less_a[3] = r_exit;
          less_b[3] = r_exit_z_reg;
          S_next = S_MINMAX_C;
        end
        else S_next = S_MINMAX_B;
      end
      S_MINMAX_C: begin
        if (less_out_valid[0]) begin
          l_entry = less_out[0] ? l_entry_z_reg : l_entry_reg;
          l_exit = less_out[1] ? l_exit_reg : l_exit_z_reg;
          r_entry = less_out[2] ? r_entry_z_reg : r_entry_reg;
          r_exit = less_out[3] ? r_exit_reg : r_exit_z_reg;
          entry_exit_reg_update = 1;
          less_in_valid = 1;
          less_a[0] = l_entry;
          less_b[0] = l_exit;
          less_a[1] = r_entry;
          less_b[1] = r_exit;
          less_a[2] = l_entry;
          less_b[2] = r_entry;
          S_next = S_HIT;
        end
        else S_next = S_MINMAX_C;
      end
      S_HIT: begin
        if (less_out_valid[0]) begin
          hit_reg_update = 1;
          if (less_out[0] && l_num_trigs_reg != 0) begin
            bram_trig_addr_reg_update_l = 1;
            S_next = S_TRIG_LEFT_ADDR;
          end
          else if (less_out[1] && r_num_trigs_reg != 0) begin
            bram_trig_addr_reg_update_r = 1;
            S_next = S_TRIG_RIGHT_ADDR;
          end
          else S_next = S_STEP;
        end
        else S_next = S_HIT;
      end
      S_TRIG_LEFT_ADDR: begin
        l_hit_reg_reset = 1;
        l_num_trigs_reg_dec = 1;
        counter_reg_reset = 1;
        bram_trig_addr_reg_inc = 1;
        S_next = S_TRIG_LEFT_LOAD;
      end
      S_TRIG_LEFT_LOAD: begin
        trig_data_reg_update = 1;
        counter_reg_inc = 1;
        if (counter_reg == 11) begin
          ist_valid = 1;
          S_next = S_TRIG_LEFT_IST;
        end
        else begin
          bram_trig_addr_reg_inc = 1;
          S_next = S_TRIG_LEFT_LOAD;
        end
      end
      S_TRIG_LEFT_IST: begin
        if (ist_done) begin
          if (ist_intersected) intersect_result_reg_update = 1;
          if (l_num_trigs_reg == 0) begin
            if (r_hit_reg && r_num_trigs_reg != 0) begin
              bram_trig_addr_reg_update_r = 1;
              S_next = S_TRIG_RIGHT_ADDR;
            end
            else S_next = S_STEP;
          end
          else S_next = S_TRIG_LEFT_ADDR;
        end
        else S_next = S_TRIG_LEFT_IST;
      end
      S_TRIG_RIGHT_ADDR: begin
        r_hit_reg_reset = 1;
        r_num_trigs_reg_dec = 1;
        counter_reg_reset = 1;
        bram_trig_addr_reg_inc = 1;
        S_next = S_TRIG_RIGHT_LOAD;
      end
      S_TRIG_RIGHT_LOAD: begin
        trig_data_reg_update = 1;
        counter_reg_inc = 1;
        if (counter_reg == 11) begin
          ist_valid = 1;
          S_next = S_TRIG_RIGHT_IST;
        end
        else begin
          bram_trig_addr_reg_inc = 1;
          S_next = S_TRIG_RIGHT_LOAD;
        end
      end
      S_TRIG_RIGHT_IST: begin
        if (ist_done) begin
          if (ist_intersected) intersect_result_reg_update = 1;
          if (r_num_trigs_reg == 0) S_next = S_STEP;
          else S_next = S_TRIG_RIGHT_ADDR;
        end
        else S_next = S_TRIG_RIGHT_IST;
      end
      S_STEP: begin
        if (l_hit_reg) begin
          S_next = S_NODE_ADDR;
          if (r_hit_reg) begin
            stack_addr = stack_size_reg;
            stack_we = 1;
            stack_size_reg_inc = 1;
            if (l_first_reg) begin
              bram_node_addr_reg_update_l = 1;
              stack_din = r_left_node_or_trig_addr_reg;
            end
            else begin
              bram_node_addr_reg_update_r = 1;
              stack_din = l_left_node_or_trig_addr_reg;
            end
          end
          else bram_node_addr_reg_update_l = 1;
        end
        else if (r_hit_reg) begin
          bram_node_addr_reg_update_r = 1;
          S_next = S_NODE_ADDR;
        end
        else begin
          if (stack_size_reg == 0) begin
            done = 1;
            S_next = S_INIT;
          end
          else begin
            stack_addr = stack_size_reg - 1;
            stack_size_reg_dec = 1;
            bram_node_addr_reg_update_stack = 1;
            S_next = S_NODE_ADDR;
          end
        end
      end
    endcase
  end
  
  always @(posedge clk) begin
    S <= S_next;
  end
  
  always @(posedge clk) begin
    if (intersect_result_reg_init) begin
      intersected_reg <= 0;
      t_reg <= tmax;
    end
    else if (intersect_result_reg_update) begin
      intersected_reg <= 1;
      t_reg <= ist_t;
      u_reg <= ist_u;
      v_reg <= ist_v;
      n_x_reg <= ist_n_x_reg;
      n_y_reg <= ist_n_y_reg;
      n_z_reg <= ist_n_z_reg;
    end
  end
  
  always @(posedge clk) begin
    if (counter_reg_reset) counter_reg <= 0;
    else if (counter_reg_inc) counter_reg <= counter_reg + 1;
  end
  
  always @(posedge clk) begin
    if (stack_size_reg_reset) stack_size_reg <= 0;
    else if (stack_size_reg_inc) stack_size_reg <= stack_size_reg + 1;
    else if (stack_size_reg_dec) stack_size_reg <= stack_size_reg - 1;
  end
  
  always @(posedge clk) begin
    if (node_data_reg_update) begin
      case (counter_reg) 
         0: l_bound_x_min_reg            <= bram_node_dout;
         1: l_bound_x_max_reg            <= bram_node_dout;
         2: l_bound_y_min_reg            <= bram_node_dout;
         3: l_bound_y_max_reg            <= bram_node_dout;
         4: l_bound_z_min_reg            <= bram_node_dout;
         5: l_bound_z_max_reg            <= bram_node_dout;
         6: l_num_trigs_reg              <= bram_node_dout[7:0];
         7: l_left_node_or_trig_addr_reg <= bram_node_dout[13:0];
         8: r_bound_x_min_reg            <= bram_node_dout;
         9: r_bound_x_max_reg            <= bram_node_dout;
        10: r_bound_y_min_reg            <= bram_node_dout;
        11: r_bound_y_max_reg            <= bram_node_dout;
        12: r_bound_z_min_reg            <= bram_node_dout;
        13: r_bound_z_max_reg            <= bram_node_dout;
        14: r_num_trigs_reg              <= bram_node_dout[7:0];
        15: r_left_node_or_trig_addr_reg <= bram_node_dout[13:0];
      endcase
    end
    else if (l_num_trigs_reg_dec) l_num_trigs_reg <= l_num_trigs_reg - 1;
    else if (r_num_trigs_reg_dec) r_num_trigs_reg <= r_num_trigs_reg - 1;
  end
  
  always @(posedge clk) begin
    if (trig_data_reg_update) begin
      case (counter_reg)
         0: ist_p0_x_reg <= bram_trig_dout;
         1: ist_p0_y_reg <= bram_trig_dout;
         2: ist_p0_z_reg <= bram_trig_dout;
         3: ist_e1_x_reg <= bram_trig_dout;
         4: ist_e1_y_reg <= bram_trig_dout;
         5: ist_e1_z_reg <= bram_trig_dout;
         6: ist_e2_x_reg <= bram_trig_dout;
         7: ist_e2_y_reg <= bram_trig_dout;
         8: ist_e2_z_reg <= bram_trig_dout;
         9: ist_n_x_reg  <= bram_trig_dout;
        10: ist_n_y_reg  <= bram_trig_dout;
        11: ist_n_z_reg  <= bram_trig_dout;
      endcase
    end
  end
  
  always @(posedge clk) begin
    if (entry_exit_xyz_reg_update) begin
      l_entry_x_reg <= l_entry_x;     
      l_entry_y_reg <= l_entry_y;     
      l_entry_z_reg <= l_entry_z;     
      l_exit_x_reg <= l_exit_x;     
      l_exit_y_reg <= l_exit_y;     
      l_exit_z_reg <= l_exit_z;     
      r_entry_x_reg <= r_entry_x;     
      r_entry_y_reg <= r_entry_y;     
      r_entry_z_reg <= r_entry_z;     
      r_exit_x_reg <= r_exit_x;     
      r_exit_y_reg <= r_exit_y;     
      r_exit_z_reg <= r_exit_z;     
    end
  end
  
  always @(posedge clk) begin
    if (entry_exit_reg_update) begin
      l_entry_reg <= l_entry;
      l_exit_reg <= l_exit; 
      r_entry_reg <= r_entry;
      r_exit_reg <= r_exit; 
    end
  end
  
  always @(posedge clk) begin
    if (hit_reg_update) begin
      l_hit_reg <= less_out[0];
      r_hit_reg <= less_out[1];
      l_first_reg <= less_out[2];
    end
    else if (l_hit_reg_reset) l_hit_reg <= 0;
    else if (r_hit_reg_reset) r_hit_reg <= 0;
  end
  
  always @(posedge clk) begin
    if (bram_node_addr_reg_init) bram_node_addr_reg <= 8;
    else if (bram_node_addr_reg_inc) bram_node_addr_reg <= bram_node_addr_reg + 1;
    else if (bram_node_addr_reg_update_l) bram_node_addr_reg <= l_left_node_or_trig_addr_reg;
    else if (bram_node_addr_reg_update_r) bram_node_addr_reg <= r_left_node_or_trig_addr_reg;
    else if (bram_node_addr_reg_update_stack) bram_node_addr_reg <= stack_dout;
  end
  
  always @(posedge clk) begin
    if (bram_trig_addr_reg_inc) bram_trig_addr_reg <= bram_trig_addr_reg + 1;
    else if (bram_trig_addr_reg_update_l) bram_trig_addr_reg <= l_left_node_or_trig_addr_reg;
    else if (bram_trig_addr_reg_update_r) bram_trig_addr_reg <= r_left_node_or_trig_addr_reg;
  end
  
  always @(posedge clk) begin
    if (S == S_NODE_LOAD && counter_reg == 0) $strobe("load node: %d", bram_node_addr_reg/8);
    if ((S == S_TRIG_LEFT_LOAD || S == S_TRIG_RIGHT_LOAD) && counter_reg == 0) $strobe("load trig: %d", bram_trig_addr_reg/12);
    if (ist_done && ist_intersected) $strobe("triangle intersected");
    if (stack_we) $strobe("push node"); 
    if (bram_node_addr_reg_update_stack) $strobe("pop node"); 
  end

endmodule
