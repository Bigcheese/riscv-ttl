module alu(
    output [31:0] bus,
    output [31:0] addr,
    input [31:0] a,
    input [31:0] b,
    input bus_en,
    input addr_en,
    input [2:0] op,
    input sub_en,
    input sra_en,
    output alu_eq,
    output alu_lt,
    output alu_ltu,
    output alu_ge,
    output alu_geu
  );

  typedef enum bit [2:0] {ADD = 3'b000, SL = 3'b001, SLT = 3'b010, SLTU = 3'b011,
                          XOR = 3'b100,  OR = 3'b110, SR = 3'b101, AND = 3'b111} OP;

  wire [31:0] result;

  wire [31:0] or_ = a | b;
  wire [31:0] xor_ = a ^ b;
  wire [31:0] and_ = a & b;
  wire [31:0] sl = a << b[4:0];
  wire [31:0] sr = a >> b[4:0];
  wire [31:0] sra = $signed(a) >>> b[4:0];
  wire [31:0] add = a + b;
  wire [31:0] sub = $signed(a) - $signed(b);

  wire eq = a == b;
  wire neq = !eq;
  wire lt = $signed(a) < $signed(b);
  wire ltu = a < b;
  wire ge = $signed(a) >= $signed(b);

  assign alu_eq = eq;
  assign alu_lt = lt;
  assign alu_ltu = a < b;
  assign alu_ge = ge;
  assign alu_geu = a >= b;

  assign bus = bus_en ? result : 'z;
  assign addr = addr_en ? result : 'z;

  assign result = op == ADD ? (sub_en ? sub : add) :
                  op == SL ? sl :
                  op == SLT ? lt :
                  op == SLTU ? ltu :
                  op == XOR ? xor_ :
                  op == OR ? or_ :
                  op == SR ? (sra_en ? sra : sr ) :
                  op == AND ? and_ : 'x;

endmodule
