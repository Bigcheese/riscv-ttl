module alu(
    output [31:0] bus,
    output [31:0] addr,
    input [31:0] a,
    input [31:0] b,
    input bus_en,
    input addr_en
  );

  wire [31:0] result;

  assign bus = bus_en ? result : 'z;
  assign addr = addr_en ? result : 'z;
  
  assign result = a + b;
  
endmodule
