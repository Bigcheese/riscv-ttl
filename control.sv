module control(
    input clk,
    inout [31:0] bus,
    inout [31:0] addr,
    input reset,
    output [4:0] reg_idx,
    output pc_addr, output pc_bus, output pc_inc, output pc_write,
    output mem_read, output mem_write,
    output reg_en, output reg_write,
    output a_bus, output a_addr, output a_write, output b_bus,
    output b_addr, output b_write,
    output alu_bus, output alu_addr, output [3:0] alu_op,
    input alu_eq, input alu_lt, input alu_ge
  );

  reg [31:0] control_lines;

  typedef enum {
    INST_WRITE = 1 << 0,
    IMM_BUS = 1 << 1,
    PC_ADDR = 1 << 2,
    PC_BUS = 1 << 3,
    PC_INC = 1 << 4,
    PC_WRITE = 1 << 5,
    MEM_READ = 1 << 6,
    MEM_WRITE = 1 << 7,
    REG_BUS = 1 << 8,
    REG_WRITE = 1 << 9,
    A_BUS = 1 << 10,
    A_ADDR = 1 << 11,
    A_WRITE = 1 << 12,
    B_BUS = 1 << 13,
    B_ADDR = 1 << 14,
    B_WRITE = 1 << 15,
    ALU_BUS = 1 << 16,
    ALU_ADDR = 1 << 17,

    REG_IDX_RS1 = 1 << 20,
    REG_IDX_RS2 = 1 << 21,
    REG_IDX_RD = 1 << 22,

    BRANCH_STUFF = 1 << 29,
    STATE_RESET = 1 << 30,
    STATE_INC = 1 << 31
  } ControlFlags;

  assign pc_addr = control_lines[2];
  assign pc_bus = control_lines[3];
  assign pc_write = control_lines[5];
  assign mem_read = control_lines[6];
  assign mem_write = control_lines[7];
  assign reg_en = control_lines[8];
  assign reg_write = control_lines[9];
  assign a_bus = control_lines[10];
  assign a_addr = control_lines[11];
  assign a_write = control_lines[12];
  assign b_bus = control_lines[13];
  assign b_addr = control_lines[14];
  assign b_write = control_lines[15];
  assign alu_bus = control_lines[16];
  assign alu_addr = control_lines[17];

  reg [2:0] state;
  reg [31:0] inst;
  wire inst_write = control_lines[0];
  wire imm_bus = control_lines[1];

  wire r_idx_rs1 = control_lines[20];
  wire r_idx_rs2 = control_lines[21];
  wire r_idx_rd = control_lines[22];

  wire branch_stuff = control_lines[29];
  wire state_reset;
  wire state_inc;

  wire [4:0] opcode;
  wire [31:0] imm;
  wire [4:0] rs1, rs2, rd;
  wire [2:0] func3;
  wire invalid;

  decode d(.clk(clk), .inst(inst), .opcode(opcode), .imm(imm),
    .rs1(rs1), .rs2(rs2), .rd(rd), .func3(func3), .invalid(invalid));

  assign bus = imm_bus ? imm : 'z;

  assign alu_op = 5;

  assign reg_idx = r_idx_rs1 ? rs1 :
                   r_idx_rs2 ? rs2 :
                   r_idx_rd ? rd : 'z;

  always @(posedge reset) begin
    state <= 0;
    inst <= 0;
    control_lines <= 0;
  end

  wire cmp = func3 == 3'b000 ? alu_eq :
             func3 == 3'b001 ? !alu_eq :
             func3 == 3'b1?0 ? alu_lt :
             func3 == 3'b1?1 ? alu_ge : 'z;

  assign state_reset = branch_stuff ? (cmp ? 0 : 1) : control_lines[30]; 
  assign state_inc = branch_stuff ? (cmp ? 1 : 0) : control_lines[31];
  assign pc_inc = branch_stuff ? (cmp ? 0 : 1) : control_lines[4];

  always @(posedge clk) begin
    if (inst_write)
      inst <= bus;
    if (state_inc)
      state <= state + 1;
    if (state_reset)
      state <= 0;
  end

  reg [31:0] ops[64][6];
  integer i;

  initial begin
    for (i = 0; i < 64; i = i + 1)
      ops[i][0] = PC_ADDR | MEM_READ | INST_WRITE | STATE_INC;
    // lui
    ops[5'b01101][1] = IMM_BUS | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
    // branch
    ops[5'b11000][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b11000][2] = REG_IDX_RS2 | REG_BUS | B_WRITE | STATE_INC;
    ops[5'b11000][3] = PC_BUS | A_WRITE | STATE_INC | BRANCH_STUFF;
    ops[5'b11000][4] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b11000][5] = ALU_BUS | PC_WRITE | STATE_RESET;
    // load
    ops[5'b00000][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b00000][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b00000][3] = ALU_ADDR | MEM_READ | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
    // store
    ops[5'b01000][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b01000][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b01000][3] = ALU_ADDR | REG_IDX_RS2 | REG_BUS | MEM_WRITE | STATE_RESET | PC_INC;
    // alu immediate
    ops[5'b00100][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b00100][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b00100][3] = ALU_BUS | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
    // alu register
    ops[5'b01100][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b01100][2] = REG_IDX_RS2 | REG_BUS | B_WRITE | STATE_INC;
    ops[5'b01100][3] = ALU_BUS | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
  end

  always @(negedge clk) begin
    control_lines <= ops[opcode][state];
  end
endmodule
