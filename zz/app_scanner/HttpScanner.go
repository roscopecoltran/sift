package main

/*
add HTTP/1.1 302 Found (not in headers) to data
*/

import (
	"crypto/tls"
	"fmt"
	"net/http"
	"strings"
	"time"
)

var (
	HTTPScanner = Scanner{
		Func: HTTPScannerFunc,
	}
	HTTPSScanner = Scanner{
		Func: HTTPSScannerFunc,
	}
)

const (
	defaultHttpTimeout = time.Duration(5 * time.Second)
)

var tr = http.Transport{
	TLSClientConfig: &tls.Config{
		InsecureSkipVerify: true,
	},
}

var httpClient = http.Client{
	CheckRedirect: func(req *http.Request, via []*http.Request) error {
		return http.ErrUseLastResponse
	},
	Timeout:   defaultHttpTimeout,
	Transport: &tr,
}

// suboptimal string concat
func HeaderToString(header http.Header) string {
	res := ""
	for key, value := range header {
		res += fmt.Sprintf("%s: %s\n", key, strings.Join(value, " "))
	}
	return res
}

func _httpScannerFunc(url string, ID int) *ScanResult {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return &ScanResult{
			ID:     ID,
			Status: ScanFailure,
		}
	}
	req.Header.Add("User-Agent", "zz")
	resp, err := httpClient.Do(req)
	if err != nil {
		return &ScanResult{
			ID:     ID,
			Status: ScanFailure,
		}
	}
	resp.Body.Close()
	if err != nil {
		return &ScanResult{
			ID:     ID,
			Status: ScanFailure,
		}
	}

	return &ScanResult{
		ID:     ID,
		Status: ScanSuccess,
		Data:   []byte(HeaderToString(resp.Header)),
	}
}

func HTTPScannerFunc(host string, port int, ID int) *ScanResult {
	if host == "" {
		return &ScanResult{
			ID:     ID,
			Status: ScanFailure,
		}
	}
	result := _httpScannerFunc(fmt.Sprintf("http://%v:%v", host, port), ID)
	result.Protocol = "http"
	return result
}

func HTTPSScannerFunc(host string, port int, ID int) *ScanResult {
	if host == "" {
		return &ScanResult{
			ID:     ID,
			Status: ScanFailure,
		}
	}
	result := _httpScannerFunc(fmt.Sprintf("https://%v:%v", host, port), ID)
	result.Protocol = "https"
	return result
}
