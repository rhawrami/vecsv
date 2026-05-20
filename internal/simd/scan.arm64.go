//go:build arm64

package simd

// ScanForStructuralChars scans a byte slice for the following characters:
//
// 1. newline:    `\n`
// 2. separator:  `,|\t|;...`
// 3. quotes:     `"`
//
// When such a character is found... blah blah
//
//go:noescape
func ScanForStructuralChars(b []byte, sep byte)

// _compare_mask_reduce_extract compares bytes in `b` to the following:
//
// 1. newline:    `\n`
// 2. separator:  `,|\t|;...`
// 3. quotes:     `"`
//
// Assumes length of `b` is divisible by 64.
//
// `t` determines how large the offsets in `o` are; if `t` == 4, then
// offsets will be unsigned 32-bit integers; if `t` == 8, offsets will
// be unsigned 64-bit integers.
//
//go:noescape
func C_compare_mask_reduce_extract(b []byte, o []uint64, sep byte)
