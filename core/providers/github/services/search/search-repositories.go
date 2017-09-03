package search

import (
	"fmt"
	"os"
	"errors"
	"encoding/json"
	"sort"
	"github.com/google/go-github/github"
	"github.com/roscopecoltran/sniperkit-sift/providers/github/models"
	"github.com/roscopecoltran/sniperkit-sift/providers/github/utils"
	"github.com/roscopecoltran/sniperkit-sift/providers/github"
)

// GitHub API definition with a authorization token
var githubApi = github.New("https://github.github.com", os.Getenv("GITHUB_AUTH_TOKEN"))

type Searcher struct {
	Client *github.Client
}

func NewSearcher(accessToken string) *Searcher {
	return &Searcher{
		Client: github.NewClient(nil),
	}
}

func (s *Searcher) Search(query string) (*SearchResult, error) {
	opts := &github.SearchOptions{
		ListOptions: github.ListOptions{
			PerPage: 100,
			Page:    1,
		},
	}
	res, _, err := s.Client.Search.Code(query, opts)
	if err != nil {
		return nil, err
	}

	fmt.Printf("res: %+v\n", res)
	// TODO

	return &SearchResult{}, nil
}

// Try to get the languages used in the repository
func getRepositoryLanguages(repo *models.Repository) (map[string]interface{}, error) {
    service := fmt.Sprintf("repos/%s/%s/languages", repo.Owner.Login, repo.Name)
    body, err := githubApi.Get(service, map[string]string{})
    var langStats map[string]interface{}

    if err != nil {
        return nil, err
    } else if err := json.Unmarshal(body, &langStats); err != nil {
        return nil, err
    }
    return langStats, nil
}

// Try to resolve the languages of each repository in the repository array
// If it succeed it return the repositories that are updated with theirs languages
func resolveRepositoryLanguage(repositories []models.Repository) ([]models.Repository, error) {
    reqChan := make(chan error)
    nbRepositories:= len(repositories)
    chunkSize := nbRepositories / 10

    // Dipatch nbRepositories calls to block of chunkSize
    // 1 go routine handle chunkSize of calls to getRepositoryLanguages
    // Errors are propageted using the channel reqChan
    for i := 0; i < nbRepositories; i += chunkSize {
        go func(start int, end int) {
            for j := start; j < end && j < nbRepositories; j++ {
                stats, err := getRepositoryLanguages(&repositories[j])

                if err != nil {
                    reqChan <- err
                    return
                } else {
                    repositories[j].LanguageStats = stats
                }
            }
            reqChan <- nil
        }(i, i + chunkSize)
    }

    remaining := nbRepositories
    for {
        select {
        case err := <- reqChan:
            if err != nil {
                return nil, err
            }
            remaining -= chunkSize
            if remaining <= 0 {
                sort.Sort(models.RepositoryBySize(repositories))
                return repositories, nil
            }
        }
    }
}

// Search GitHub repositories by name
// It return the repositories sorted by size
func SearchRepositories(name string) ([]models.Repository, error) {
    var result models.searchResult

    params := map[string]string {
        "q" : name + " in:name",
        "type" : "repositories",
        "page" : "1",
        "per_page" : "100",
        "sort" : "stars",
        "order" : "desc",
    }
    body, err := githubApi.Get("search/repositories", params)
    if err != nil {
        return nil, err
    }
    if err := json.Unmarshal(body, &result); err != nil {
        return nil, err
    }
    if len(result.Items) > 0 {
        return resolveRepositoryLanguage(result.Items)
    }
    return nil, errors.New("No Results")
}