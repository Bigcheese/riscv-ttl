module main;
  reg [31:0] bus_set;
  reg [31:0] addr_set;
  reg enable = 0;
  reg reset = 0;
  reg clk = 0;
  
  wire [31:0] bus = enable ? bus_set : 'z;
  wire [31:0] addr = addr_set;

  rv r(.bus(bus), .addr(addr), .rst(reset));
  
  always #1 clk = ~clk;
  
  initial begin
    $dumpfile("rv-tb.dmp");
    $dumpvars();
    $monitor("addr=%b, bus=%b", addr, bus);
    reset = 1;
    #1 reset = 0;
    r.r.regs[1] = 42;
    #1 r.inst = 32'b0000000_00001_00000_010_00000_0100011;
    enable = 1;
    #1 addr_set = r.r.regs[r.rs1] + r.imm;
    bus_set = r.r.regs[r.rs2];
    #1;
    r.write = 1;
    #1;
    r.write = 0;
    enable = 0;
    #1;
    r.inst = 32'b0000000_00000_00000_010_00001_0000011;
    addr_set = r.r.regs[r.rs1] + r.imm;
    r.read = 1;
    #1;
    r.r.regs[r.rd] = bus;
    #1;
    r.read = 0;
    #1;
    $finish();
  end
endmodule
