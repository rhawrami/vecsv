//go:build arm64

#include "textflag.h"

#define QUOTE_CHAR $34
#define LF_CHAR $10

#define PREFIX_XOR(target_gp, out_gp) \
        MOVQ $-1, R12                 \
        VMOVQ R12, X3                 \
        VMOVQ target_gp, X4           \
        VPCLMULQDQ $0, X3, X4, X3     \
        VMOVQ X3, out_gp

// func cmr128AVX2(base *byte, in_quotes int, sep byte) cmr128Result
TEXT ·cmr128AVX2(SB),NOSPLIT,$0-56
    MOVQ byteBase+0(FP), AX
    MOVQ inQ+48(FP), DI

    MOVB LF_CHAR, SI
    VPBROADCASTB SI, Y0
    MOVB sepChar+56(FP), SI
    VPBROADCASTB SI, Y1
    MOVB QUOTE_CHAR, SI
    VPBROADCASTB SI, Y2

cmre:
    VPMOVDQU (AX), Y3
    VPMOVDQU 32(AX), Y4

    VPCMPEQB Y0, Y3, Y5
    VPCMPEQB Y1, Y3, Y6
    VPCMPEQB Y2, Y3, Y7

    VPCMPEQB Y0, Y4, Y8
    VPCMPEQB Y1, Y4, Y9
    VPCMPEQB Y2, Y4, Y10

    VPMOVMSKB Y5, R8
    VPMOVMSKB Y8, R10
    SHLQ $32, R10
    ORQ R10, R8

    VPMOVMSKB Y6, R9
    VPMOVMSKB Y9, R12
    SHLQ $32, R12
    ORQ R12, R9

    VPMOVMSKB Y7, R10
    VPMOVMSKB Y10, R11
    SHLQ $32, R11
    ORQ R11, R10

    ORQ DI, R10
    PREFIX_XOR(R10, R11)
    MOVQ R11, DI
    SHRQ $63, DI

    ORQ R9, R8
    ANDNQ R11, R8

    POPCNTQ R8, R9

