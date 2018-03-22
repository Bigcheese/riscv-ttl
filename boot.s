  .section .reset,"ax"
  .global reset_vector
  .align 6 /* 64 */
  j reset_vector

  .section .tvec,"ax"
  .align 2 /* 4 */
  .weak mtvec_handler
  .global _start
trap_vector:
  csrr t5, mcause
  blez t5, external_exception
internal_exception:
  j reset_vector
external_exception:
  li t4, 0x8004
  lw t4, 0(t4)
  mv x2, t4
  mret
  j reset_vector
reset_vector:
  csrwi mstatus, 0
  la t0, _start
  csrw mepc, t0
  mret
  .section .text,"ax"
_start:
  li x1, 0x8000
  li x2, 0
1:srli x3, x2, 16
  sw x3, 0(x1)
  addi x2, x2, 1
  j 1b
