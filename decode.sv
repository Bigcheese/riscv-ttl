module decode(input [31:0] inst, output [4:0] opcode, output [31:0] imm,
              output [4:0] rs1, output [4:0] rs2, output [4:0] rd, output [2:0] func3,
              output [6:0] func7, output [11:0] func12, output ecall, output ebreak, output mret, output branch,
              output invalid);
  wire [31:0] immI = {{21{inst[31]}}, inst[30:20]};

  wire [31:0] immS = {{21{inst[31]}}, inst[30:25], inst[11:7]};

  wire [31:0] immB = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

  wire [31:0] immU = {inst[31:12], 12'b0};

  wire [31:0] immJ = {{21{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

  wire [31:0] immZ = {27'b0, rs1};

  assign rs2 = inst[24:20];
  assign rs1 = inst[19:15];
  assign rd = inst[11:7];

  assign func3 = inst[14:12];
  assign func7 = inst[31:25];
  assign func12 = inst[31:20];

  assign opcode = inst[6:2];

  wire R = opcode == 5'b01100 ? 1 : 0;
  wire I = (opcode == 5'b00000 || opcode == 5'b00100 || opcode == 5'b11001) ? 1 : 0;
  wire S = opcode == 5'b01000 ? 1 : 0;
  wire B = opcode == 5'b11000 ? 1 : 0;
  wire U = (opcode == 5'b01101 || opcode == 5'b00101) ? 1 : 0;
  wire J = opcode == 5'b11011 ? 1 : 0;
  wire Z = opcode == 5'b11100;
  wire NA = opcode == 5'b00011;

  assign imm = I ? immI :
               S ? immS :
               B ? immB :
               U ? immU :
               J ? immJ :
               Z ? immZ : 'x;

  wire system0 = opcode == 5'b11100 && func3 == 0;
  assign ecall = system0 && func7 == 0 && rs2 == 0;
  assign ebreak = system0 && func7 == 0 && rs2 == 1;
  assign mret = system0 && func7 == 7'b0011000 && rs2 == 5'b00010;
  assign branch = opcode == 5'b11011 || opcode == 5'b11001 || opcode == 5'b11000;

  assign invalid = !(R | I | S | B| U | J | Z | NA) || inst[1:0] != 2'b11;
endmodule
