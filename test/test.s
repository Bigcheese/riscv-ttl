  .text
#  li a3, 111
#  lh a0, insn
  lh a1, (insn+2)
  sh a1, 1f+2, t0
  fence.i

1:
  nop

insn:
  addi x0, x0, 0
