module main;
  reg [31:0] bus_set;
  reg [31:0] addr_set = 'z;
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

  integer bob;

  initial begin
    $dumpfile("rv-tb.dmp");
    $dumpvars();
    $monitor("addr=%b, bus=%b mem42=%d, x1=%d, x2=%d", addr, bus, r.m.mem[42], r.r.regs[1], r.r.regs[2]);
    bob = $fopen("test/add.bin", "rb");                 
    $fread(r.m.mem, bob);
    $fclose(bob);
    #1 reset = 1;
    #1 reset = 0;
    #40;
    $finish();
  end
endmodule
