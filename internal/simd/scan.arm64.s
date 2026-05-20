//go:build arm64

#include "textflag.h"

#define QUOTE_CHAR $34
#define LF_CHAR $10

#define B_MASK_0 $0x1001100110011001
#define B_MASK_1 $0x2002200220022002
#define B_MASK_2 $0x4004400440044004
#define B_MASK_3 $0x8008800880088008

#define POP_COUNT(target_gp, out_gp)   \ 
        VEOR V0.B16, V0.B16, V0.B16    \
        VMOV target_gp, V1.D[0]        \
        VCNT V1.B8, V1.B8              \
        VADDV V1.B8, V0                \
        VMOV V0.D[0], out_gp


#define CMP_MASK_REDUCE(target, out_gp)   \
        VCMEQ target.B16, V0.B16, V11.B16 \
        VCMEQ target.B16, V1.B16, V12.B16 \
        VCMEQ target.B16, V2.B16, V13.B16 \
        VCMEQ target.B16, V3.B16, V14.B16 \
        VAND V11.B16, V4.B16, V11.B16     \
        VAND V12.B16, V5.B16, V12.B16     \
        VAND V13.B16, V6.B16, V13.B16     \
        VAND V14.B16, V7.B16, V14.B16     \
        VADD V11.D2, V12.D2, V11.D2       \
        VADD V13.D2, V14.D2, V12.D2       \
        VADD V11.D2, V12.D2, V11.D2       \
        VADDP V11.B16, V11.B16, V11.B16   \
        VMOV V11.D[0], out_gp

// func _compare_mask_reduce_extract(b []byte, o []uint64, sep byte)
TEXT ·C_compare_mask_reduce_extract(SB),NOSPLIT,$0-56
    MOVD b+0(FP), R0  
    MOVD o+24(FP), R1  
    MOVD N+8(FP), R2  
    EOR R3, R3

    MOVD LF_CHAR, R4                                 // init `\n`
    VDUP R4, V8.B16

    MOVD SEP_CHAR+48(FP), R4                         // init `sep`
    VDUP R4, V9.B16

    MOVD QUOTE_CHAR, R4                              // init `"`
    VDUP R4, V10.B16

    VMOVQ B_MASK_0, B_MASK_0, V4
    VMOVQ B_MASK_1, B_MASK_1, V5
    VMOVQ B_MASK_2, B_MASK_2, V6
    VMOVQ B_MASK_3, B_MASK_3, V7

    CMP $0, R2
    BEQ exit_fn 

cmp_mask_loop:
    VLD4.P 64(R0), [V0.B16, V1.B16, V2.B16, V3.B16]
    CMP_MASK_REDUCE(V8, R5)                           // Vx_i == `\n` ? 0xFF : 0x00 
    CMP_MASK_REDUCE(V9, R6)                           // Vx_i == `sep` ? 0xFF : 0x00 
    CMP_MASK_REDUCE(V10, R7)                          // Vx_i == `"` ? 0xFF : 0x00

    ORR R5, R6, R6

    POP_COUNT(R7, R11)
    CMP $0, R11
    BGT slow_extract_loop

    POP_COUNT(R6, R11)
    CMP $0, R11
    BEQ cmp_mask_loop

    RBIT R6, R6
    MOVD $0x7FFFFFFFFFFFFFFF, R7
fast_extract_loop:
    CLZ R6, R9
    MOVD.P R9, 8(R1)

    LSR R9, R7, R9
    AND R9, R6, R6

    SUB $1, R11
    CMP $0, R11
    BGT fast_extract_loop

    RET

slow_extract_loop:

exit_fn:
    RET

