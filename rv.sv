module mem(addr, bus, write, read);
  input wire [31:0] addr;
  inout wire [31:0] bus;
  input wire write;
  input wire read;

  reg [7:0] mem[4096];
  reg [31:0] data_out;

  assign bus = read ? data_out : 'z;

  always @(addr or write or read) begin
    if (write) begin
      mem[addr] <= bus[7:0];
      mem[addr + 1] <= bus[15:8];
      mem[addr + 2] <= bus[23:16];
      mem[addr + 3] <= bus[31:24];
    end
    if (read) begin
      data_out[7:0] <= mem[addr];
      data_out[15:8] <= mem[addr + 1];
      data_out[23:16] <= mem[addr + 2];
      data_out[31:24] <= mem[addr + 3];
    end
  end
endmodule

module rv(clk, bus, addr, rst);
  inout wire [31:0] bus;
  inout wire [31:0] addr;
  input wire rst;
  input wire clk;
  reg [31:0] a;
  reg [31:0] b;
  reg [31:0] pc;

  wire [4:0] reg_idx;
  wire pc_addr, pc_bus, pc_inc, pc_write;
  wire mem_read, mem_write;
  wire reg_en, reg_write;
  wire a_bus, a_addr, a_write, b_bus, b_addr, b_write;
  wire alu_bus, alu_addr;
  wire [2:0] alu_op;
  wire alu_eq, alu_lt, alu_ge;
  wire mwrite = mem_write & clk;

  registers r(.clk(clk), .rst(rst), .bus(bus), .reg_idx(reg_idx), .reg_en(reg_en), .reg_write(reg_write));
  mem m(.addr(addr), .bus(bus), .write(mwrite), .read(mem_read));
  alu ar(.bus(bus), .addr(addr), .a(a), .b(b), .bus_en(alu_bus), .addr_en(alu_addr), .op(alu_op), .alu_eq(alu_eq));
  control c(.clk(clk), .bus(bus), .addr(addr), .reset(rst), .reg_idx(reg_idx),
            .pc_addr(pc_addr), .pc_bus(pc_bus), .pc_inc(pc_inc), .pc_write(pc_write),
            .mem_write(mem_write), .mem_read(mem_read), .reg_en(reg_en),
            .reg_write(reg_write), .a_bus(a_bus), .a_addr(a_addr), .a_write(a_write),
            .b_bus(b_bus), .b_addr(b_addr), .b_write(b_write),
            .alu_bus(alu_bus), .alu_addr(alu_addr), .alu_op(alu_op), .alu_eq(alu_eq),
            .alu_lt(alu_lt), .alu_ge(alu_ge));
  
  always @(posedge rst) begin
    a <= 0;
    b <= 0;
    pc <= 0;
  end

  assign bus = a_bus ? a :
               b_bus ? b :
               pc_bus ? pc :
               'z;

  assign addr = a_addr ? a :
                b_addr ? b :
                pc_addr ? pc :
                'z;

  always @(posedge clk) begin
    if (a_write)
      a <= bus;
    if (b_write)
      b <= bus;
    if (pc_inc)
      pc <= pc + 4;
    if (pc_write)
      pc <= bus;
  end
endmodule
