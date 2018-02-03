module registers(clk);
  input wire clk;
  
  reg [31:0] regs[32];
  
  initial regs[0] = 0;
endmodule
