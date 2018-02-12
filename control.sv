module control(
    input clk,
    inout [31:0] bus,
    inout [31:0] addr,
    input reset,
    output [4:0] reg_idx,
    output pc_addr, output pc_bus, output pc_inc, output pc_write,
    output mem_read, output mem_write, output [3:0] mem_size,
    output reg_en, output reg_write,
    output a_bus, output a_addr, output a_write, output b_bus,
    output b_addr, output b_write,
    output alu_bus, output alu_addr, output [2:0] alu_op, output alu_sub, output alu_sra,
    input alu_eq, input alu_lt, input alu_ltu, input alu_ge, input alu_geu
  );

  reg [31:0] control_lines;
  reg [63:0] instret;

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
    ALU_ADD = 1 << 18,
    LOAD_STORE = 1 << 19,

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

  wire alu_add = control_lines[18];

  wire load_store = control_lines[19];

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
  wire [6:0] func7;
  wire invalid;

  decode d(.clk(clk), .inst(inst), .opcode(opcode), .imm(imm),
    .rs1(rs1), .rs2(rs2), .rd(rd), .func3(func3), .func7(func7), .invalid(invalid));

  wire [31:0] imm_out = (opcode == 5'b00100 && (func3 == 3'b001 || func3 == 3'b101)) ? {27'b0, imm[4:0]} : imm;

  assign bus = imm_bus ? imm_out : 'z;

  assign mem_size = load_store ? {func3 == 3'b000, func3 == 3'b100, func3 == 3'b001, func3 == 3'b101} : 4'b0;

  assign alu_op = alu_add ? 3'b000 : func3;

  assign alu_sub = opcode == 5'b01100 && func7[5];

  assign alu_sra = (opcode == 5'b00100 || opcode == 5'b01100) && (func3 == 3'b001 || func3 == 3'b101) && inst[30];

  assign reg_idx = r_idx_rs1 ? rs1 :
                   r_idx_rs2 ? rs2 :
                   r_idx_rd ? rd : 'z;

  always @(posedge reset) begin
    state <= 0;
    inst <= 0;
    control_lines <= 0;
    instret <= 0;
  end

  wire cmp = func3 == 3'b000 ? alu_eq :
             func3 == 3'b001 ? !alu_eq :
             func3 == 3'b100 ? alu_lt :
             func3 == 3'b110 ? alu_ltu :
             func3 == 3'b101 ? alu_ge :
             func3 == 3'b111 ? alu_geu : 'z;

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
    // auipc
    ops[5'b00101][1] = PC_BUS | A_WRITE | STATE_INC;
    ops[5'b00101][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b00101][3] = ALU_BUS | ALU_ADD | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
    // jal
    ops[5'b11011][1] = PC_BUS | A_WRITE | STATE_INC;
    ops[5'b11011][2] = IMM_BUS | B_WRITE | STATE_INC | PC_INC;
    ops[5'b11011][3] = PC_BUS | REG_IDX_RD | REG_WRITE | STATE_INC;
    ops[5'b11011][4] = ALU_BUS | ALU_ADD | PC_WRITE | STATE_RESET;
    // jalr
    ops[5'b11001][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC | PC_INC;
    ops[5'b11001][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b11001][3] = PC_BUS | REG_IDX_RD | REG_WRITE | STATE_INC;
    ops[5'b11001][4] = ALU_BUS | ALU_ADD | PC_WRITE | STATE_RESET;
    // branch
    ops[5'b11000][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b11000][2] = REG_IDX_RS2 | REG_BUS | B_WRITE | STATE_INC;
    ops[5'b11000][3] = PC_BUS | A_WRITE | STATE_INC | BRANCH_STUFF;
    ops[5'b11000][4] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b11000][5] = ALU_BUS | ALU_ADD | PC_WRITE | STATE_RESET;
    // load
    ops[5'b00000][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b00000][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b00000][3] = ALU_ADDR | ALU_ADD | MEM_READ | LOAD_STORE | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
    // store
    ops[5'b01000][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b01000][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b01000][3] = ALU_ADDR | ALU_ADD | REG_IDX_RS2 | REG_BUS | MEM_WRITE | STATE_RESET | PC_INC;
    // alu immediate
    ops[5'b00100][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b00100][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b00100][3] = ALU_BUS | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
    // alu register
    ops[5'b01100][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b01100][2] = REG_IDX_RS2 | REG_BUS | B_WRITE | STATE_INC;
    ops[5'b01100][3] = ALU_BUS | REG_IDX_RD | REG_WRITE | STATE_RESET | PC_INC;
    // fence
    ops[5'b00011][1] = STATE_RESET | PC_INC;
    // system
    ops[5'b11100][1] = 0; // infloop
  end

  always @(negedge clk) begin
    if (state == 0)
      instret <= instret + 1;
    control_lines <= ops[opcode][state];
  end
endmodule
