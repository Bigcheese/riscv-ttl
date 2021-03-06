module main;
  reg [31:0] bus_set;
  reg [31:0] addr_set = 'x;
  reg enable = 0;
  reg reset = 0;
  reg clk = 0;

  wire [31:0] bus;
  wire [31:0] addr;

  rv r(.clk(clk), .bus(bus), .addr(addr), .rst(reset));

  always #1 clk = ~clk;

  always @(posedge reset) clk = 0;

  task writeMem32(bit [31:0] addr, bit [31:0] data);
    r.m.mem[addr] = data[7:0];
    r.m.mem[addr + 1] = data[15:8];
    r.m.mem[addr + 2] = data[23:16];
    r.m.mem[addr + 3] = data[31:24];
  endtask

  initial begin
    $dumpfile("rv-tb.dmp");
    $dumpvars();
    $monitor("addr=%b, bus=%b mem42=%d, r1=%d", addr, bus, r.m.mem[42], r.r.regs[1]);
    writeMem32(0, 32'b0000000_00001_00001_010_00000_0100011); // stw r1, r1
    writeMem32(4, 32'b0000000_00000_00001_010_00001_0000011); // ldw r1, r1
    #1 reset = 1;
    #1 reset = 0;
    r.r.regs[1] = 42;
    #20;
    $finish();
  end
endmodule
