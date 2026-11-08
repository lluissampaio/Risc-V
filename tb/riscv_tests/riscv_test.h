#ifndef _ENV_PICORV32_TEST_H
#define _ENV_PICORV32_TEST_H

#ifndef TEST_FUNC_NAME
#  define TEST_FUNC_NAME mytest
#  define TEST_FUNC_TXT "mytest"
#  define TEST_FUNC_RET mytest_ret
#endif

#define RVTEST_RV32U
#define RVTEST_RV64U
#define TESTNUM gp

#define RVTEST_CODE_BEGIN       \
    .section .text.init;        \
    .align  2;                  \
    .globl _start;              \
_start:                         \
    li x1, 0;                   \
    li x2, 0;                   \
    li x3, 0;                   \
    li x4, 0;                   \
    li x5, 0;                   \
    li x6, 0;                   \
    li x7, 0;                   \
    li x8, 0;                   \
    li x9, 0;                   \
    li x10, 0;                  \
    li x11, 0;                  \
    li x12, 0;                  \
    li x13, 0;                  \
    li x14, 0;                  \
    li x15, 0;                  \
    li x16, 0;                  \
    li x17, 0;                  \
    li x18, 0;                  \
    li x19, 0;                  \
    li x20, 0;                  \
    li x21, 0;                  \
    li x22, 0;                  \
    li x23, 0;                  \
    li x24, 0;                  \
    li x25, 0;                  \
    li x26, 0;                  \
    li x27, 0;                  \
    li x28, 0;                  \
    li x29, 0;                  \
    li x30, 0;                  \
    li x31, 0;

#define RVTEST_PASS             \
    li a0, 0;                   \
    ecall;                      \
    j .;

#define RVTEST_FAIL             \
    sll a0, TESTNUM, 1;         \
    ori a0, a0, 1;              \
    ecall;                      \
    j .;

#define RVTEST_CODE_END
#define RVTEST_DATA_BEGIN       \
    .section .data;             \
    .align 4;
#define RVTEST_DATA_END

#define extra_boot

#endif
