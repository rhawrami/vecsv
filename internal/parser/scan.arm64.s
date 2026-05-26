//go:build arm64

#include "textflag.h"

// PREFIX_XOR calculate the prefix XOR sum of `target_gp`
// uses `scratch_gp` in the process, and overwrites `target_gp`
// with the result.
#define PREFIX_XOR(target_gp, scratch_gp)    \
        RBIT target_gp, target_gp            \
        LSR $1, target_gp, scratch_gp        \
        EOR target_gp, scratch_gp, target_gp \
        LSR $2, target_gp, scratch_gp        \
        EOR target_gp, scratch_gp, target_gp \
        LSR $4, target_gp, scratch_gp        \
        EOR target_gp, scratch_gp, target_gp \
        LSR $8, target_gp, scratch_gp        \
        EOR target_gp, scratch_gp, target_gp \
        LSR $16, target_gp, scratch_gp       \
        EOR target_gp, scratch_gp, target_gp \
        LSR $32, target_gp, scratch_gp       \
        EOR target_gp, scratch_gp, target_gp \
        RBIT target_gp, target_gp

// POP_COUNT calculates the population count of the 64 bits 
// in `target_gp`, placing the result in `out_gp`.
#define POP_COUNT(target_gp, out_gp) \ 
        VEOR V0.B16, V0.B16, V0.B16  \
        VMOV target_gp, V1.D[0]      \
        VCNT V1.B8, V1.B8            \
        VADDV V1.B8, V0              \
        VMOV V0.D[0], out_gp

// CMP_MASK_REDUCE calculates the 64-bit mask of whether bytes 
// in [A_V, B_V, C_V, D_V] are equal to the values in `target`,
// placing the resulting mask in `out_gp`. 
#define CMP_MASK_REDUCE(target, out_gp)    \
        VCMEQ target.B16, A_V.B16, V11.B16 \
        VCMEQ target.B16, B_V.B16, V12.B16 \
        VCMEQ target.B16, C_V.B16, V13.B16 \
        VCMEQ target.B16, D_V.B16, V14.B16 \
        VAND V11.B16, M0_V.B16, V11.B16    \
        VAND V12.B16, M1_V.B16, V12.B16    \
        VAND V13.B16, M2_V.B16, V13.B16    \
        VAND V14.B16, M3_V.B16, V14.B16    \
        VADD V11.D2, V12.D2, V11.D2        \
        VADD V13.D2, V14.D2, V12.D2        \
        VADD V11.D2, V12.D2, V11.D2        \
        VADDP V11.B16, V11.B16, V11.B16    \
        VMOV V11.D[0], out_gp

// CMP_MASK_REDUCE_2 calculates the 64-bit mask of whether bytes 
// in [A_V, B_V, C_V, D_V] are equal to the values in `target1` 
// or `target2`, placing the resulting mask in `out_gp`. 
#define CMP_MASK_REDUCE_2(target1, target2, out_gp) \
        VCMEQ target1.B16, A_V.B16, V11.B16         \
        VCMEQ target1.B16, B_V.B16, V12.B16         \
        VCMEQ target1.B16, C_V.B16, V13.B16         \
        VCMEQ target1.B16, D_V.B16, V14.B16         \
        VCMEQ target2.B16, A_V.B16, V15.B16         \
        VCMEQ target2.B16, B_V.B16, V16.B16         \
        VCMEQ target2.B16, C_V.B16, V17.B16         \
        VCMEQ target2.B16, D_V.B16, V18.B16         \
        VORR V11.B16, V15.B16, V11.B16              \
        VORR V12.B16, V16.B16, V12.B16              \
        VORR V13.B16, V17.B16, V13.B16              \
        VORR V14.B16, V18.B16, V14.B16              \
        VAND V11.B16, M0_V.B16, V11.B16             \
        VAND V12.B16, M1_V.B16, V12.B16             \
        VAND V13.B16, M2_V.B16, V13.B16             \
        VAND V14.B16, M3_V.B16, V14.B16             \
        VADD V11.D2, V12.D2, V11.D2                 \
        VADD V13.D2, V14.D2, V12.D2                 \
        VADD V11.D2, V12.D2, V11.D2                 \
        VADDP V11.B16, V11.B16, V11.B16             \
        VMOV V11.D[0], out_gp

#define QUOTE_CHAR $34
#define LF_CHAR $10

#define B_MASK_0 $0x1001100110011001
#define B_MASK_1 $0x2002200220022002
#define B_MASK_2 $0x4004400440044004
#define B_MASK_3 $0x8008800880088008

#define BASE_R R0
#define OFF_R R1
#define LEN_R R2
#define CTR_R R3
#define AT_R R10

#define QSTATE_R R4
#define NOFFSETSWRITTEN_R R9

#define A_V V0
#define B_V V1
#define C_V V2
#define D_V V3

#define M0_V V4
#define M1_V V5
#define M2_V V6
#define M3_V V7

#define LF_V V8
#define SEP_V V9
#define QUOTE_V V10

// func compareMaskReduceExtract(b []byte, o []uint, in_quotes, at int, sep byte) resCMRE
TEXT ·compareMaskReduceExtract(SB),NOSPLIT,$0-88
    MOVD b+0(FP), BASE_R
    MOVD o+24(FP), OFF_R  
    MOVD N+8(FP), LEN_R  
    MOVD in_quotes+48(FP), QSTATE_R
    MOVD at+56(FP), AT_R
    EOR NOFFSETSWRITTEN_R, NOFFSETSWRITTEN_R
    EOR CTR_R, CTR_R

    MOVD LF_CHAR, R5                          
    VDUP R5, LF_V.B16
    MOVD sep+64(FP), R5                         
    VDUP R5, SEP_V.B16
    MOVD QUOTE_CHAR, R5                              
    VDUP R5, QUOTE_V.B16

    VMOVQ B_MASK_0, B_MASK_0, M0_V
    VMOVQ B_MASK_1, B_MASK_1, M1_V
    VMOVQ B_MASK_2, B_MASK_2, M2_V
    VMOVQ B_MASK_3, B_MASK_3, M3_V

    CMP $0, LEN_R
    BEQ exit_fn 

cmp_mask_loop:
    VLD4.P 64(BASE_R), [A_V.B16, B_V.B16, C_V.B16, D_V.B16]

    CMP_MASK_REDUCE_2(LF_V, SEP_V, R5)                     
    CMP_MASK_REDUCE(QUOTE_V, R6)        

    ORR QSTATE_R, R6, R6

    PREFIX_XOR(R6, R8)
    LSR $63, R6, QSTATE_R

    BIC R6, R5, R5

    POP_COUNT(R5, R8)
    ADD R8, NOFFSETSWRITTEN_R
    CMP $0, R8
    BEQ eval

    RBIT R5, R5
    MOVD $0x7FFFFFFFFFFFFFFF, R6
extract_loop:
    CLZ R5, R7
    ADD AT_R, R7, R11
    MOVD.P R11, 8(R1)

    LSR R7, R6, R7
    AND R7, R5, R5

    SUB $1, R8
    CMP $0, R8
    BGT extract_loop

eval:
    ADD $64, AT_R
    ADD $64, CTR_R
    CMP LEN_R, CTR_R
    BLT cmp_mask_loop

exit_fn:
    MOVD QSTATE_R, quote_state_out+72(FP)
    MOVD NOFFSETSWRITTEN_R, n_offsets_read_out+80(FP)
    RET

// func cmre128B(base, prior, out *byte, inQ, sep int32) cmre128BResult
TEXT ·cmre128B(SB),NOSPLIT,$0-48
    MOVD base+0(FP), R0
    MOVD prior+8(FP), R1
    MOVD out+16(FP), R2
    MOVW inQ+24(FP), R3
    MOVW sep+28(FP), R4

    VMOVQ $0x1001100110011001, $0x1001100110011001, V4
    VMOVQ $0x2002200220022002, $0x2002200220022002, V5
    VMOVQ $0x4004400440044004, $0x4004400440044004, V6
    VMOVQ $0x8008800880088008, $0x8008800880088008, V7

    VMOVI $10, V8.B16
    VDUP R4, V9.B16
    VMOVI $34, V10.B16

    EOR R12, R12
    EOR R13, R13

compare_mask_reduce:
    VLD4 (R0), [V0.B16, V1.B16, V2.B16, V3.B16]

    VCMEQ V8.B16, V0.B16, V11.B16
    VCMEQ V8.B16, V1.B16, V12.B16
    VCMEQ V8.B16, V2.B16, V13.B16
    VCMEQ V8.B16, V3.B16, V14.B16
    VCMEQ V9.B16, V0.B16, V15.B16
    VCMEQ V9.B16, V1.B16, V16.B16
    VCMEQ V9.B16, V2.B16, V17.B16
    VCMEQ V9.B16, V3.B16, V18.B16
    VORR V11.B16, V15.B16, V11.B16
    VORR V12.B16, V16.B16, V12.B16
    VORR V13.B16, V17.B16, V13.B16
    VORR V14.B16, V18.B16, V14.B16
    VAND V11.B16, V4.B16, V11.B16
    VAND V12.B16, V5.B16, V12.B16
    VAND V13.B16, V6.B16, V13.B16
    VAND V14.B16, V7.B16, V14.B16
    VADD V11.D2, V12.D2, V11.D2
    VADD V13.D2, V14.D2, V12.D2
    VADD V11.D2, V12.D2, V11.D2
    VADDP V11.B16, V11.B16, V11.B16
    VMOV V11.D[0], R4

    VCMEQ V10.B16, V0.B16, V11.B16
    VCMEQ V10.B16, V1.B16, V12.B16
    VCMEQ V10.B16, V2.B16, V13.B16
    VCMEQ V10.B16, V3.B16, V14.B16
    VAND V11.B16, V4.B16, V11.B16
    VAND V12.B16, V5.B16, V12.B16
    VAND V13.B16, V6.B16, V13.B16
    VAND V14.B16, V7.B16, V14.B16
    VADD V11.D2, V12.D2, V11.D2
    VADD V13.D2, V14.D2, V12.D2
    VADD V11.D2, V12.D2, V11.D2
    VADDP V11.B16, V11.B16, V11.B16
    VMOV V11.D[0], R5

    ORR R5, R3, R5
    PREFIX_XOR(R5, R6)
    LSR $63, R5, R3
    BIC R5, R4, R4

    ADD $64, R0, R14
    VLD4 (R14), [V0.B16, V1.B16, V2.B16, V3.B16]

    VCMEQ V8.B16, V0.B16, V11.B16
    VCMEQ V8.B16, V1.B16, V12.B16
    VCMEQ V8.B16, V2.B16, V13.B16
    VCMEQ V8.B16, V3.B16, V14.B16
    VCMEQ V9.B16, V0.B16, V15.B16
    VCMEQ V9.B16, V1.B16, V16.B16
    VCMEQ V9.B16, V2.B16, V17.B16
    VCMEQ V9.B16, V3.B16, V18.B16
    VORR V11.B16, V15.B16, V11.B16
    VORR V12.B16, V16.B16, V12.B16
    VORR V13.B16, V17.B16, V13.B16
    VORR V14.B16, V18.B16, V14.B16
    VAND V11.B16, V4.B16, V11.B16
    VAND V12.B16, V5.B16, V12.B16
    VAND V13.B16, V6.B16, V13.B16
    VAND V14.B16, V7.B16, V14.B16
    VADD V11.D2, V12.D2, V11.D2
    VADD V13.D2, V14.D2, V12.D2
    VADD V11.D2, V12.D2, V11.D2
    VADDP V11.B16, V11.B16, V11.B16
    VMOV V11.D[0], R6

    VCMEQ V10.B16, V0.B16, V11.B16
    VCMEQ V10.B16, V1.B16, V12.B16
    VCMEQ V10.B16, V2.B16, V13.B16
    VCMEQ V10.B16, V3.B16, V14.B16
    VAND V11.B16, V4.B16, V11.B16
    VAND V12.B16, V5.B16, V12.B16
    VAND V13.B16, V6.B16, V13.B16
    VAND V14.B16, V7.B16, V14.B16
    VADD V11.D2, V12.D2, V11.D2
    VADD V13.D2, V14.D2, V12.D2
    VADD V11.D2, V12.D2, V11.D2
    VADDP V11.B16, V11.B16, V11.B16
    VMOV V11.D[0], R7

    ORR R7, R3, R7
    PREFIX_XOR(R7, R8)
    LSR $63, R7, R3
    BIC R7, R6, R6

    VEOR V0.B16, V0.B16, V0.B16
    VMOV R4, V1.D[0]
    VCNT V1.B8, V1.B8
    VADDV V1.B8, V0
    VMOV V0.D[0], R8

    CMP $0, R8
    BEQ extract_64to127

    MOVD R0, R14
    RBIT R4, R4
extract_0to63:
    CLZ R4, R9
    ADD R9, R14, R10
    SUB R1, R10, R11

    MOVD R1, (R2)
    MOVD R11, 8(R2)
    
    ADD $16, R2
    ADD R11, R1
    ADD $1, R1
    MOVD R1, R14

    ADD $1, R9
    LSL R9, R4

    ADD $1, R12

    SUB $1, R8
    CMP $0, R8
    BGT extract_0to63

    ADD $64, R0

    VEOR V0.B16, V0.B16, V0.B16
    VMOV R6, V1.D[0]
    VCNT V1.B8, V1.B8
    VADDV V1.B8, V0
    VMOV V0.D[0], R8

    CMP $0, R8
    BEQ epilogue

    MOVD R0, R14
    RBIT R6, R4
extract_64to127:
    CLZ R4, R9
    ADD R9, R14, R10
    SUB R1, R10, R11

    MOVD R1, (R2)
    MOVD R11, 8(R2)
    
    ADD $16, R2
    ADD R11, R1
    ADD $1, R1
    MOVD R1, R14

    ADD $1, R9
    LSL R9, R4

    ADD $1, R12

    SUB $1, R8
    CMP $0, R8
    BGT extract_64to127

epilogue:
    MOVD R1, newPrior+32(FP)
    MOVH R12, nWritten+40(FP)
    MOVH R3, inQuotes+42(FP)
    MOVW R13, nQuotes+44(FP)
    RET
    