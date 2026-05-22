package parser

import "unsafe"

const alignSize int = 64

// ref is a reference to a byte slice, starting at
// `ptr`, with `len` bytes of length; mirrors the underlying
// representation of a string type.
type ref struct {
	ptr *byte
	len uint
}

// Records represent a parsed csv file.
type records struct {
	rec     [][]ref
	nFields int
}

func (r *records) asStringSlices() [][]string {
	return unsafe.Slice((*[]string)(unsafe.Pointer(&r.rec[0])), len(r.rec))
}

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
