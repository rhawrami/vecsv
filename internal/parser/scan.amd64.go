//go:build amd64

package parser

import "golang.org/x/sys/cpu"

var (
	compareMaskReduceExtract func(b []byte, o []int, in_quotes, at int, sep byte) resCMRE
)

func init() {
	if cpu.X86.HasAVX2 {
		compareMaskReduceExtract = cmreAVX2
	} else {
		// SSE2 is always available on amd64
		compareMaskReduceExtract = cmreSSE2
	}
}

//go:noescape
func cmreAVX2(b []byte, o []int, in_quotes, at int, sep byte) resCMRE

//go:noescape
func cmreSSE2(b []byte, o []int, in_quotes, at int, sep byte) resCMRE
