package main

import (
	"fmt"
	"net"
	"time"
)

const (
	// lel
	defaultDefaultReadSize = 256
	defaultDefaultTimeout  = time.Duration(5 * time.Second)
)

var (
	DefaultScanner = Scanner{
		Func: DefaultScannerFunc,
	}
)

func DefaultScannerFunc(host string, port int, ID int) *ScanResult {
	conn, err := net.Dial("tcp", fmt.Sprintf("%v:%v", host, port))
	if err != nil {
		return &ScanResult{
			ID:     ID,
			Status: ScanFailure,
		}
	}
	defer conn.Close()

	b := make([]byte, defaultDefaultReadSize)
	conn.SetReadDeadline(time.Now().Add(defaultDefaultTimeout))

	_, err = conn.Read(b)
	if err != nil {
		return &ScanResult{
			ID:       ID,
			Status:   ScanSuccess,
			Data:     make([]byte, 0),
			Protocol: "unknown",
		}
	}

	// protocol is unknown, but we could execute some regex to find a bit more
	// need to structure though, because multiple scanners could use the same
	// regex (eg: sshScanner)
	return &ScanResult{
		ID:       ID,
		Status:   ScanSuccess,
		Data:     b,
		Protocol: "unknown",
	}
}
