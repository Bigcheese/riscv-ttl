module alu(
    output [31:0] bus,
    output [31:0] addr,
    input [31:0] a,
    input [31:0] b,
    input bus_en,
    input addr_en,
    input [3:0] op,
    output alu_eq,
    output alu_lt,
    output alu_ge
  );
  
  enum {OR, XOR, AND, SL, SR, ADD, SUB} OP;

  wire [31:0] result;
  
  wire [31:0] or_ = a | b;
  wire [31:0] xor_ = a ^ b;
  wire [31:0] and_ = a & b;
  wire [31:0] sl = a << b;
  wire [31:0] sr = a >> b;
  wire [31:0] add = a + b;
  wire [31:0] sub = a - b;

  wire eq = a == b;
  wire neq = !eq;
  wire lt = a < b;
  wire ge = a >= b;
  
  assign alu_eq = eq;
  assign alu_lt = lt;
  assign alu_ge = ge;

  assign bus = bus_en ? result : 'z;
  assign addr = addr_en ? result : 'z;
  
  assign result = op == OR ? or_ : 
                  op == XOR ? xor_ :
                  op == AND ? and_ :
                  op == SL ? sl :
                  op == SR ? sr :
                  op == ADD ? add :
                  op == SUB ? sub : 'x;
  
endmodule
