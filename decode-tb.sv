module decode_tb;
  reg clk;
  reg [31:0] inst;
  reg [31:0] imm;
  reg [4:0] rs1;
  reg [4:0] rs2;
  reg [4:0] rd;
  reg invalid;
  decode d(clk, inst, imm, rs1, rs2, rd, invalid);
  
  initial begin
    $dumpfile("decode-tb.dmp");
    $dumpvars(0);
    $monitor("opcode=%b, imm=%b, rs1=%d, rs2=%d, rd=%d, invalid=%b, %b%b%b%b%b%b", d.opcode, imm, rs1, rs2, rd, invalid, d.R, d.I, d.S, d.B, d.U, d.J);
    clk = 0;
    #1 inst = 32'b0000000_00000_00000_000_00000_0000000;
    #1 inst = 32'b1000000_00000_00000_001_00001_0110111;
  end
endmodule
