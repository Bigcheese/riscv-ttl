module mem(addr, bus, write, read, b, bu, h, hu);
  input wire [31:0] addr;
  inout wire [31:0] bus;
  input wire write;
  input wire read;
  input wire b, bu, h, hu;

  reg [7:0] mem[8192];
  reg [31:0] data_out;

  assign bus = read ? data_out : 'z;
  
  wire [31:0] mem_out = {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
  wire [31:0] mem_out_sized = b ? {{24{mem_out[7]}}, mem_out[7:0]} :
                              bu ? {24'b0, mem_out[7:0]} :
                              h ? {{16{mem_out[15]}}, mem_out[15:0]} :
                              hu ? {16'b0, mem_out[15:0]} :  mem_out ;

  always @(*) begin
    if (write) begin
      mem[addr] <= bus[7:0];
      if (!b)
        mem[addr + 1] <= bus[15:8];
      if (!b && !h) begin
        mem[addr + 2] <= bus[23:16];
        mem[addr + 3] <= bus[31:24];
      end
    end
    if (read) begin
      data_out <= mem_out_sized;
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
  reg [63:0] cycles;
  reg [63:0] instret;

  wire [4:0] reg_idx;
  wire pc_addr, pc_bus, pc_inc, pc_write;
  wire mem_read, mem_write;
  wire [3:0]  mem_size;
  wire reg_en, reg_write;
  wire a_bus, a_addr, a_write, b_bus, b_addr, b_write;
  wire alu_bus, alu_addr;
  wire [2:0] alu_op;
  wire alu_sub, alu_sra;
  wire alu_eq, alu_lt, alu_ltu, alu_ge, alu_geu;
  wire mwrite = mem_write & clk;

  registers r(.clk(clk), .rst(rst), .bus(bus), .reg_idx(reg_idx), .reg_en(reg_en), .reg_write(reg_write));
  mem m(.addr(addr), .bus(bus), .write(mwrite), .read(mem_read), .b(mem_size[3]), .bu(mem_size[2]), .h(mem_size[1]), .hu(mem_size[0]));
  alu ar(.bus(bus), .addr(addr), .a(a), .b(b), .bus_en(alu_bus), .addr_en(alu_addr), .op(alu_op),
         .sub_en(alu_sub), .sra_en(alu_sra), .alu_eq(alu_eq), .alu_lt(alu_lt), .alu_ltu(alu_ltu), .alu_ge(alu_ge), .alu_geu(alu_geu));
  control c(.clk(clk), .bus(bus), .addr(addr), .reset(rst), .reg_idx(reg_idx),
            .pc_addr(pc_addr), .pc_bus(pc_bus), .pc_inc(pc_inc), .pc_write(pc_write),
            .mem_write(mem_write), .mem_read(mem_read), .mem_size(mem_size), .reg_en(reg_en),
            .reg_write(reg_write), .a_bus(a_bus), .a_addr(a_addr), .a_write(a_write),
            .b_bus(b_bus), .b_addr(b_addr), .b_write(b_write),
            .alu_bus(alu_bus), .alu_addr(alu_addr), .alu_op(alu_op), .alu_sub(alu_sub), .alu_sra(alu_sra), .alu_eq(alu_eq),
            .alu_lt(alu_lt), .alu_ltu(alu_ltu), .alu_ge(alu_ge), .alu_geu(alu_geu));
  
  always @(posedge rst) begin
    a <= 0;
    b <= 0;
    pc <= 0;
    cycles <= 0;
    instret <= 0;
  end
  
  always @(posedge clk) cycles = cycles + 1;

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
    if (pc_inc) begin
      pc <= pc + 4;
      instret = instret + 1;
    end
    if (pc_write)
      pc <= bus;
  end
endmodule
