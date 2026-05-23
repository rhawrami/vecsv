package parser

import "fmt"

const (
	CHUNKSIZE     int  = 4096
	NEWLINECHAR   byte = '\n'
	SEPDEFAULT    byte = ','
	FIELDNDEFAULT int  = 10
)

// ResCMRE defines the results returned from a call to compareMaskReduceExtract.
type resCMRE struct {
	inQuotes        int // 1 if left off in a quote pair; 0 otherwise
	nOffsetsWritten int // number of offsets recorded
}

// NewParser returns a new Parser.
func NewParser() *Parser {
	tail := makeAlignedSlice(CHUNKSIZE)
	o := make([]int, CHUNKSIZE)
	return &Parser{Sep: SEPDEFAULT, tail: tail, o: o}
}

// Parser parses a csv file. A Parser makes the following assumptions:
//
// 1. The csv file has an uniform number of fields (e.g., no variable field count).
//
// 2. Row endings are either `\n` or `\r\n`, and this ending is uniform across the
// document (e.g., `\n` throughout or `\r\n` throughout, no mix).
//
// 3. Unpaired quotes (e.g., `,fie"ld,`) are not allowed.
type Parser struct {
	b     []byte   // csv data buffer
	tail  []byte   // copied remainder bytes (if len(b) not divisibly by 4096)
	o     []int    // offsets
	wip   *records // records
	ptrAt int      // field starts at
	at    int      // on byte
	Sep   byte     // seperator character
}

// clearTail sets all tail bytes to 0.
func (p *Parser) clearTail() {
	// cast to 32|64 bit integer type to speed up clearing.
	t := asIntT(p.tail)

	for i := 0; i < len(t); i++ {
		t[i] = 0
	}
}

func (p *Parser) copyToTail() {
	if len(p.b) < CHUNKSIZE {
		copy(p.tail, p.b)
	} else {
		copy(p.tail, p.b[(len(p.b)>>12)<<12:])
	}
}

func (p *Parser) readFirstRow() int {
	var chunkSize int = CHUNKSIZE

	wip := newRecords()

	var (
		inQ     int // left off in quote pair?
		at      int // buffer offset
		ptrAt   int // buffer offset for string references
		foundNL bool
	)

	for !foundNL && at < len(p.b) {
		// handle final 4096 bytes
		var buff []byte
		if diff := len(p.b) - at; diff >= chunkSize {
			buff = p.b[at : at+chunkSize]
		} else {
			buff = p.tail
			chunkSize = diff
		}

		r := compareMaskReduceExtract(
			buff,
			p.o,
			inQ,
			at,
			p.Sep,
		)

		for i := 0; i < r.nOffsetsWritten; i++ {
			idx := p.o[i]
			l := p.o[i] - ptrAt
			ref := newStrRef(&p.b[ptrAt], l)
			wip.append(ref)

			ptrAt += l + 1

			if c := p.b[idx]; c == NEWLINECHAR && !foundNL {
				foundNL = true
				wip.setNFields()
			}
		}

		inQ = r.inQuotes
		at += chunkSize
	}

	// if new line not found, assume just header row without NL at end
	if !foundNL {
		l := len(p.b) - ptrAt
		ref := newStrRef(&p.b[ptrAt], l)
		wip.append(ref)
		ptrAt += l + 1

		wip.setNFields()
	}

	p.wip = wip
	p.ptrAt = ptrAt
	p.at = at

	return inQ
}

func (p *Parser) readRemaining(inQ int) {
	if p.at == len(p.b) {
		return
	}

	inQuotes := inQ

	// process full chunks
	nFullChunks := (len(p.b) - p.at) / CHUNKSIZE
	for range nFullChunks {
		r := compareMaskReduceExtract(
			p.b[p.at:p.at+CHUNKSIZE],
			p.o,
			inQuotes,
			p.at,
			p.Sep,
		)

		for i := 0; i < r.nOffsetsWritten; i++ {
			l := p.o[i] - p.ptrAt
			ref := newStrRef(&p.b[p.ptrAt], l)
			p.wip.append(ref)

			p.ptrAt += l + 1
		}

		inQuotes = r.inQuotes
		p.at += CHUNKSIZE
	}

	// process tail
	r := compareMaskReduceExtract(
		p.tail,
		p.o,
		inQuotes,
		p.at,
		p.Sep,
	)
	for i := 0; i < r.nOffsetsWritten; i++ {
		l := p.o[i] - p.ptrAt
		ref := newStrRef(&p.b[p.ptrAt], l)
		p.wip.append(ref)

		p.ptrAt += l + 1
	}
	inQuotes = r.inQuotes
	p.at += CHUNKSIZE
}

// ParseBytes parses a set of bytes representing a csv file.
func (p *Parser) ParseBytes(b []byte) ([][]string, error) {
	p.b = b
	p.clearTail()
	p.copyToTail()

	inQ := p.readFirstRow()
	p.readRemaining(inQ)

	if ok := p.wip.buildHeaders(); !ok {
		return nil, fmt.Errorf("something went wrong")
	}
	return p.wip.asStringSlices(), nil
}

// // ParseFile parses a csv file.
// func (p *Parser) ParseFile(file string) ([][]string, error)
