package score

import (
	"math"
	"sort"
	"testing"

	assert "github.com/stretchr/testify/require"

	"github.com/dziemba/seeker/data"
)

func TestScore(t *testing.T) {
	state := NewState()

	state.AddRepoInfo(&data.RepoInfo{
		Stars:           100,
		LangPercentages: map[string]float64{"Ruby": 0.1, "Go": 0.9},
		Contributions:   map[string]int{"hans": 20, "peter": 300},
	})
	state.AddRepoInfo(&data.RepoInfo{
		Stars:           200,
		LangPercentages: map[string]float64{"Scala": 0.8, "Ruby": 0.2},
		Contributions:   map[string]int{"hans": 200, "peter": 50},
	})

	users := state.GetUsersRanked()
	assert.Len(t, users, 2)

	peterScore := 300*math.Log1p(100) + 50*math.Log1p(200)
	hansScore := 20*math.Log1p(100) + 200*math.Log1p(200)
	assert.True(t, peterScore > hansScore)

	peter := users[0]
	assert.Equal(t, "peter", peter.Username)
	assert.InDelta(t, peterScore, peter.Score, 0.0001)
	assert.Equal(t, "Go: 75%, Scala: 12%, Ruby: 11%", peter.LanguageInfo)

	hans := users[1]
	assert.Equal(t, "hans", hans.Username)
	assert.InDelta(t, hansScore, hans.Score, 0.0001)
	assert.Equal(t, "Scala: 73%, Ruby: 19%, Go: 7%", hans.LanguageInfo)
}

func TestSortUsersByScore(t *testing.T) {
	users := []*data.User{
		{Username: "u1", Score: 10},
		{Username: "u2", Score: 100},
		{Username: "u3", Score: 5},
	}

	sort.Sort(usersByScore(users))

	assert.Equal(t, []*data.User{
		{Username: "u3", Score: 5},
		{Username: "u1", Score: 10},
		{Username: "u2", Score: 100},
	}, users)
}
