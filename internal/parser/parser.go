package parser

const (
	MINBUFFERSIZE    int  = 128
	CHUNKSIZEDEFAULT int  = 4096
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
	o := make([]uint, CHUNKSIZEDEFAULT)
	return &Parser{Sep: SEPDEFAULT, o: o}
}

// Parser parses a csv file. A Parser makes the following assumptions:
//
// 1. The csv file has an uniform number of fields (e.g., no variable field count).
//
// 2. Unpaired or escaped quotes (e.g., `,fie"ld,` or `,fie\"ld",`) are not allowed.
type Parser struct {
	b   []byte   // csv data buffer
	o   []uint   // offsets
	wip *records // records
	at  uint     // on byte
	Sep byte     // seperator character
}

func (p *Parser) readFirstRow() int {
	// assume that p.b is at least 128 bytes.
	const chunkSize int = 128

	wip := newRecords()

	var (
		inQ     int  // left off in quote pair?
		at      int  // buffer offset
		ptrAt   uint // buffer offset for string references
		foundNL bool
	)
	// TODO: handle buffer remainder
	for !foundNL && at < (len(p.b)+chunkSize) {
		r := compareMaskReduceExtract(
			p.b[at:at+chunkSize],
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

	return inQ
}

// ParseBytes parses a set of bytes representing a csv file.
func (p *Parser) ParseBytes(b []byte) ([][]string, error)

// ParseFile parses a csv file.
func (p *Parser) ParseFile(file string) ([][]string, error)
