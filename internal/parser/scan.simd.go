package parser

type cmr128Result struct {
	m0    int // mask for bytes 0-63
	m1    int // mask for bytes 64-127
	qCnts int // quote count
	inQ   int // 1 if left off in quotes
}

var compareMaskReduce128 func(base *byte, in_quotes int, sep byte) cmr128Result
