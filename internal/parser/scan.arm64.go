//go:build arm64

package parser

// compareMaskReduceExtract compares bytes in `b` to the following:
// 1. newline:    `\n`
// 2. separator:  `,|\t|;...`
// 3. quotes:     `"`
//
// For each 64-byte chunk, two 64-bit masks are built: a newline|sep identifier, and
// a quote identifier; `in_quotes` determines if the starting chunk was left off in a
// quote pair; this information is used to control for newline|sep characters found
// in quote pairs; once these characters are masked out, offsets corresponding to newlin_sep
// characters are written out to `o`; `at` is used as the base offset for the first byte in `b`.
//
// A resCMRE result is returned, containing the quote state, and the number of offsets read, in order
// to update/grow the offsets buffer.
//
// Assumes length of `b` is divisible by 64, and that len(`o`) >= len(`b`).
//
//go:noescape
func compareMaskReduceExtract(b []byte, o []int, in_quotes, at int, sep byte) resCMRE
