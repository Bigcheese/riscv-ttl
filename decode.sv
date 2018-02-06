module decode(clk, inst, opcode, imm, rs1, rs2, rd, func3, invalid);
  input clk;
  input [31:0] inst;
  output [4:0] opcode;
  output [31:0] imm;
  output [4:0] rs1;
  output [4:0] rs2;
  output [4:0] rd;
  output [2:0] func3;
  output invalid;
  
  wire [31:0] immI;
  assign immI[31:11] = inst[31];
  assign immI[10:5] = inst[30:25];
  assign immI[4:1] = inst[24:21];
  assign immI[0] = inst[20];
  
  wire [31:0] immS;
  assign immS[31:11] = inst[31];
  assign immS[10:5] = inst[30:25];
  assign immS[4:1] = inst[11:8];
  assign immS[0] = inst[7];
  
  wire [31:0] immB;
  assign immB[31:12] = inst[31];
  assign immB[11] = inst[7];
  assign immB[10:5] = inst[30:25];
  assign immB[4:1] = inst[11:8];
  assign immB[0] = 0;
  
  wire [31:0] immU;
  assign immU[31:12] = inst[31:12];
  assign immU[11:0] = 0;
  
  wire [31:0] immJ;
  assign immJ[31:20] = inst[31];
  assign immJ[19:12] = inst[19:12];
  assign immJ[11] = inst[20];
  assign immJ[10:5] = inst[30:25];
  assign immJ[4:1] = inst[24:21];
  assign immJ[0] = 0;
  
  assign rs2 = inst[24:20];
  assign rs1 = inst[19:15];
  assign rd = inst[11:7];
  
  assign func3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];
  
  assign opcode = inst[6:2];
  
  wire R = opcode == 5'b01100 ? 1 : 0;
  wire I = (opcode == 5'b00000 || opcode == 5'b00100) ? 1 : 0;
  wire S = opcode == 5'b01000 ? 1 : 0;
  wire B = opcode == 5'b11000 ? 1 : 0;
  wire U = (opcode == 5'b01101 || opcode == 5'b00101) ? 1 : 0;
  wire J = opcode == 5'b11011 ? 1 : 0;
  
  assign imm = I ? immI :
               S ? immS :
               B ? immB :
               U ? immU :
               J ? immJ : 'x;

  assign invalid = !(R | I | S | B| U | J) || inst[1:0] != 2'b11;
endmodule
