# 1 "test/lb.S"
# 1 "<built-in>" 1
# 1 "test/lb.S" 2
 # See LICENSE for license details.

 #*****************************************************************************
 # lb.S
 #-----------------------------------------------------------------------------

 # Test lb instruction.



# 1 "test/riscv_test.h" 1





# 1 "test/encoding.h" 1
# 7 "test/riscv_test.h" 2
# 11 "test/lb.S" 2
# 1 "test/test_macros.h" 1






 #-----------------------------------------------------------------------
 # Helper macros
 #-----------------------------------------------------------------------
# 20 "test/test_macros.h"
 # We use a macro hack to simpify code generation for various numbers
 # of bubble cycles.
# 36 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # RV64UI MACROS
 #-----------------------------------------------------------------------

 #-----------------------------------------------------------------------
 # Tests for instructions with immediate operand
 #-----------------------------------------------------------------------
# 92 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # Tests for an instruction with register operands
 #-----------------------------------------------------------------------
# 120 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # Tests for an instruction with register-register operands
 #-----------------------------------------------------------------------
# 214 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # Test memory instructions
 #-----------------------------------------------------------------------
# 340 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # Test jump instructions
 #-----------------------------------------------------------------------
# 369 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # RV64UF MACROS
 #-----------------------------------------------------------------------

 #-----------------------------------------------------------------------
 # Tests floating-point instructions
 #-----------------------------------------------------------------------
# 631 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # Pass and fail code (assumes test num is in gp)
 #-----------------------------------------------------------------------
# 643 "test/test_macros.h"
 #-----------------------------------------------------------------------
 # Test data section
 #-----------------------------------------------------------------------
# 12 "test/lb.S" 2

.macro init; .endm
.text

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  test_2: la x1, tdat; lb x30, 0(x1);; li x29, ((0xffffffffffffffff) & ((1 << (32 - 1) << 1) - 1)); li gp, 2; bne x30, x29, fail;;
  test_3: la x1, tdat; lb x30, 1(x1);; li x29, ((0x0000000000000000) & ((1 << (32 - 1) << 1) - 1)); li gp, 3; bne x30, x29, fail;;
  test_4: la x1, tdat; lb x30, 2(x1);; li x29, ((0xfffffffffffffff0) & ((1 << (32 - 1) << 1) - 1)); li gp, 4; bne x30, x29, fail;;
  test_5: la x1, tdat; lb x30, 3(x1);; li x29, ((0x000000000000000f) & ((1 << (32 - 1) << 1) - 1)); li gp, 5; bne x30, x29, fail;;

  # Test with negative offset

  test_6: la x1, tdat4; lb x30, -3(x1);; li x29, ((0xffffffffffffffff) & ((1 << (32 - 1) << 1) - 1)); li gp, 6; bne x30, x29, fail;;
  test_7: la x1, tdat4; lb x30, -2(x1);; li x29, ((0x0000000000000000) & ((1 << (32 - 1) << 1) - 1)); li gp, 7; bne x30, x29, fail;;
  test_8: la x1, tdat4; lb x30, -1(x1);; li x29, ((0xfffffffffffffff0) & ((1 << (32 - 1) << 1) - 1)); li gp, 8; bne x30, x29, fail;;
  test_9: la x1, tdat4; lb x30, 0(x1);; li x29, ((0x000000000000000f) & ((1 << (32 - 1) << 1) - 1)); li gp, 9; bne x30, x29, fail;;

  # Test with a negative base

  test_10: la x1, tdat; addi x1, x1, -32; lb x5, 32(x1);; li x29, ((0xffffffffffffffff) & ((1 << (32 - 1) << 1) - 1)); li gp, 10; bne x5, x29, fail;





  # Test with unaligned base

  test_11: la x1, tdat; addi x1, x1, -6; lb x5, 7(x1);; li x29, ((0x0000000000000000) & ((1 << (32 - 1) << 1) - 1)); li gp, 11; bne x5, x29, fail;





  #-------------------------------------------------------------
  # Bypassing tests
  #-------------------------------------------------------------

  test_12: li gp, 12; li x4, 0; 1: la x1, tdat2; lb x30, 1(x1); addi x6, x30, 0; li x29, 0xfffffffffffffff0; bne x6, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;;
  test_13: li gp, 13; li x4, 0; 1: la x1, tdat3; lb x30, 1(x1); nop; addi x6, x30, 0; li x29, 0x000000000000000f; bne x6, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;;
  test_14: li gp, 14; li x4, 0; 1: la x1, tdat1; lb x30, 1(x1); nop; nop; addi x6, x30, 0; li x29, 0x0000000000000000; bne x6, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;;

  test_15: li gp, 15; li x4, 0; 1: la x1, tdat2; lb x30, 1(x1); li x29, 0xfffffffffffffff0; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_16: li gp, 16; li x4, 0; 1: la x1, tdat3; nop; lb x30, 1(x1); li x29, 0x000000000000000f; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;
  test_17: li gp, 17; li x4, 0; 1: la x1, tdat1; nop; nop; lb x30, 1(x1); li x29, 0x0000000000000000; bne x30, x29, fail; addi x4, x4, 1; li x5, 2; bne x4, x5, 1b;

  #-------------------------------------------------------------
  # Test write-after-write hazard
  #-------------------------------------------------------------

  test_18: la x5, tdat; lb x2, 0(x5); li x2, 2;; li x29, ((2) & ((1 << (32 - 1) << 1) - 1)); li gp, 18; bne x2, x29, fail;





  test_19: la x5, tdat; lb x2, 0(x5); nop; li x2, 2;; li x29, ((2) & ((1 << (32 - 1) << 1) - 1)); li gp, 19; bne x2, x29, fail;






  bne x0, gp, pass; fail: fence; 1: beqz gp, 1b; slli gp, gp, 1; ori gp, gp, 1; ecall; pass: fence; li gp, 1; ecall

ebreak

  .data




tdat:
tdat1: .byte 0xff
tdat2: .byte 0x00
tdat3: .byte 0xf0
tdat4: .byte 0x0f

.align 4; .global end_signature; end_signature:
