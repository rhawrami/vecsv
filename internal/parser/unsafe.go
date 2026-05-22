package simd

import "unsafe"

const alignSize int = 64

// isAligned returns true if `addr` is divisble by `a`.
func isAligned(addr *byte, a int) bool {
	return uintptr(unsafe.Pointer(addr))&uintptr(a-1) == 0
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
		start = 64 - offBy
	}

	s = s[start : start+l]
	return s
}

// asU64T casts `b` as a slice of unsigned 64-bit integers, with length
// len(b) / 8.
func asU64T(b []byte) []uint64 {
	if len(b) == 0 {
		return []uint64{}
	}
	if !isAligned(&b[0], alignSize) {
		panic("base not aligned to 64 bytes")
	}
	if len(b)&7 != 0 {
		panic("slice length not divisible by 8")
	}
	return unsafe.Slice((*uint64)(unsafe.Pointer(&b[0])), len(b)>>3)
}

// asU32T casts `b` as a slice of unsigned 32-bit integers, with length
// len(b) / 8.
func asU32T(b []byte) []uint32 {
	if len(b) == 0 {
		return []uint32{}
	}
	if !isAligned(&b[0], alignSize) {
		panic("base not aligned to 64 bytes")
	}
	if len(b)&3 != 0 {
		panic("slice length not divisible by 4")
	}
	return unsafe.Slice((*uint32)(unsafe.Pointer(&b[0])), len(b)>>2)
}
