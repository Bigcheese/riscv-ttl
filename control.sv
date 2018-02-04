module control(clk, pc, bus, addr, reset, reg_idx,
    pc_en, pc_inc, mem_read, mem_write, reg_en, reg_write, a_bus, a_addr, a_write, b_bus, b_addr, b_write,
    alu_bus, alu_addr);
  input clk;
  input [31:0] pc;
  inout [31:0] bus;
  input [31:0] addr;
  input reset;
  output reg [4:0] reg_idx;
  output reg pc_en, pc_inc;
  output reg mem_write, mem_read;
  output reg reg_en, reg_write;
  output reg a_bus, a_addr, a_write, b_bus, b_addr, b_write;
  output reg alu_bus, alu_addr;

  enum reg [3:0] {FETCH, REGA, REGB, OP, WB} state;
  reg [3:0] next_state;
  reg [31:0] inst;
  reg inst_write;
  reg imm_en;

  wire [4:0] opcode;
  wire [31:0] imm;
  wire [4:0] rs1, rs2, rd;
  wire invalid;

  decode d(.clk(clk), .inst(inst), .opcode(opcode), .imm(imm),
    .rs1(rs1), .rs2(rs2), .rd(rd), .invalid(invalid));
    
  assign bus = imm_en ? imm : 'z;

  always @(posedge reset) begin
    state <= FETCH;
    next_state <= FETCH;
    reg_idx <= 0;
    {inst, imm_en, pc_en, pc_inc, mem_read, mem_write, reg_en, reg_write, a_bus, a_addr, a_write,
    b_bus, b_addr, b_write, alu_bus, alu_addr, inst_write} <= 0;
  end

  always @(posedge clk) begin
    if (inst_write)
      inst <= bus;
    state <= next_state;
  end

  always @(negedge clk) begin
    reg_idx <= 0;
    {imm_en, pc_en, pc_inc, mem_read, mem_write, reg_en, reg_write, a_bus, a_addr, a_write,
    b_bus, b_addr, b_write, alu_bus, alu_addr, inst_write} <= 0;
    case (state)
      FETCH: begin
        pc_en <= 1;
        mem_read <= 1;
        inst_write <= 1;
        next_state <= REGA;
      end
      REGA: begin
        pc_inc <= 1;
        reg_idx <= rs1;
        reg_en <= 1;
        a_write <= 1;
        next_state <= REGB;
      end
      REGB: begin
        if (opcode == 5'b00100) begin
          imm_en <= 1;
          b_write <= 1;
        end else begin
          reg_idx <= rs2;
          reg_en <= 1;
          b_write <= 1;
        end
        next_state <= OP;
      end
      OP: begin
        case (opcode)
          5'b0: begin
            a_addr <= 1;
            mem_read <= 1;
            reg_idx <= rd;
            reg_write <= 1;
          end
          5'b01000: begin
            a_addr <= 1;
            b_bus <= 1;
            mem_write <= 1;
          end
          5'b00100: begin
            alu_bus <= 1;
            reg_idx <= rd;
            reg_write <= 1;
          end
          5'b01100: begin
            alu_bus <= 1;
            reg_idx <= rd;
            reg_write <= 1;
          end
        endcase
        next_state <= FETCH;
      end
    endcase
  end
endmodule
