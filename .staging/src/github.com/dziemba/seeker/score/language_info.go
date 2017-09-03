package score

import (
	"fmt"
	"sort"
)

const (
	languageInfoMinPercent = 5
	languageInfoMaxLangs   = 4
)

type languageAndScore struct {
	language string
	score    float64
}

type langsByScore []languageAndScore

func (a langsByScore) Len() int           { return len(a) }
func (a langsByScore) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a langsByScore) Less(i, j int) bool { return a[i].score < a[j].score }

func (lsm languageScoreMap) infoString() string {
	var langArr []languageAndScore

	totalScore := 0.0
	for language, score := range lsm {
		totalScore += score
		langArr = append(langArr, languageAndScore{language: language, score: score})
	}

	sort.Sort(sort.Reverse(langsByScore(langArr)))

	str := ""
	for i, ls := range langArr {
		if i >= languageInfoMaxLangs {
			break
		}

		percent := 100.0 * ls.score / totalScore
		if percent > languageInfoMinPercent {
			str += fmt.Sprintf("%s: %d%%, ", ls.language, int(percent))
		}
	}

	if str == "" {
		return "Unknown"
	}

	return str[:len(str)-2]
}
