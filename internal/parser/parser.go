package parser

const (
	CHUNKSIZEDEFAULT int  = 4096
	TAILSIZE         int  = 128
	NEWLINECHAR      byte = '\n'
	SEPDEFAULT       byte = ','
	FIELDNDEFAULT    int  = 10
)

// ResCMRE defines the results returned from a call to compareMaskReduceExtract.
type resCMRE struct {
	inQuotes        int // 1 if left off in a quote pair; 0 otherwise
	nOffsetsWritten int // number of offsets recorded
}

// NewParser returns a new Parser.
func NewParser() *Parser {
	tail := makeAlignedSlice(TAILSIZE)
	o := make([]uint, CHUNKSIZEDEFAULT)
	return &Parser{Sep: SEPDEFAULT, tail: tail, o: o}
}

// Parser parses a csv file. A Parser makes the following assumptions:
//
// 1. The csv file has an uniform number of fields (e.g., no variable field count).
//
// 2. Unpaired or escaped quotes (e.g., `,fie"ld,` or `,fie\"ld",`) are not allowed.
type Parser struct {
	b    []byte   // csv data buffer
	tail []byte   // copied remainder bytes (if len(b) not divisibly by 128)
	o    []uint   // offsets
	wip  *records // records
	at   uint     // on byte
	Sep  byte     // seperator character
}

// clearTail sets all tail bytes to 0.
func (p *Parser) clearTail() {
	// cast to 32|64 bit integer type to speed up clearing.
	t := asUintT(p.tail)

	for i := 0; i < len(t); i++ {
		t[i] = 0
	}
}

func (p *Parser) readFirstRow() (int, bool) {
	var chunkSize int = 128

	wip := newRecords()

	var (
		inQ     int  // left off in quote pair?
		at      int  // buffer offset
		ptrAt   uint // buffer offset for string references
		foundNL bool
	)

	for !foundNL && at < len(p.b) {
		// handle final 128 bytes
		var buff []byte
		if diff := len(p.b) - int(at); diff < chunkSize {
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

			if c := p.b[idx]; c == NEWLINECHAR {
				if !foundNL {
					foundNL = true
					wip.setNFields()
				}
			}
		}

		inQ = r.inQuotes
		at += chunkSize
	}

	p.wip = wip
	p.at = uint(at)

	return inQ, true
}

// ParseBytes parses a set of bytes representing a csv file.
func (p *Parser) ParseBytes(b []byte) ([][]string, error)

// ParseFile parses a csv file.
func (p *Parser) ParseFile(file string) ([][]string, error)
