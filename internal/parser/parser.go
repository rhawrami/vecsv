package parser

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
