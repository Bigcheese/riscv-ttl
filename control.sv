module control(clk, bus, addr, reset);
  input clk;
  input [31:0] bus;
  input [31:0] addr;
  input reset;

  enum reg [3:0] {FETCH, DECODE, REGA, REGB, WB} state;

  always @(posedge reset) begin
    state <= FETCH;
  end

  always @(posedge reset) begin
  end
endmodule
