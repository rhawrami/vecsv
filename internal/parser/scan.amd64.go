//go:build amd64

package parser

import "golang.org/x/sys/cpu"

func init() {
	if cpu.X86.HasAVX2 {
		compareMaskReduce128 = cmr128AVX2
	} else {
		// SSE2 is always available on amd64
		compareMaskReduce128 = cmr128SSE2
	}
}

//go:noescape
func cmr128AVX2(base *byte, in_quotes int, sep byte) cmr128Result

//go:noescape
func cmr128SSE2(base *byte, in_quotes int, sep byte) cmr128Result
