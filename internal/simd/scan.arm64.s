//go:build arm64

#include "textflag.h"

#define QUOTE_CHAR $34
#define LF_CHAR $10

#define B_MASK_0 $0x1001100110011001
#define B_MASK_1 $0x2002200220022002
#define B_MASK_2 $0x4004400440044004
#define B_MASK_3 $0x8008800880088008

#define CMP_MASK_REDUCE(target, out)      \
        VCMEQ target.B16, V0.B16, V11.B16 \
        VCMEQ target.B16, V1.B16, V12.B16 \
        VCMEQ target.B16, V2.B16, V13.B16 \
        VCMEQ target.B16, V3.B16, V14.B16 \
        VAND V11.B16, V4.B16, V0.B16      \
        VAND V12.B16, V5.B16, V1.B16      \
        VAND V13.B16, V6.B16, V2.B16      \
        VAND V14.B16, V7.B16, V3.B16      \
        VADD V0.D2, V1.D2, V11.D2         \
        VADD V2.D2, V3.D2, V12.D2         \
        VADD V11.D2, V12.D2, V0.D2        \
        VADDP V0.B16, V0.B16, V0.B16      \
        VST1.P V0.D[0], 8(out)

// func ScanForStructuralChars(b []byte, m []uint64, sep byte)
TEXT ·ScanForStructuralChars(SB),NOSPLIT,$0-56
    MOVD b+0(FP), R0  
    MOVD m+24(FP), R1  
    MOVD N+8(FP), R2  
    EOR R3, R3
    SUB $64, R2, R4

    MOVD LF_CHAR, R8                                  // init `\n`
    VDUP R8, V8.B16

    MOVD QUOTE_CHAR, R9                               // init `"`
    VDUP R9, V9.B16
    
    MOVD SEP_CHAR+48(FP), R10                         // init `sep`
    VDUP R10, V10.B16

    VMOVQ B_MASK_0, B_MASK_0, V4
    VMOVQ B_MASK_1, B_MASK_1, V5
    VMOVQ B_MASK_2, B_MASK_2, V6
    VMOVQ B_MASK_3, B_MASK_3, V7

    CMP $0, R2
    BEQ exitFn 

    CMP $64, R2
    BLT tradLoopInit

vecLoop:
    VLD4.P 64(R0), [V0.B16, V1.B16, V2.B16, V3.B16]
    CMP_MASK_REDUCE(V8, R1)                           // Vx_i == `\n` ? 0xFF : 0x00 

    ADD $64, R3
    CMP R4, R3
    BLE vecLoop

    CMP R2, R3
    BEQ exitFn

tradLoopInit:
    VEOR V0.B16, V0.B16, V0.B16
    EOR R5, R5, R5                                    // track final uint64_t
    ADD $1, R5, R6
tradLoop:
    VLD1.P 1(R0), V0.B[0]
    VCMEQ V8.B8, V0.B8, V1.B8
    VMOV V1.D[0], R7
    AND R7, R6, R8
    ORR R8, R5, R5

    LSL $1, R5
    ADD $1, R3
    CMP R2, R3
    BLT tradLoop

    MOVD R5, (R1)
exitFn:
    RET
