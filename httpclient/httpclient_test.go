package httpclient

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	assert "github.com/stretchr/testify/require"
)

const (
	testCacheDir = "tmp"
)

func init() {
	// we don't have all day
	rateLimitRetry = 10 * time.Millisecond
	notReadyRetry = 10 * time.Millisecond
}

func makeClient() *http.Client {
	os.RemoveAll(testCacheDir)

	return New("verysecret", testCacheDir)
}

func TestCacheOK(t *testing.T) {
	reqNum := 0
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, "token verysecret", r.Header.Get("Authorization"))

		reqNum++
		fmt.Fprintf(w, "%d:%s", reqNum, r.URL.Path)
	}))
	defer ts.Close()

	cli := makeClient()

	// first request - goes to server
	resp, err := cli.Get(ts.URL + "/ok")
	assert.Nil(t, err)
	assert.Equal(t, 200, resp.StatusCode)
	assert.Equal(t, int64(5), resp.ContentLength)
	body, _ := ioutil.ReadAll(resp.Body)
	assert.Equal(t, "1:/ok", string(body))

	// second request - read from cache
	resp, err = cli.Get(ts.URL + "/ok")
	assert.Nil(t, err)
	assert.Equal(t, 200, resp.StatusCode)
	assert.Equal(t, int64(5), resp.ContentLength)
	body, _ = ioutil.ReadAll(resp.Body)
	assert.Equal(t, "1:/ok", string(body))

	// third request - different url - goes to server
	resp, err = cli.Get(ts.URL + "/ok2")
	assert.Nil(t, err)
	assert.Equal(t, 200, resp.StatusCode)
	assert.Equal(t, int64(6), resp.ContentLength)
	body, _ = ioutil.ReadAll(resp.Body)
	assert.Equal(t, "2:/ok2", string(body))
}

func TestCacheRetryNotReady(t *testing.T) {
	reqNum := 0
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reqNum++
		if reqNum == 1 {
			w.WriteHeader(202)
		}
		fmt.Fprintf(w, "%d:%s", reqNum, r.URL.Path)
	}))
	defer ts.Close()

	cli := makeClient()

	// retries automatically - result is second request
	resp, err := cli.Get(ts.URL + "/ok")
	assert.Nil(t, err)
	assert.Equal(t, 200, resp.StatusCode)
	body, _ := ioutil.ReadAll(resp.Body)
	assert.Equal(t, "2:/ok", string(body))
}

func TestCacheRetryRateLimit(t *testing.T) {
	reqNum := 0
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reqNum++
		if reqNum == 1 {
			w.WriteHeader(403)
		}
		fmt.Fprintf(w, "%d:%s", reqNum, r.URL.Path)
	}))
	defer ts.Close()

	cli := makeClient()

	// retries automatically - result is second request
	resp, err := cli.Get(ts.URL + "/ok")
	assert.Nil(t, err)
	assert.Equal(t, 200, resp.StatusCode)
	body, _ := ioutil.ReadAll(resp.Body)
	assert.Equal(t, "2:/ok", string(body))
}

func TestCacheHTTPNotOK(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(404)
		w.Write([]byte("someerror"))
	}))
	defer ts.Close()

	cli := makeClient()

	defer func() {
		r := recover()
		assert.EqualError(t, r.(error), "HTTP 404: someerror")
	}()

	cli.Get(ts.URL)
}

func TestCacheHTTPError(t *testing.T) {
	cli := makeClient()

	defer func() {
		r := recover()
		assert.EqualError(t, r.(error), `unsupported protocol scheme "xhttp"`)
	}()

	cli.Get("xhttp://")
}

func TestCacheWriteFileError(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	defer ts.Close()

	cli := makeClient()

	defer func() {
		r := recover()
		assert.Regexp(t, "no such file or directory", r.(error).Error())
	}()

	os.RemoveAll(testCacheDir)
	cli.Get(ts.URL)
}
