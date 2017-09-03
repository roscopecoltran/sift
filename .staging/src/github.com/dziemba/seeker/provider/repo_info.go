package provider

import (
	"fmt"

	"github.com/google/go-github/github"

	"github.com/dziemba/seeker/data"
)

const (
	itemsPerPage   = 100
	itemsPerSearch = 1000
)

// RepoInfos returns (almost) all repositories given the selected criteria via a channel
func RepoInfos(
	cli *github.Client,
	language string,
	starMin int,
	starMax int,
	repoInfoCh chan *data.RepoInfo,
	doneCh chan struct{},
) {
	for cursor := starMin; cursor < starMax; {
		start := cursor
		end := start + (start / 10)
		cursor = end

		query := fmt.Sprintf("language:%s stars:%d..%d", language, start, end)
		opts := &github.SearchOptions{
			Sort:        "updated",
			ListOptions: github.ListOptions{PerPage: itemsPerPage},
		}

		for page := 1; page <= itemsPerSearch/itemsPerPage; page++ {
			opts.ListOptions.Page = page
			res, _, _ := cli.Search.Repositories(query, opts)

			for _, repo := range res.Repositories {
				repoInfo := makeRepoInfo(cli, &repo)
				if repoInfo != nil {
					repoInfoCh <- repoInfo
				}
			}

			if len(res.Repositories) < itemsPerPage {
				break
			}
		}
	}

	doneCh <- struct{}{}
}

func makeRepoInfo(cli *github.Client, repo *github.Repository) *data.RepoInfo {
	info := &data.RepoInfo{
		Owner:         *repo.Owner.Login,
		Name:          *repo.Name,
		Stars:         *repo.StargazersCount,
		Contributions: make(map[string]int),
	}

	langs, _, _ := cli.Repositories.ListLanguages(info.Owner, info.Name)
	info.LangPercentages = makeLangPercentages(langs)
	if info.LangPercentages == nil {
		// GitHub cannot detect languages -> ignore this repo
		return nil
	}

	contributors, _, _ := cli.Repositories.ListContributors(
		info.Owner,
		info.Name,
		&github.ListContributorsOptions{},
	)
	for _, contrib := range contributors {
		info.Contributions[*contrib.Login] = *contrib.Contributions
	}

	return info
}

func makeLangPercentages(langBytes map[string]int) map[string]float64 {
	percentages := make(map[string]float64)

	totalBytes := 0
	for _, bytes := range langBytes {
		totalBytes += bytes
	}
	if totalBytes == 0 {
		return nil
	}

	for lang, bytes := range langBytes {
		percentages[lang] = float64(bytes) / float64(totalBytes)
	}

	return percentages
}
