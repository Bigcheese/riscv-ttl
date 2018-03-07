module registers(input clk, input rst, inout [31:0] bus,
                 input [4:0] reg_idx, input reg_en, input reg_write);
  reg [31:0] regs[32];

  initial regs[0] = 0;

  assign bus = reg_en ? regs[reg_idx] : 'z;

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for (i = 1; i < 32; i = i + 1)
        regs[i] <= 0;
    end else begin
      if (reg_write && reg_idx != 0)
        regs[reg_idx] <= bus;
    end
  end
endmodule
