    .section .text,"ax",@progbits
_start:
    addi x1, x0, 42
    addi x2, x0, 32
    add x1, x1, x2
    .4byte 0
