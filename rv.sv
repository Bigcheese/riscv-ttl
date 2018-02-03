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
  wire pc_en, pc_inc, mem_read, mem_write, reg_en, reg_write, a_bus, a_addr, a_write, b_bus, b_addr, b_write;
  wire mwrite = mem_write & clk;

  registers r(.clk(clk), .rst(rst), .bus(bus), .reg_idx(reg_idx), .reg_en(reg_en), .reg_write(reg_write));
  mem m(.addr(addr), .bus(bus), .write(mwrite), .read(mem_read));
  control c(.clk(clk), .pc(pc), .bus(bus), .addr(addr), .reset(rst), .reg_idx(reg_idx),
            .pc_en(pc_en), .pc_inc(pc_inc), .mem_write(mem_write), .mem_read(mem_read), .reg_en(reg_en),
            .reg_write(reg_write), .a_bus(a_bus), .a_addr(a_addr), .a_write(a_write),
            .b_bus(b_bus), .b_addr(b_addr), .b_write(b_write));
  
  always @(posedge rst) begin
    a <= 0;
    b <= 0;
    pc <= 0;
  end

  assign bus = a_bus ? a :
               b_bus ? b :
               'z;

  assign addr = pc_en ? pc : 
                a_addr ? a :
                b_addr ? b :
                'z;

  always @(posedge clk) begin
    if (a_write)
      a <= bus;
    if (b_write)
      b <= bus;
    if (pc_inc)
      pc <= pc + 4;
  end
endmodule
