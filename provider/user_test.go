package provider

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	assert "github.com/stretchr/testify/require"

	"github.com/dziemba/seeker/data"
)

func TestGetUserInfoAllSet(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.String() {
		case "/users/hans":
			fmt.Fprintf(w, `{
				"name": "Hans Peter",
				"location": "Berlin",
				"company": "Initech",
				"email": "hans@example.com",
				"hireable": true
			}`)

		default:
			panic("invalid url: " + r.URL.String())
		}
	}))
	defer ts.Close()

	cli := makeClient(ts.URL)

	user := &data.User{Username: "hans"}
	GetUserInfo(cli, user)

	assert.Equal(t, &data.User{
		Username: "hans",
		Name:     "Hans Peter",
		Location: "Berlin",
		Company:  "Initech",
		Email:    "hans@example.com",
		Hireable: true,
	}, user)
}

func TestGetUserInfoNothingSet(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.String() {
		case "/users/hans":
			fmt.Fprintf(w, `{
				"name": null,
				"location": null,
				"company": null,
				"email": null,
				"hireable": null
			}`)

		default:
			panic("invalid url: " + r.URL.String())
		}
	}))
	defer ts.Close()

	cli := makeClient(ts.URL)

	user := &data.User{Username: "hans"}
	GetUserInfo(cli, user)

	assert.Equal(t, &data.User{
		Username: "hans",
	}, user)
}
