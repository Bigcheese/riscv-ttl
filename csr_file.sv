module csr_file(input clk, input rst, input [11:0] addr, inout [31:0] bus, input read, input write,
    input [1:0] write_type, input trap, input [4:0] trap_cause, input ret, output invalid);
  // mstatus SD | WPRI | TSR | TW | TVM | MXR | SUM | MPRV | XS | FS | MPP M | WPRI | SPP 0 | MPIE | WPRI | SPIE 0 | UPIE 0 |
  // MIE | WPRI | SIE 0 | UIE 0
  `define MVENDORID 12'hF11
  `define MARCHID 12'hF12
  `define MIMPID 12'hF13
  `define MHARTID 12'hF14
  `define MSTATUS 12'h300
  `define MISA 12'h301
  `define MTVEC 12'h305
  `define MSCRATCH 12'h340
  `define MEPC 12'h341
  `define MCAUSE 12'h342
  `define MTVAL 12'h343
  reg [2:0] mstatus_internal;
  wire [31:0] mstatus = {19'b0, 2'b11, 3'b0, mstatus_internal[1], 3'b0, mstatus_internal[0], 3'b0};
  wire [31:0] mtvec = 32'h4;
  reg [31:0] mscratch;
  reg [31:0] mepc;
  reg [4:0] mcause;
  reg [31:0] mtval;

  reg [31:0] bus_out;
  reg invalid_out;

  assign bus = bus_out;
  assign invalid = invalid_out & (read | write);

  always @(*) begin
    case (addr)
      `MVENDORID: invalid_out = 0;
      `MARCHID: invalid_out = 0;
      `MIMPID: invalid_out = 0;
      `MHARTID: invalid_out = 0;
      `MSTATUS: invalid_out = 0;
      `MISA: invalid_out = 0;
      `MTVEC: invalid_out = 0;
      `MSCRATCH: invalid_out = 0;
      `MEPC: invalid_out = 0;
      `MCAUSE: invalid_out = 0;
      `MTVAL: invalid_out = 0;
      default: invalid_out = 1;
    endcase
  end

  always @(*) begin
    bus_out = 'z;
    if (read) begin
      case (addr)
        `MVENDORID: bus_out = 0;
        `MARCHID: bus_out = 0;
        `MIMPID: bus_out = 0;
        `MHARTID: bus_out = 0;
        `MSTATUS: bus_out = mstatus;
        `MISA: bus_out = 1 << 30 | 1 << 8;
        `MTVEC: bus_out = mtvec;
        `MSCRATCH: bus_out = mscratch;
        `MEPC: bus_out = mepc;
        `MCAUSE: bus_out = {27'b0, mcause};
        `MTVAL: bus_out = 0;
      endcase
    end
  end

  function int csr_write_value(input [1:0] write_type, input [31:0] cur_val, input [31:0] bus);
    return write_type == 2'b01 ? bus :
           write_type == 2'b10 ? cur_val | (32'hffffffff & bus) :
           write_type == 2'b11 ? cur_val & (32'hffffffff ^ bus) : 'x;
  endfunction

  wire [31:0] mstatus_temp = csr_write_value(write_type, mstatus, bus);
  always @(posedge clk) begin
    if (rst) begin
      mstatus_internal <= 0;
      mscratch <= 0;
      mepc <= 0;
      mcause <= 0;
      mtval <= 0;
    end else begin
      if (trap) begin
        mcause <= trap_cause;
        mepc <= bus;
        mstatus_internal[1] <= mstatus_internal[0];
        mstatus_internal[0] <= 0;
      end else if (ret) begin
        mstatus_internal[0] <= mstatus_internal[1];
        mstatus_internal[1] <= 1;
      end else if (write) begin
      case (addr)
          `MSTATUS: mstatus_internal <= {mstatus_temp[7], mstatus_temp[3]};
          `MSCRATCH: mscratch <= csr_write_value(write_type, mscratch, bus);
          `MEPC: mepc <= csr_write_value(write_type, mepc, bus);
          `MCAUSE: mcause <= csr_write_value(write_type, mcause, bus);
        endcase
      end
    end
  end
endmodule
