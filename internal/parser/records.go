package parser

import "unsafe"

// newStrRef returns a string reference.
func newStrRef(ptr *byte, len uint) strRef {
	return strRef{ptr: bPtrToUnsafe(ptr), len: len}
}

// strRef is a reference to a byte slice, starting at
// `ptr`, with `len` bytes of length; mirrors the underlying
// representation of a string type.
type strRef struct {
	ptr unsafe.Pointer
	len uint
}

// sliceHeader represents a slice.
type sliceHeader struct {
	ptr unsafe.Pointer
	len int
	cap int
}

// newRecords returns a new set of csv records.
func newRecords() *records {
	refs := make([]strRef, 0, FIELDNDEFAULT)
	return &records{
		refs:    refs,
		headers: nil,
		nFields: -1,
	}
}

// records represent a csv file, with all underlying references being
// to a contiguous buffer of csv data; records should be used as follows:
//
// 1. r := newRecords()
// 2. r.append() // until hit new line character
// 3. r.setNFields()
// 4. r.append() // ...
// 5. ok := r.buildHeaders()
//
// if !ok, this means that the number of references is not divisble by the
// number of fields; this MAY be because of variable fields per row, but it could
// just as easily be other things; further, as of now, just because ok == true doesn't
// mean that there are no errors; in other words, !ok is a definitive negative signal,
// but ok is not a definitive positive signal.
type records struct {
	refs    []strRef      // string references
	headers []sliceHeader // slice headers
	nFields int           // number of fields per row
}

// setNFields determines the number of fields per row depending on the length
// of references in the current set.
func (r *records) setNFields() {
	r.nFields = len(r.refs)
}

// append appends a string reference to the set.
func (r *records) append(ref strRef) {
	r.refs = append(r.refs, ref)
}

// buildHeaders builds the slice headers representing the [][]string form
// of a parsed csv file; returns false if the number of references is not
// divisible by the number of fields.
func (r *records) buildHeaders() bool {
	// error somewhere
	if len(r.refs)%r.nFields != 0 {
		return false
	}

	N := len(r.refs) / r.nFields
	headers := make([]sliceHeader, N)
	for i := 0; i < N; i++ {
		headers[i] = sliceHeader{
			ptr: unsafe.Pointer(&r.refs[i*r.nFields]),
			len: r.nFields,
			cap: r.nFields,
		}
	}

	r.headers = headers
	return true
}

// as StringSlices returns the records in their [][]string form; the returned
// slice is only defined so far as the underlying csv data buffer is defined.
func (r *records) asStringSlices() [][]string {
	return unsafe.Slice((*[]string)(unsafe.Pointer(&r.headers[0])), len(r.headers))
}
