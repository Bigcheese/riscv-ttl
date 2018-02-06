  .text
  addi a0, zero, 24
  addi a1, zero, 24
  addi a2, zero, 1
  beq a0, a1, .ret
  addi a2, zero, 2
.ret:
  ebreak
