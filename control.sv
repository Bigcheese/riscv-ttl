module control(
    input clk,
    input reset,
    input [31:0] addr,
    input [31:0] bus,
    output [31:0] control_aout,
    output [31:0] control_bout,
    output control_bus,
    output control_addr,
    output [4:0] reg_idx,
    output mem_read, output mem_write, output [3:0] mem_size,
    output reg mem_addr_ready, input mem_data_ready,
    output reg_en, output reg_write,
    output a_bus, output a_addr, output a_write, output b_bus,
    output b_addr, output b_write,
    output alu_bus, output alu_addr, output [2:0] alu_op, output alu_sub, output alu_sra,
    input alu_eq, input alu_lt, input alu_ltu, input alu_ge, input alu_geu,
    input eip
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

    A_WRITE = 1 << 12,

    B_WRITE = 1 << 15,
    ALU_BUS = 1 << 16,
    ALU_ADDR = 1 << 17,
    ALU_ADD = 1 << 18,
    LOAD_STORE = 1 << 19,

    REG_IDX_RS1 = 1 << 20,
    REG_IDX_RS2 = 1 << 21,
    REG_IDX_RD = 1 << 22,

    CSR_READ = 1 << 23,
    CSR_WRITE = 1 << 24,
    SYSTEM0 = 1 << 25,

    SYSTEM = 1 << 28,
    BRANCH_STUFF = 1 << 29,
    STATE_RESET = 1 << 30,
    STATE_INC = 1 << 31
  } ControlFlags;

  wire inst_write;
  wire imm_bus;

  wire pc_addr;
  wire pc_bus;
  wire pc_inc;
  wire pc_write;

  wire alu_add;

  wire load_store;

  wire r_idx_rs1;
  wire r_idx_rs2;
  wire r_idx_rd;

  wire csr_read;
  wire csr_write;
  wire system0;

  wire system;
  wire branch_stuff;

  reg [2:0] state;
  reg [31:0] inst;
  reg [31:0] pc;

  wire state_reset;
  wire state_inc;

  wire [4:0] opcode;
  wire [31:0] imm;
  wire [4:0] rs1, rs2, rd;
  wire [2:0] func3;
  wire [6:0] func7;
  wire [11:0] func12;
  wire [11:0] csr_addr;
  wire decode_invalid_inst;
  wire [4:0] trap_cause;
  wire trap;
  wire csr_inv;
  wire csr_invalid = csr_inv && func3 != 0;
  wire [31:0] csr_out;

  wire ecall;
  wire ebreak;
  wire mret;
  wire branch;

  wire ecallbreak_trap = (ecall || ebreak) && state == 1;

  wire [31:0] sys_control = ecall ? 0 :
                            ebreak ? 0 :
                            mret ? PC_WRITE | CSR_READ : 0;

  reg prev_eip;
  reg external_int;

  always @(posedge clk) begin
    if (reset) begin
      prev_eip <= 0;
      external_int <= 0;
    end else begin
      prev_eip <= eip;
      if (eip && !prev_eip)
        external_int <= 1;
      else if (take_external_interupt)
        external_int <= 0;
    end
  end

  wire take_external_interupt = external_int && state_reset && !branch;

  decode d(.inst(inst), .opcode(opcode), .imm(imm),
    .rs1(rs1), .rs2(rs2), .rd(rd), .func3(func3), .func7(func7), .func12(func12), .ecall, .ebreak, .mret, .branch,
    .invalid(decode_invalid_inst));
  csr_file csr(.clk, .rst(reset), .csr_addr, .addr, .bus, .pc, .csr_out, .read(csr_read), .write(csr_write),
    .write_type(func3[1:0]), .trap, .trap_cause, .take_external_interupt, .ret(mret), .invalid(csr_inv));

  wire [31:0] imm_out = (opcode == 5'b00100 && (func3 == 3'b001 || func3 == 3'b101)) ? {27'b0, imm[4:0]} : imm;

  assign control_bout = pc_bus | trap ? pc :
                        imm_bus ? imm_out :
                        csr_read ? csr_out :
                        'x;

  assign control_aout = pc_addr ? pc : 'x;

  assign control_bus = imm_bus | pc_bus | trap | csr_read;
  assign control_addr = pc_addr;

  assign mem_size = load_store ? {func3 == 3'b000, func3 == 3'b100, func3 == 3'b001, func3 == 3'b101} : 4'b0;

  assign alu_op = alu_add ? 3'b000 : func3;

  assign alu_sub = opcode == 5'b01100 && func7[5];

  assign alu_sra = (opcode == 5'b00100 || opcode == 5'b01100) && (func3 == 3'b001 || func3 == 3'b101) && inst[30];

  assign reg_idx = r_idx_rs1 ? rs1 :
                   r_idx_rs2 ? rs2 :
                   r_idx_rd ? rd : 'x;

  wire cmp = func3 == 3'b000 ? alu_eq :
             func3 == 3'b001 ? !alu_eq :
             func3 == 3'b100 ? alu_lt :
             func3 == 3'b110 ? alu_ltu :
             func3 == 3'b101 ? alu_ge :
             func3 == 3'b111 ? alu_geu : 'x;

  wire invalid_address = addr > 32'h80000 && (alu_addr || pc_addr);
  wire invalid_fetch_address = state == 0 && invalid_address;
  wire invalid_load_address = opcode[3] == 0 && load_store && invalid_address;
  wire invalid_store_address = opcode[3] == 1 && load_store && invalid_address;
  wire invalid_inst = decode_invalid_inst && state == 1; 
  wire misaliged_addr = load_store && (|addr[1:0] && mem_size == 0) ||
                        (addr[1:0] == 2'b11 && (mem_size[1] || mem_size[0]));

  assign trap = invalid_inst | invalid_fetch_address | invalid_load_address | invalid_store_address | csr_invalid |
                misaliged_addr | ecallbreak_trap | take_external_interupt;
  assign trap_cause = invalid_inst ? 2 :
                      invalid_fetch_address ? 1 :
                      invalid_load_address ? 5 :
                      invalid_store_address ? 7 :
                      csr_invalid ? 2 :
                      misaliged_addr ? (opcode[3] ? 6 : 4) :
                      ecall ? 11 :
                      ebreak ? 3 :
                      take_external_interupt ? 11 : 'x;

  assign csr_addr = mret ? 12'h341 : func12;

  assign inst_write = control_lines[0] & mem_data_ready;

  assign imm_bus = control_lines[1];

  assign pc_addr = control_lines[2];
  assign pc_bus = control_lines[3];
  assign pc_inc = branch_stuff ? (cmp ? 0 : 1) : control_lines[4];
  assign pc_write = control_lines[5];

  assign mem_read = control_lines[6];
  assign mem_write = control_lines[7] && !trap;

  assign reg_en = control_lines[8];
  assign reg_write = control_lines[9] && !trap && (mem_read ? mem_data_ready : 1);

  assign a_bus = control_lines[10];
  assign a_addr = control_lines[11];
  assign a_write = control_lines[12];

  assign b_bus = control_lines[13];
  assign b_addr = control_lines[14];
  assign b_write = control_lines[15];

  assign alu_bus = control_lines[16];
  assign alu_addr = control_lines[17];
  assign alu_add = control_lines[18];

  assign load_store = control_lines[19];

  assign r_idx_rs1 = control_lines[20];
  assign r_idx_rs2 = control_lines[21];
  assign r_idx_rd = control_lines[22];

  assign csr_read = control_lines[23];
  assign csr_write = control_lines[24];
  assign system0 = control_lines[25];

  assign system = control_lines[28];

  assign branch_stuff = control_lines[29];

  assign state_reset = (branch_stuff ? (cmp ? 0 : 1) : control_lines[30]) && (mem_read ? mem_data_ready : 1);
  assign state_inc = (branch_stuff ? (cmp ? 1 : 0) : control_lines[31]) && (mem_read ? mem_data_ready : 1);

  always @(posedge clk) begin
    if (reset) begin
      state <= 0;
      inst <= 0;
      pc <= 0;
      mem_addr_ready <= 0;
    end else begin
      if (inst_write && !trap)
        inst <= bus;
      if (state_inc && !trap)
        state <= state + 1;
      if (state_reset || trap)
        state <= 0;
      if (trap)
        pc <= 32'h4;
      else if (pc_inc)
        pc <= pc + 4;
      else if (pc_write)
        pc <= bus;
      mem_addr_ready <= (pc_addr | alu_addr) && !mem_data_ready && !trap;
    end
  end

  reg [31:0] ops[64][6];
  reg [31:0] sys_ops[8][4];
  integer i, j;

  initial begin
    for (i = 0; i < 64; i = i + 1)
      for (j = 0; j < 6; j = j + 1)
        ops[i][j] = 0;
    for (i = 0; i < 64; i = i + 1)
      ops[i][0] = PC_ADDR | MEM_READ | INST_WRITE | STATE_INC;
    for (i = 0; i < 8; i = i + 1)
      for (j = 0; j < 4; j = j + 1)
        sys_ops[i][j] = 0;
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
    ops[5'b00000][3] = ALU_ADDR | ALU_ADD | MEM_READ | LOAD_STORE | REG_IDX_RD | REG_WRITE | STATE_INC;
    ops[5'b00000][4] = STATE_RESET | PC_INC; // Allow a cycle for the memory read to complete.
    // store
    ops[5'b01000][1] = REG_IDX_RS1 | REG_BUS | A_WRITE | STATE_INC;
    ops[5'b01000][2] = IMM_BUS | B_WRITE | STATE_INC;
    ops[5'b01000][3] = ALU_ADDR | ALU_ADD | REG_IDX_RS2 | REG_BUS | LOAD_STORE | MEM_WRITE | STATE_RESET | PC_INC;
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
    ops[5'b11100][1] = SYSTEM;
    ops[5'b11100][2] = SYSTEM;
    ops[5'b11100][3] = SYSTEM;
    ops[5'b11100][4] = SYSTEM;
    ops[5'b11100][5] = SYSTEM;

    // mret
    sys_ops[3'b000][1] = SYSTEM0 | STATE_RESET;

    // read and write
    sys_ops[3'b001][1] = CSR_READ | A_WRITE | STATE_INC; // save existing value
    sys_ops[3'b001][2] = REG_IDX_RS1 | REG_BUS | CSR_WRITE | STATE_INC; // write new value
    sys_ops[3'b001][3] = REG_IDX_RD | REG_WRITE | A_BUS | STATE_RESET | PC_INC; // copy saved value to dest

    // read and set bits
    sys_ops[3'b010][1] = CSR_READ | A_WRITE | STATE_INC; // save existing value
    sys_ops[3'b010][2] = REG_IDX_RS1 | REG_BUS | CSR_WRITE | STATE_INC; // write new value
    sys_ops[3'b010][3] = REG_IDX_RD | REG_WRITE | A_BUS | STATE_RESET | PC_INC; // copy saved value to dest

    // read and clear bits
    sys_ops[3'b011][1] = CSR_READ | A_WRITE | STATE_INC; // save existing value
    sys_ops[3'b011][2] = REG_IDX_RS1 | REG_BUS | CSR_WRITE | STATE_INC; // write new value
    sys_ops[3'b011][3] = REG_IDX_RD | REG_WRITE | A_BUS | STATE_RESET | PC_INC; // copy saved value to dest

    // read and write imm
    sys_ops[3'b101][1] = REG_IDX_RD | REG_WRITE | CSR_READ | STATE_INC;
    sys_ops[3'b101][2] = IMM_BUS | CSR_WRITE | STATE_RESET | PC_INC;

    // read and set bits imm
    sys_ops[3'b110][1] = REG_IDX_RD | REG_WRITE | CSR_READ | STATE_INC;
    sys_ops[3'b110][2] = IMM_BUS | CSR_WRITE | STATE_RESET | PC_INC;

    // read and clear bits imm
    sys_ops[3'b111][1] = REG_IDX_RD | REG_WRITE | CSR_READ | STATE_INC;
    sys_ops[3'b111][2] = IMM_BUS | CSR_WRITE | STATE_RESET | PC_INC;
  end

  always @(negedge clk) begin
    if (reset) begin
      control_lines <= 0;
      instret <= 0;
    end else begin 
      if (state == 0)
        instret <= instret + 1;
      if (trap)
        control_lines <= 0;
      else
        control_lines <= (ops[opcode][state] & SYSTEM ?
                          ops[opcode][state] | sys_ops[func3][state] : ops[opcode][state]) |
                         (sys_ops[func3][state] & SYSTEM0 ? sys_control : 0);
    end
  end
endmodule
