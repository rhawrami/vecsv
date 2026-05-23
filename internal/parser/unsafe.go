package parser

import "unsafe"

const alignSize int = 64

func asIntT(b []byte) []int {
	return unsafe.Slice((*int)(unsafe.Pointer(&b[0])), len(b)/int(unsafe.Sizeof(int(1))))
}

func bPtrToUnsafe(b *byte) unsafe.Pointer { return unsafe.Pointer(b) }

// incPtr increments a byte pointer by `o` bytes.
func incPtr(b *byte, o uint) *byte {
	return (*byte)(unsafe.Pointer(uintptr(unsafe.Pointer(b)) + uintptr(o)))
}

// decPtr decrements a byte pointer by `o` bytes.
func decPtr(b *byte, o uint) *byte {
	return (*byte)(unsafe.Pointer(uintptr(unsafe.Pointer(b)) - uintptr(o)))
}

// makeAlignedSlice returns a byte slice with len >= `l`.
func makeAlignedSlice(l int) []byte {
	if l < alignSize {
		l = alignSize
	}
	if l%alignSize != 0 {
		l += alignSize - (l & (alignSize - 1))
	}

	s := make([]byte, l+alignSize)
	offBy := int(uintptr(unsafe.Pointer(&s[0])) & uintptr(alignSize-1))
	start := 0
	if offBy != 0 {
		start = alignSize - offBy
	}

	s = s[start : start+l]
	return s
}
