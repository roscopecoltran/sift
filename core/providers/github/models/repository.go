/*
The MIT License (MIT)

Copyright (c) 2016 Chaabane Jalal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package repos

import "time"

// This structure represent a Github Repository information
type Repository struct {
    ID int `json:"id"`
    Name string `json:"name"`
    FullName string `json:"full_name"`
    Owner User `json:"owner"`
    Private bool `json:"private"`
    HTMLURL string `json:"html_url"`
    Description string `json:"description"`
    Fork bool `json:"fork"`
    URL string `json:"url"`
    DeploymentsURL string `json:"deployments_url"`
    CreatedAt *time.Time `json:"created_at"`
    UpdatedAt *time.Time `json:"updated_at"`
    PushedAt *time.Time `json:"pushed_at"`
    CloneURL string `json:"clone_url"`
    SvnURL string `json:"svn_url"`
    Homepage string `json:"homepage"`
    Size int `json:"size"`
    StargazersCount int `json:"stargazers_count"`
    WatchersCount int `json:"watchers_count"`
    Language string `json:"language"`
    HasIssues bool `json:"has_issues"`
    HasDownloads bool `json:"has_downloads"`
    ForksCount int `json:"forks_count"`
    MirrorURL interface{} `json:"mirror_url"`
    OpenIssuesCount int `json:"open_issues_count"`
    Forks int `json:"forks"`
    OpenIssues int `json:"open_issues"`
    Watchers int `json:"watchers"`
    DefaultBranch string `json:"default_branch"`
    Score float64 `json:"score"`
    LanguageStats map[string]interface{} `json:"language_stats"`
}

type RepositoryBySize []Repository

func (a RepositoryBySize) Len() int           { return len(a) }
func (a RepositoryBySize) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a RepositoryBySize) Less(i, j int) bool { return a[i].Size > a[j].Size }