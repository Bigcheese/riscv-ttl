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

  function integer readMem32(bit [31:0] addr);
  endfunction

  always @(negedge clk) begin
    if (r.c.inst[6:0] == 7'b1110011 && r.c.func3 == 0 &&
        (r.c.inst[31:20] == 12'b000000000001 || r.c.inst[31:20] == 12'b000000000000)) begin
      if (r.r.regs[3] != 1) begin
        for (i = 0; i < 32; i = i + 1) begin
          $display("x%0d = %d", i, r.r.regs[i]);
        end
        $display("Failed on test: %d", r.r.regs[3] >> 1);
      end
      $finish_and_return(r.r.regs[3] == 1 ? 0 : 1);
    end
  end

  integer bob, c;
  integer a = 0;
  integer i;
  string input_file;
  string output_file;

  task automatic read_mem(string path);
    reg [31:0] val;

    bob = $fopen(path, "rb");
    c = $fread(val, bob);
    while (c == 4) begin
      r.m.mem[a] = {val[7:0], val[15:8], val[23:16], val[31:24]};
      a = a + 1;
      c = $fread(val, bob);
    end
    $fclose(bob);
  endtask

  integer blah;

  initial begin
    blah = $value$plusargs("bin=%s", input_file);
    blah = $value$plusargs("out=%s", output_file);
    $dumpfile(output_file);
    $dumpvars();
    // $monitor("addr=%b, bus=%b mem42=%d, x1=%d, x2=%d, cl=%b", addr, bus, r.m.mem[42], r.r.regs[1], r.r.regs[2], r.c.control_lines);
    read_mem(input_file);
    #1 reset = 1;
    #1 reset = 0;
    #10000;
    for (i = 0; i < 32; i = i + 1) begin
      $display("x%0d = %d", i, r.r.regs[i]);
    end
    $finish_and_return(r.r.regs[3] == 1 ? 0 : 1);
  end
endmodule
