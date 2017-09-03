package provider

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	assert "github.com/stretchr/testify/require"

	"github.com/dziemba/seeker/data"
)

func makeSearchResult(n int) string {
	item := `{
		"name": "dotfiles",
		"owner": { "login": "hans" },
		"stargazers_count": 42
	}`

	items := strings.Repeat(item+",", n)
	items = items[:len(items)-1] // cut off last comma

	return fmt.Sprintf(`{ "items": [%s] }`, items)
}

func TestRepoInfosAllData(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.String() {
		case "/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated":
			fmt.Fprintf(w, `{
				"items": [
					{
						"name": "dotfiles",
						"owner": { "login": "hans" },
						"stargazers_count": 42
					}
				]
			}`)

		case "/repos/hans/dotfiles/languages":
			fmt.Fprintf(w, `{ "Ruby": 350, "C": 50 }`)

		case "/repos/hans/dotfiles/contributors":
			fmt.Fprintf(w, `[
				{ "login": "hans", "contributions": 10 },
				{ "login": "peter", "contributions": 24 }
			]`)

		default:
			panic("invalid url: " + r.URL.String())
		}
	}))
	defer ts.Close()

	cli := makeClient(ts.URL)

	repoInfoCh := make(chan *data.RepoInfo)
	doneCh := make(chan struct{})

	go RepoInfos(cli, "Ruby", 10, 11, repoInfoCh, doneCh)

	assert.Equal(t, &data.RepoInfo{
		Owner:           "hans",
		Name:            "dotfiles",
		Stars:           42,
		LangPercentages: map[string]float64{"Ruby": 0.875, "C": 0.125},
		Contributions:   map[string]int{"hans": 10, "peter": 24},
	}, <-repoInfoCh)

	<-doneCh
}

func TestRepoInfosNoLanguageInfo(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.String() {
		case "/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated":
			fmt.Fprintf(w, `{
				"items": [
					{
						"name": "dotfiles",
						"owner": { "login": "hans" },
						"stargazers_count": 42
					}
				]
			}`)

		case "/repos/hans/dotfiles/languages":
			// GitHub doesn't return an empty object, but rather the total byte count is 0
			// if there is no useable language info
			fmt.Fprintf(w, `{ "Ruby": 0, "Go": 0 }`)

		case "/repos/hans/dotfiles/contributors":
			fmt.Fprintf(w, `[
				{ "login": "hans", "contributions": 10 },
			]`)

		default:
			panic("invalid url: " + r.URL.String())
		}
	}))
	defer ts.Close()

	cli := makeClient(ts.URL)

	repoInfoCh := make(chan *data.RepoInfo)
	doneCh := make(chan struct{})

	go RepoInfos(cli, "Ruby", 10, 11, repoInfoCh, doneCh)

	// no repoInfo is sent

	<-doneCh
}

func TestRepoInfosStarPartitioning(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.String() {
		case
			"/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A80..88&sort=updated",
			"/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A88..96&sort=updated",
			"/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A96..105&sort=updated",
			"/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A105..115&sort=updated":
			fmt.Fprintf(w, makeSearchResult(1))

		case "/repos/hans/dotfiles/languages":
			fmt.Fprintf(w, `{ "Ruby": 111 }`)
		case "/repos/hans/dotfiles/contributors":
			fmt.Fprintf(w, "[]")

		default:
			panic("invalid url: " + r.URL.String())
		}

	}))
	defer ts.Close()

	cli := makeClient(ts.URL)

	repoInfoCh := make(chan *data.RepoInfo)
	doneCh := make(chan struct{})

	go RepoInfos(cli, "Ruby", 80, 110, repoInfoCh, doneCh)

	for i := 0; i < 4; i++ {
		info := <-repoInfoCh
		assert.Equal(t, "hans", info.Owner)

	}
	<-doneCh
}

func TestRepoInfosPaginationStopWhenNoResults(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.String() {
		case
			"/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=2&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated":
			fmt.Fprintf(w, makeSearchResult(100))
		case
			"/search/repositories?page=3&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated":
			fmt.Fprintf(w, makeSearchResult(50))

		case "/repos/hans/dotfiles/languages":
			fmt.Fprintf(w, `{ "Ruby": 111 }`)
		case "/repos/hans/dotfiles/contributors":
			fmt.Fprintf(w, "[]")

		default:
			panic("invalid url: " + r.URL.String())
		}
	}))
	defer ts.Close()

	cli := makeClient(ts.URL)

	repoInfoCh := make(chan *data.RepoInfo)
	doneCh := make(chan struct{})

	go RepoInfos(cli, "Ruby", 10, 11, repoInfoCh, doneCh)

	for i := 0; i < 250; i++ {
		info := <-repoInfoCh
		assert.Equal(t, "hans", info.Owner)
	}
	<-doneCh
}

func TestRepoInfosPaginationStopAtMaxResults(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.String() {
		case
			"/search/repositories?page=1&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=2&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=3&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=4&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=5&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=6&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=7&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=8&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=9&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated",
			"/search/repositories?page=10&per_page=100&q=language%3ARuby+stars%3A10..11&sort=updated":
			fmt.Fprintf(w, makeSearchResult(100))

		case "/repos/hans/dotfiles/languages":
			fmt.Fprintf(w, `{ "Ruby": 111 }`)
		case "/repos/hans/dotfiles/contributors":
			fmt.Fprintf(w, "[]")

		default:
			panic("invalid url: " + r.URL.String())
		}
	}))
	defer ts.Close()

	cli := makeClient(ts.URL)

	repoInfoCh := make(chan *data.RepoInfo)
	doneCh := make(chan struct{})

	go RepoInfos(cli, "Ruby", 10, 11, repoInfoCh, doneCh)

	for i := 0; i < 1000; i++ {
		info := <-repoInfoCh
		assert.Equal(t, "hans", info.Owner)
	}
	<-doneCh
}
