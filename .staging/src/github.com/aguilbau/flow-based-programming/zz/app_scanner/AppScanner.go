package main

/*

todo find (and fix) a bug causing empty ScanData to be sent

*/

const (
	ScanSuccess = 0
	ScanFailure = 1

	// the number of goroutines launching scans.
	// maybe this should be global to all requests, to avoid having to much
	digesterCount = 1024
)

type ScanResult struct {
	ID       int
	Status   int
	Data     []byte
	Protocol string
}

type ScanData struct {
	Host     string
	Protocol string
	Data     []byte
}

type ScanStatus struct {
	Host            string
	ScanTableOffest int
}

type Scan struct {
	ID   int
	Func ScanFunction
	Host string
}

type ScanFunction func(Host string, port int, ID int) *ScanResult

type ScanTable []Scanner

type Scanner struct {
	Func ScanFunction
}

var scanTables = map[int]ScanTable{
	80: ScanTable{
		HTTPScanner,
		HTTPSScanner,
	},
	443: ScanTable{
		HTTPSScanner,
		HTTPScanner,
	},
}

var defaultScanTable = ScanTable{
	HTTPScanner,
	HTTPSScanner,
	DefaultScanner,
}

func GetScanTable(port int) ScanTable {
	if val, ok := scanTables[port]; ok {
		return val
	}
	return defaultScanTable
}

func digester(port int, scans chan *Scan, results chan *ScanResult) {
	for scan := range scans {
		results <- scan.Func(scan.Host, port, scan.ID)
	}
}

func AppScanner(port int, hosts []string, scanData chan *ScanData) {
	defer close(scanData)
	if len(hosts) == 0 {
		return
	}

	scanTable := GetScanTable(port)
	scans := make(chan *Scan)
	scanResults := make(chan *ScanResult)
	scanStatus := make(map[int]*ScanStatus)
	defer close(scans)
	defer close(scanResults)

	// launch digesters
	for i := 0; i < digesterCount; i++ {
		go digester(port, scans, scanResults)
	}

	// start first scan for all hosts,
	// create the scanstatus map
	id := 0
	for _, host := range hosts {
		scans <- &Scan{
			ID:   id,
			Func: scanTable[0].Func,
			Host: host,
		}
		scanStatus[id] = &ScanStatus{
			Host:            host,
			ScanTableOffest: 0,
		}
		id++
	}

	// done is incremented when a scan succeeded for a host, or when all
	// scanTable scans failed for a host
	done := 0
	for done != len(hosts) {
		// recieve from the sscanResults channel, which is handled by the digesters
		scanResult := <-scanResults
		if scanResult.Status == ScanSuccess {
			done++
			// send to the scanData chan, handled in In.go
			scanData <- &ScanData{
				Host:     scanStatus[scanResult.ID].Host,
				Protocol: scanResult.Protocol,
				Data:     scanResult.Data,
			}
		} else if scanResult.Status == ScanFailure {
			// increment ScanTableOffest, moving on to next scan
			scanStatus[scanResult.ID].ScanTableOffest++
			offset := scanStatus[scanResult.ID].ScanTableOffest
			// all scan failed, we are done for this host
			if offset == len(scanTable) {
				done++
				continue
			}
			// launch a new scan with the next scanner
			scans <- &Scan{
				ID:   scanResult.ID,
				Func: scanTable[offset].Func,
				Host: scanStatus[scanResult.ID].Host,
			}
		}
	}
}
