package data

import (
	"regexp"

	"github.com/dziemba/seeker/env"
)

const (
	minScore = 20
)

var locationRegexp = regexp.MustCompile(`(?i)(` + env.Get("SEEKER_LOCATIONS") + `)`)

// ScoreOK checks whether the user has the minimum required score
func (u *User) ScoreOK() bool {
	return u.Score >= minScore
}

// DataOK checks whether the user has the minimum required fields matching
func (u *User) DataOK() bool {
	if !locationRegexp.MatchString(u.Location) {
		return false
	}

	if u.Email == "" {
		return false
	}

	return true
}
