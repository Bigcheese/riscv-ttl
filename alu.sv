module alu(
    output [31:0] bus,
    output [31:0] addr,
    input [31:0] a,
    input [31:0] b,
    input bus_en,
    input addr_en,
    input [2:0] op,
    output alu_eq,
    output alu_lt,
    output alu_ge
  );
  
  typedef enum bit [2:0] {ADD = 3'b000, SL = 3'b001, SLT = 3'b010, SLTU = 3'b011,
                          XOR = 3'b100,  OR = 3'b110, SR = 3'b101, AND = 3'b111} OP;

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
  
  assign result = op == ADD ? add :
                  op == SL ? sl :
                  op == SLT ? lt :
                  op == SLTU ? lt :
                  op == XOR ? xor_ :
                  op == OR ? or_ :
                  op == SR ? sr :
                  op == AND ? and_ : 'x;

endmodule
