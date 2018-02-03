module mem(addr, bus, write, read);
  input wire [31:0] addr;
  inout wire [31:0] bus;
  input wire write;
  input wire read;

  reg [7:0] mem[4096];
  reg [31:0] data_out;

  assign bus = read ? data_out : 'z;

  always @(write or read) begin
    if (write) begin
      mem[addr] <= bus[7:0];
      mem[addr + 1] <= bus[15:8];
      mem[addr + 2] <= bus[23:16];
      mem[addr + 3] <= bus[31:24];
    end else if (read) begin
      data_out[7:0] <= mem[addr];
      data_out[15:8] <= mem[addr + 1];
      data_out[23:16] <= mem[addr + 1];
      data_out[31:24] <= mem[addr + 1];
    end
  end
endmodule

module rv(clk, bus, addr, rst);
  inout wire [31:0] bus;
  inout wire [31:0] addr;
  input wire rst;
  input wire clk;
  reg write;
  reg read;
  reg [31:0] a;
  reg [31:0] b;
  reg [31:0] pc;
  reg [31:0] inst;
  wire [31:0] imm;
  wire [4:0] rs1, rs2, rd;
  wire invalid;

  registers r(.clk(clk));
  mem m(.addr(addr), .bus(bus), .write(write), .read(read));
  decode d(.clk(clk), .inst(inst), .imm(imm),
    .rs1(rs1), .rs2(rs2), .rd(rd), .invalid(invalid));

  always @(posedge rst) begin
    write <= 0;
    read <= 0;
    a <= 0;
    b <= 0;
    pc <= 0;
    inst <= 0;
  end
endmodule
