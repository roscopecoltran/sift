/*
 * Ferret
 * Copyright (c) 2016 Yieldbot, Inc.
 * For the full copyright and license information, please view the LICENSE.txt file.
 */

// Package consul implements Consul provider
package consul

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"

	"golang.org/x/net/context"
	"golang.org/x/net/context/ctxhttp"
)

// Register registers the provider
func Register(config map[string]interface{}, f func(interface{}) error) {

	name, ok := config["Name"].(string)
	if name == "" || !ok {
		name = "consul"
	}
	title, ok := config["Title"].(string)
	if title == "" || !ok {
		title = "Consul"
	}
	priority, ok := config["Priority"].(int64)
	if priority == 0 || !ok {
		priority = 0
	}
	url, _ := config["URL"].(string)
	query, _ := config["Query"].(string)
	rewrite, _ := config["Rewrite"].(string)

	p := Provider{
		provider: "consul",
		name:     name,
		title:    title,
		priority: priority,
		noui:     true,
		url:      strings.TrimSuffix(url, "/"),
		query:    query,
		rewrite:  rewrite,
	}
	if p.url != "" {
		p.enabled = true
	}

	if err := f(&p); err != nil {
		panic(err)
	}
}

// Provider represents the provider
type Provider struct {
	provider string
	enabled  bool
	name     string
	title    string
	priority int64
	noui     bool
	url      string
	query    string
	rewrite  string
}

// Search makes a search
func (provider *Provider) Search(ctx context.Context, args map[string]interface{}) ([]map[string]interface{}, error) {

	results := []map[string]interface{}{}
	page, ok := args["page"].(int)
	if page < 1 || !ok {
		page = 1
	}
	limit, ok := args["limit"].(int)
	if limit < 1 || !ok {
		limit = 10
	}
	keyword, ok := args["keyword"].(string)

	dcs, err := provider.datacenter()
	if err != nil {
		return nil, err
	}
	for _, dc := range dcs {

		u := fmt.Sprintf("%s/v1/catalog/services?dc=%s", provider.url, url.QueryEscape(dc))
		if provider.query != "" {
			u += fmt.Sprintf("%s", provider.query)
		}
		req, err := http.NewRequest("GET", u, nil)
		if err != nil {
			return nil, errors.New("failed to prepare request. Error: " + err.Error())
		}

		res, err := ctxhttp.Do(ctx, nil, req)
		if err != nil {
			return nil, err
		} else if res.StatusCode < 200 || res.StatusCode > 299 {
			return nil, errors.New("bad response: " + fmt.Sprintf("%d", res.StatusCode))
		}
		defer res.Body.Close()
		data, err := ioutil.ReadAll(res.Body)
		if err != nil {
			return nil, err
		}
		var sr SearchResult
		if err = json.Unmarshal(data, &sr); err != nil {
			return nil, errors.New("failed to unmarshal JSON data. Error: " + err.Error())
		}
		for k, v := range sr {
			if len(v) > 0 {
				for _, vv := range v {
					if strings.Contains(vv, keyword) || strings.Contains(k, keyword) {
						ri := map[string]interface{}{
							"Link":  fmt.Sprintf("%s/ui/#/%s/services/%s", provider.url, dc, k),
							"Title": fmt.Sprintf("%s.%s.service.%s.consul", vv, k, dc),
						}
						results = append(results, ri)
					}
				}
			} else {
				if strings.Contains(k, keyword) {
					ri := map[string]interface{}{
						"Link":  fmt.Sprintf("%s/ui/#/%s/services/%s", provider.url, dc, k),
						"Title": fmt.Sprintf("%s.service.%s.consul", k, dc),
					}
					results = append(results, ri)
				}
			}
		}

		if err != nil {
			return nil, err
		}
	}

	if len(results) > 0 {
		// TODO: implement sort
		var l, h = 0, limit
		if page > 1 {
			h = (page * limit)
			l = h - limit
		}
		if h > len(results) {
			h = len(results)
		}
		results = results[l:h]
	}

	return results, err
}

// datacenter gets the list of the datacenters
func (provider *Provider) datacenter() ([]string, error) {

	// Prepare the request
	query := fmt.Sprintf("%s/v1/catalog/datacenters", provider.url)
	req, err := http.NewRequest("GET", query, nil)

	// Make the request
	var client = &http.Client{}
	res, err := client.Do(req)
	if err != nil {
		return nil, err
	} else if res.StatusCode < 200 || res.StatusCode > 299 {
		return nil, errors.New("bad response: " + fmt.Sprintf("%d", res.StatusCode))
	}
	defer res.Body.Close()
	data, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	// Parse and prepare the result
	var result []string
	if err := json.Unmarshal(data, &result); err != nil {
		return nil, errors.New("failed to unmarshal JSON data. Error: " + err.Error())
	}

	return result, nil
}

// SearchResult represents the structure of the search result
type SearchResult map[string][]string