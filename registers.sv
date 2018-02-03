module registers(clk, rst, bus, reg_idx, reg_en, reg_write);
  input wire clk;
  input wire rst;
  inout wire [31:0] bus;
  input wire [4:0] reg_idx;
  input wire reg_en;
  input wire reg_write;

  reg [31:0] regs[32];

  initial regs[0] = 0;

  assign bus = reg_en ? regs[reg_idx] : 'z;
  
  integer i;
  always @(posedge rst) begin
    for (i = 1; i < 32; i = i + 1)
      regs[i] = 0;
  end

  always @(posedge clk) begin
    if (reg_write && reg_idx != 0)
      regs[reg_idx] <= bus;
  end
endmodule
