module registers(input clk, input rst, input [31:0] reg_in, output [31:0] reg_out,
                 input [4:0] reg_idx, input reg_write);
  reg [31:0] regs[32];

  initial regs[0] = 0;

  assign reg_out = regs[reg_idx];

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for (i = 1; i < 32; i = i + 1)
        regs[i] <= 0;
    end else begin
      if (reg_write && reg_idx != 0)
        regs[reg_idx] <= reg_in;
    end
  end
endmodule
