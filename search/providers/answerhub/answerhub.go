/*
 * Ferret
 * Copyright (c) 2016 Yieldbot, Inc.
 * For the full copyright and license information, please view the LICENSE.txt file.
 */

// Package answerhub implements AnswerHub provider
package answerhub

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
	"time"

	"golang.org/x/net/context"
	"golang.org/x/net/context/ctxhttp"
)

// Register registers the provider
func Register(config map[string]interface{}, f func(interface{}) error) {

	name, ok := config["Name"].(string)
	if name == "" || !ok {
		name = "answerhub"
	}
	title, ok := config["Title"].(string)
	if title == "" || !ok {
		title = "AnswerHub"
	}
	priority, ok := config["Priority"].(int64)
	if priority == 0 || !ok {
		priority = 1000
	}
	url, _ := config["URL"].(string)
	username, _ := config["Username"].(string)
	password, _ := config["Password"].(string)
	query, _ := config["Query"].(string)
	rewrite, _ := config["Rewrite"].(string)

	p := Provider{
		provider: "answerhub",
		name:     name,
		title:    title,
		priority: priority,
		url:      strings.TrimSuffix(url, "/"),
		username: username,
		password: password,
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
	url      string
	username string
	password string
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

	u := fmt.Sprintf("%s/services/v2/node.json?page=%d&pageSize=%d&q=%s*", provider.url, page, limit, url.QueryEscape(keyword))
	if provider.query != "" {
		u += fmt.Sprintf("%s", provider.query)
	}
	req, err := http.NewRequest("GET", u, nil)
	if err != nil {
		return nil, errors.New("failed to prepare request. Error: " + err.Error())
	}
	if provider.username != "" || provider.password != "" {
		req.SetBasicAuth(provider.username, provider.password)
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
	if err := json.Unmarshal(data, &sr); err != nil {
		return nil, errors.New("failed to unmarshal JSON data. Error: " + err.Error())
	}
	for _, v := range sr.List {
		d := strings.TrimSpace(v.Body)
		if len(d) > 255 {
			d = d[0:252] + "..."
		} else if len(d) == 0 {
			if v.Author.Realname != "" {
				d = "Asked by " + v.Author.Realname
			} else {
				d = "Asked by " + v.Author.Username
			}
		}
		ri := map[string]interface{}{
			"Link":        fmt.Sprintf("%s/questions/%d/", provider.url, v.ID),
			"Title":       v.Title,
			"Description": d,
			"Date":        time.Unix(0, v.CreationDate*int64(time.Millisecond)),
		}
		results = append(results, ri)
	}

	return results, err
}

// SearchResult represents the structure of the search result
type SearchResult struct {
	List []*SRList `json:"list"`
}

// SRList represents the structure of the search result list
type SRList struct {
	ID           int        `json:"id"`
	Title        string     `json:"title"`
	Body         string     `json:"body"`
	Author       *SRLAuthor `json:"author"`
	CreationDate int64      `json:"creationDate"`
}

// SRLAuthor represents the structure of the search result list author field
type SRLAuthor struct {
	Username string `json:"username"`
	Realname string `json:"realname"`
}