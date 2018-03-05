module mem #(parameter SIZE = 8192)(input clk, input [31:0] addr, input [31:0] in, output [31:0] out, input write, input b, input h);
  reg [31:0] mem[SIZE];
  wire [31:0] data_out;

  assign out = mem[addr];

  reg [7:0] in0, in1;
  reg [16:0] in2;

  always @(b or h or in) begin
    case ({b, h})
    2'b10: begin
      in0 = in[7:0];
      in1 = mem[addr][15:8];
      in2 = mem[addr][31:16];
    end
    2'b01: begin
      in0 = in[7:0];
      in1 = in[15:8];
      in2 = mem[addr][31:16];
    end
    default: begin
      in0 = in[7:0];
      in1 = in[15:8];
      in2 = in[31:16];
    end
    endcase
  end

  always @(posedge clk) begin
    if (write) begin
      mem[addr] <= {in2, in1, in0};
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
  reg [63:0] cycles;
  reg [63:0] instret;

  wire [4:0] reg_idx;
  wire mem_read, mem_write;
  wire [3:0]  mem_size;
  wire reg_en, reg_write;
  wire a_bus, a_addr, a_write, b_bus, b_addr, b_write;
  wire alu_bus, alu_addr;
  wire [2:0] alu_op;
  wire alu_sub, alu_sra;
  wire alu_eq, alu_lt, alu_ltu, alu_ge, alu_geu;
  wire mwrite = mem_write;

  wire [31:0] mem_out;

  registers r(.clk(clk), .rst(rst), .bus(bus), .reg_idx(reg_idx), .reg_en(reg_en), .reg_write(reg_write));
  mem m(.clk, .addr(addr[31:2]), .in(bus), .out(mem_out), .write(mwrite), .b(mem_size[3]), .h(mem_size[1]));
  alu ar(.bus(bus), .addr(addr), .a(a), .b(b), .bus_en(alu_bus), .addr_en(alu_addr), .op(alu_op),
         .sub_en(alu_sub), .sra_en(alu_sra), .alu_eq(alu_eq), .alu_lt(alu_lt), .alu_ltu(alu_ltu), .alu_ge(alu_ge), .alu_geu(alu_geu));
  control c(.clk(clk), .bus(bus), .addr(addr), .reset(rst), .reg_idx(reg_idx),
            .mem_write(mem_write), .mem_read(mem_read), .mem_size(mem_size), .reg_en(reg_en),
            .reg_write(reg_write), .a_bus(a_bus), .a_addr(a_addr), .a_write(a_write),
            .b_bus(b_bus), .b_addr(b_addr), .b_write(b_write),
            .alu_bus(alu_bus), .alu_addr(alu_addr), .alu_op(alu_op), .alu_sub(alu_sub), .alu_sra(alu_sra), .alu_eq(alu_eq),
            .alu_lt(alu_lt), .alu_ltu(alu_ltu), .alu_ge(alu_ge), .alu_geu(alu_geu));

  always @(posedge clk) cycles = cycles + 1;

  assign bus = a_bus ? a :
               b_bus ? b :
               mem_read ? mem_out :
               'z;

  assign addr = a_addr ? a :
                b_addr ? b :
                'z;

  always @(posedge clk) begin
    if (rst) begin
      a <= 0;
      b <= 0;
      cycles <= 0;
      instret <= 0;
    end else begin
      if (a_write)
        a <= bus;
      if (b_write)
        b <= bus;
    end
  end
endmodule
