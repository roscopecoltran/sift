package score

import (
	"math"
	"sort"

	"github.com/dziemba/seeker/data"
)

type languageScoreMap map[string]float64
type userLanguageScoreMap map[string]languageScoreMap

// State keeps state about repository contributions for user scoring
type State struct {
	userLanguageScores userLanguageScoreMap
}

// NewState creates a new State instance
func NewState() *State {
	return &State{
		userLanguageScores: make(userLanguageScoreMap),
	}
}

// AddRepoInfo adds contributions from a single repository to the scoring state
func (s *State) AddRepoInfo(repoInfo *data.RepoInfo) {
	starFactor := math.Log1p(float64(repoInfo.Stars))

	for user, commits := range repoInfo.Contributions {
		uc := s.userCommits(user)

		for lang, langFactor := range repoInfo.LangPercentages {
			uc[lang] += langFactor * float64(commits) * starFactor
		}
	}
}

type usersByScore []*data.User

func (a usersByScore) Len() int           { return len(a) }
func (a usersByScore) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a usersByScore) Less(i, j int) bool { return a[i].Score < a[j].Score }

// GetUsersRanked returns a list of users with their scores and languageInfo strings
func (s *State) GetUsersRanked() []*data.User {
	var users []*data.User

	for username, languageScores := range s.userLanguageScores {
		user := &data.User{Username: username, LanguageInfo: languageScores.infoString()}
		for _, langScore := range languageScores {
			user.Score += langScore
		}

		users = append(users, user)
	}

	sort.Sort(sort.Reverse(usersByScore(users)))

	return users
}

func (s *State) userCommits(user string) languageScoreMap {
	if s.userLanguageScores[user] == nil {
		s.userLanguageScores[user] = make(languageScoreMap)
	}

	return s.userLanguageScores[user]
}
