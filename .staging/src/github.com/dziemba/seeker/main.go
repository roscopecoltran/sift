package main

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/google/go-github/github"

	"github.com/dziemba/seeker/data"
	"github.com/dziemba/seeker/env"
	"github.com/dziemba/seeker/httpclient"
	"github.com/dziemba/seeker/provider"
	"github.com/dziemba/seeker/score"
)

const (
	repoMaxStars = 150000
	cacheDir     = "cache"
)

func repoMinStars() (num int) {
	num, _ = strconv.Atoi(env.Get("SEEKER_REPO_MIN_STARS"))

	if num < 1 {
		panic("SEEKER_REPO_MIN_STARS too small!")
	} else if num >= repoMaxStars {
		panic("SEEKER_REPO_MIN_STARS too large!")
	}

	return
}

func main() {
	cli := httpclient.New(env.Get("SEEKER_GITHUB_TOKEN"), cacheDir)
	gh := github.NewClient(cli)

	scores := score.NewState()

	repoInfoCh := make(chan *data.RepoInfo, 100)
	doneCh := make(chan struct{})

	languages := strings.Split(env.Get("SEEKER_LANGUAGES"), "|")
	for _, lang := range languages {
		go provider.RepoInfos(gh, lang, repoMinStars(), repoMaxStars, repoInfoCh, doneCh)

	fetch:
		for {
			select {
			case <-doneCh:
				break fetch

			case repoInfo := <-repoInfoCh:
				scores.AddRepoInfo(repoInfo)
			}
		}
	}

	users := scores.GetUsersRanked()

	for _, user := range users {
		if !user.ScoreOK() {
			continue
		}

		provider.GetUserInfo(gh, user)

		if !user.DataOK() {
			continue
		}

		fmt.Printf("%s\t%s\t%d\t%s\t%s\t%s\t%s\t%t\n",
			user.Username, user.Name, int(user.Score), user.LanguageInfo,
			user.Location, user.Company, user.Email, user.Hireable,
		)
	}
}
