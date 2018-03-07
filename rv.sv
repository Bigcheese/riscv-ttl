module rv(input clk, input rst, output mem_read, output mem_write, output [31:0] mem_addr, output [31:0] mem_wdata, output [3:0] mem_wstrb, input [31:0] mem_rdata);
  reg [31:0] pc;
  reg [31:0] a;
  reg [31:0] b;
  reg [63:0] cycles;
  reg [63:0] instret;

  wire [31:0] addr;
  wire [31:0] bus;
  wire [4:0] reg_idx;
  wire reg_en, reg_write;
  wire [31:0] reg_in;
  wire [31:0] reg_out;
  wire [3:0]  mem_size;
  wire a_bus, a_addr, a_write, b_bus, b_addr, b_write;
  wire [31:0] alu_out;
  wire alu_bus, alu_addr;
  wire [2:0] alu_op;
  wire alu_sub, alu_sra;
  wire alu_eq, alu_lt, alu_ltu, alu_ge, alu_geu;
  wire [31:0] control_aout;
  wire [31:0] control_bout;
  wire control_bus, control_addr;

  assign reg_in = bus;

  assign mem_addr = addr;
  assign mem_wdata = bus;
  assign mem_wstrb = mem_size;

  registers r(.clk, .rst, .reg_in, .reg_out, .reg_idx, .reg_write);
  alu ar(.alu_out, .a, .b, .op(alu_op), .sub_en(alu_sub), .sra_en(alu_sra), .alu_eq, .alu_lt, .alu_ltu, .alu_ge,
         .alu_geu);
  control c(.clk, .reset(rst), .addr, .bus, .control_aout, .control_bout, .control_bus, .control_addr, .reg_idx,
            .mem_write, .mem_read, .mem_size, .reg_en,
            .reg_write, .a_bus, .a_addr, .a_write,
            .b_bus, .b_addr, .b_write,
            .alu_bus, .alu_addr, .alu_op, .alu_sub, .alu_sra, .alu_eq,
            .alu_lt, .alu_ltu, .alu_ge, .alu_geu);

  always @(posedge clk) cycles = cycles + 1;

  assign bus = a_bus ? a :
               b_bus ? b :
               mem_read ? mem_rdata :
               reg_en ? reg_out :
               alu_bus ? alu_out :
               control_bus ? control_bout :
               'x;

  assign addr = a_addr ? a :
                b_addr ? b :
                alu_addr ? alu_out :
                control_addr ? control_aout : 
                'x;

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
