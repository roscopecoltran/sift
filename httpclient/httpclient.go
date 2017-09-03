package httpclient

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"
)

var (
	// this has to include waiting for rate-limit retries, so make it big
	httpTimeout = 70 * time.Minute

	rateLimitRetry = 30 * time.Second
	notReadyRetry  = 3 * time.Second
)

type transport struct {
	oauthToken string
	cacheDir   string
	logger     *log.Logger
	base       http.RoundTripper
}

// New creates a http.Client instance with on-disk caching, OAuth token auth,
// rate-limit/not-ready retry and it panics on all errors.
func New(oauthToken string, cacheDir string) *http.Client {
	os.MkdirAll(cacheDir, 0700)

	transport := &transport{
		oauthToken: oauthToken,
		cacheDir:   cacheDir,
		logger:     log.New(os.Stderr, "[seeker] ", log.LstdFlags),

		base: http.DefaultTransport,
	}

	return &http.Client{
		Transport: transport,
		Timeout:   httpTimeout,
	}
}

func (t *transport) RoundTrip(request *http.Request) (*http.Response, error) {
	filename := t.cacheDir + "/" + requestHash(request)

	body, err := ioutil.ReadFile(filename)
	if err == nil {
		return makeResponse(body), nil
	}

	request.Header.Set("Authorization", "token "+t.oauthToken)
	response := t.doRequest(request)

	body, _ = ioutil.ReadAll(response.Body)
	response.Body.Close()

	err = ioutil.WriteFile(filename, body, 0644)
	if err != nil {
		panic(err)
	}

	return makeResponse(body), nil
}

func (t *transport) doRequest(request *http.Request) *http.Response {
	t.logger.Println(request.URL.String())

	for {
		response, err := t.base.RoundTrip(request)
		if err != nil {
			panic(err)
		}

		switch response.StatusCode {
		case 200, 204:
			return response

		case 403:
			t.logger.Println("Rate limited")
			time.Sleep(rateLimitRetry)

		case 202:
			t.logger.Println("Not Ready")
			time.Sleep(notReadyRetry)

		default:
			body, _ := ioutil.ReadAll(response.Body)
			panic(fmt.Errorf("HTTP %d: %s", response.StatusCode, body))
		}
	}
}

func requestHash(request *http.Request) string {
	hash := sha256.Sum256([]byte(request.URL.String()))
	return hex.EncodeToString(hash[:])
}

func makeResponse(body []byte) *http.Response {
	return &http.Response{
		Status:     "200 OK",
		StatusCode: 200,
		Proto:      "HTTP/1.1",
		ProtoMajor: 1,
		ProtoMinor: 1,

		ContentLength: int64(len(body)),
		Body:          ioutil.NopCloser(bytes.NewReader(body)),
	}
}
