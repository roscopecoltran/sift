/*
 * Ferret
 * Copyright (c) 2016 Yieldbot, Inc.
 * For the full copyright and license information, please view the LICENSE.txt file.
 */

// Package api provides REST API functionality
package api

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	conf "github.com/roscopecoltran/sniperkit-sift/config"
	"github.com/yieldbot/ferret/search"
)

var (
	config    conf.Listen
	providers []provider
	port      string
)

// httpError represents an HTTP error
type httpError struct {
	StatusCode int    `json:"statusCode"`
	Error      string `json:"error"`
	Message    string `json:"message"`
}

// provider represents a provider
type provider struct {
	Name     string `json:"name"`
	Title    string `json:"title"`
	Priority int64  `json:"priority"`
}

// Init initializes the api
func Init(c conf.Config) {
	config = c.Listen
	port = os.Getenv("PORT")
	if port != "" {
		config.Address = ":" + port
	}
	if config.Address == "" {
		config.Address = ":3030"
	}

	// Prepare providers
	pl, err := parseProviderList(config.Providers, true)
	if err != nil {
		log.Fatal(err)
	}
	for _, v := range pl {
		p, err := search.ProviderByName(v)
		if err != nil {
			log.Fatal(err)
		}
		providers = append(providers, provider{
			Name:     p.Name,
			Title:    p.Title,
			Priority: p.Priority,
		})
	}

}

// Listen initializes HTTP handlers and listens for the requests
func Listen() {
	// Init handlers
	lpp := strings.TrimRight(config.Path, "/")
	// http.HandleFunc(fmt.Sprintf("%s/", lpp), assets.IndexHandler)
	http.HandleFunc(fmt.Sprintf("%s/search", lpp), SearchHandler)
	http.HandleFunc(fmt.Sprintf("%s/providers", lpp), ProvidersHandler)
	/*
	if config.Path != "" {
		http.Handle(lpp+"/public/", http.StripPrefix(lpp+"/public/", assets.PublicHandler()))
	} else {
		http.Handle("/public/", http.StripPrefix("/public/", assets.PublicHandler()))
	}
	*/
	if lpp != "" {
		http.HandleFunc(fmt.Sprintf("%s", lpp), RedirectHandler)
	}

	// Listen
	log.Printf("listening on %s", config.Address)
	if err := http.ListenAndServe(config.Address, nil); err != nil {
		log.Fatal(err)
	}
}

// parseProviderList parses the provider list from a given string
func parseProviderList(providerList string, defaults bool) ([]string, error) {
	// If the provider list is empty and defaults is true then create the list
	if providerList == "" && defaults == true {
		for _, v := range search.Providers() {
			if p, err := search.ProviderByName(v); err == nil {
				if p.Enabled == true && p.Noui == false {
					providerList += p.Name + ","
				}
			}
		}
	}

	// Iterate the provider list and check them
	var pl []string
	s := strings.Split(strings.TrimSpace(strings.Trim(providerList, ",")), ",")
	for _, v := range s {
		if v != "" {
			if _, err := search.ProviderByName(v); err != nil {
				return nil, err
			}
			pl = append(pl, v)
		}
	}
	return pl, nil
}

// CheckProvider checks whether the given provider is acceptable or not
func checkProvider(provider string) bool {
	for _, v := range providers {
		if v.Name == provider {
			return true
		}
	}
	return false
}

// RedirectHandler handles redirect for listen path prefix
func RedirectHandler(w http.ResponseWriter, req *http.Request) {
	http.Redirect(w, req, config.Path, 301)
}

// SearchHandler is the handler for the search route
func SearchHandler(w http.ResponseWriter, req *http.Request) {

	// Search
	q := search.Query{
		Provider: req.URL.Query().Get("provider"),
		Keyword:  req.URL.Query().Get("keyword"),
		Page:     search.ParsePage(req.URL.Query().Get("page")),
		Timeout:  search.ParseTimeout(req.URL.Query().Get("timeout")),
		Limit:    search.ParsePage(req.URL.Query().Get("limit")),
	}

	// Check the provider
	if !checkProvider(q.Provider) {
		w.WriteHeader(http.StatusBadRequest)
		data, _ := json.Marshal(httpError{
			StatusCode: http.StatusBadRequest,
			Error:      http.StatusText(http.StatusBadRequest),
			Message:    "invalid provider",
		})
		ResponseHandler(w, req, data)
		return
	}

	if err := q.Do(); err != nil {
		w.WriteHeader(q.HTTPStatus)
		data, _ := json.Marshal(httpError{
			StatusCode: q.HTTPStatus,
			Error:      http.StatusText(q.HTTPStatus),
			Message:    err.Error(),
		})
		ResponseHandler(w, req, data)
		return
	}

	// Prepare data
	var data []byte
	if len(q.Results) > 0 {
		var err error
		if req.URL.Query().Get("output") == "pretty" {
			data, err = json.MarshalIndent(q.Results, "", "  ")
		} else {
			data, err = json.Marshal(q.Results)
		}
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			data, _ := json.Marshal(httpError{
				StatusCode: http.StatusInternalServerError,
				Error:      http.StatusText(http.StatusInternalServerError),
				Message:    err.Error(),
			})
			ResponseHandler(w, req, data)
			return
		}
	}

	ResponseHandler(w, req, data)
}

// ProvidersHandler is the handler for the providers route
func ProvidersHandler(w http.ResponseWriter, req *http.Request) {

	// Prepare data
	var data []byte
	var err error
	if len(providers) > 0 {
		if req.URL.Query().Get("output") == "pretty" {
			data, err = json.MarshalIndent(providers, "", "  ")
		} else {
			data, err = json.Marshal(providers)
		}
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		data, _ := json.Marshal(httpError{
			StatusCode: http.StatusInternalServerError,
			Error:      http.StatusText(http.StatusInternalServerError),
			Message:    err.Error(),
		})
		ResponseHandler(w, req, data)
		return
	}

	ResponseHandler(w, req, data)
}

// ResponseHandler handles HTTP responses
func ResponseHandler(w http.ResponseWriter, req *http.Request, data []byte) {
	cb := req.URL.Query().Get("callback")
	if cb != "" {
		w.Header().Set("Content-Type", "application/javascript")
		fmt.Fprintf(w, "%s(%s)", cb, data)
	} else {
		w.Header().Set("Content-Type", "application/json")
		w.Write(data)
	}
}