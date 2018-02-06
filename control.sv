module control(
    input clk,
    inout [31:0] bus,
    inout [31:0] addr,
    input reset,
    output reg [4:0] reg_idx,
    output reg pc_addr, output reg pc_bus, output reg pc_inc, output reg pc_write,
    output reg mem_read, output reg mem_write,
    output reg reg_en, output reg reg_write,
    output reg a_bus, output reg a_addr, output reg a_write, output reg b_bus,
    output reg b_addr, output reg b_write,
    output reg alu_bus, output reg alu_addr, output reg [3:0] alu_op,
    input alu_eq
  );

  enum reg [3:0] {FETCH, REGA, REGB, OP, OP2, OP3, OP4} state;
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
    {inst, imm_en, pc_addr, pc_bus, pc_inc, pc_write, mem_read, mem_write, reg_en, reg_write, a_bus, a_addr, a_write,
    b_bus, b_addr, b_write, alu_bus, alu_addr, alu_op, inst_write} <= 0;
  end

  always @(posedge clk) begin
    if (inst_write)
      inst <= bus;
    state <= next_state;
  end

  always @(negedge clk) begin
    reg_idx <= 0;
    {imm_en, pc_addr, pc_bus, pc_inc, pc_write, mem_read, mem_write, reg_en, reg_write, a_bus, a_addr, a_write,
    b_bus, b_addr, b_write, alu_bus, alu_addr, alu_op, inst_write} <= 0;
    case (state)
      FETCH: begin
        pc_addr <= 1;
        mem_read <= 1;
        inst_write <= 1;
        next_state <= REGA;
      end
      REGA: begin
        if (opcode != 5'b11000)
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
        next_state <= FETCH;
        case (opcode)
          5'b0: begin // load
            a_addr <= 1;
            mem_read <= 1;
            reg_idx <= rd;
            reg_write <= 1;
          end
          5'b01000: begin // store
            a_addr <= 1;
            b_bus <= 1;
            mem_write <= 1;
          end
          5'b00100: begin // alui
            alu_op <= 5;
            alu_bus <= 1;
            reg_idx <= rd;
            reg_write <= 1;
          end
          5'b01100: begin // alur
            alu_op <= 5;
            alu_bus <= 1;
            reg_idx <= rd;
            reg_write <= 1;
          end
          5'b01101: begin // lui
            imm_en <= 1;
            reg_idx <= rd;
            reg_write <= 1;
          end
          5'b11000: begin // branch compare
            next_state <= alu_eq ? OP2 : FETCH;
            if (!alu_eq)
              pc_inc <= 1;
          end
        endcase
      end
      OP2: begin
        pc_bus <= 1;
        a_write <= 1;
        next_state <= OP3;
      end
      OP3: begin
        imm_en <= 1;
        b_write <= 1;
        alu_op <= 5;
        next_state <= OP4;
      end
      OP4: begin
        alu_op <= 5;
        alu_bus <= 1;
        pc_write <= 1;
        next_state <= FETCH;
      end
    endcase
  end
endmodule
