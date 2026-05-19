//go:build arm64

package simd

// ScanForStructuralChars scans a byte slice for the following characters:
//
// 1. comma:      `,`
// 2. separator:  `,|\t|;...`
// 3. quotes:     `"`
//
// When such a character is found... blah blah
//
//go:noescape
func ScanForStructuralChars(b []byte, m []uint64, sep byte)
