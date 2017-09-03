package score

import (
	"sort"
	"testing"

	assert "github.com/stretchr/testify/require"
)

func TestInfoString(t *testing.T) {
	lsm := languageScoreMap{
		"Scala": 100,
		"Ruby":  200,
	}

	assert.Equal(t, "Ruby: 66%, Scala: 33%", lsm.infoString())
}

func TestInfoStringMany(t *testing.T) {
	lsm := languageScoreMap{
		"Scala":  400,
		"Ruby":   500,
		"Python": 200,
		"Golang": 300,
		"C":      100,
	}

	assert.Equal(t, "Ruby: 33%, Scala: 26%, Golang: 20%, Python: 13%", lsm.infoString())
}

func TestInfoStringLittle(t *testing.T) {
	lsm := languageScoreMap{
		"Scala": 96,
		"Ruby":  4,
	}

	assert.Equal(t, "Scala: 96%", lsm.infoString())
}

func TestInfoStringEmpty(t *testing.T) {
	lsm := languageScoreMap{}

	assert.Equal(t, "Unknown", lsm.infoString())
}

func TestSortLanguageAndScore(t *testing.T) {
	langs := []languageAndScore{
		{"Ruby", 4.23},
		{"Go", 14.23},
		{"Scala", 1.23},
	}

	sort.Sort(langsByScore(langs))

	assert.Equal(t, []languageAndScore{
		{"Scala", 1.23},
		{"Ruby", 4.23},
		{"Go", 14.23},
	}, langs)
}
