package data

import (
	"testing"

	assert "github.com/stretchr/testify/require"
)

func TestScoreOK(t *testing.T) {
	u1 := &User{Score: 0}
	u2 := &User{Score: 10}
	u3 := &User{Score: 20}
	u4 := &User{Score: 10000}

	assert.False(t, u1.ScoreOK())
	assert.False(t, u2.ScoreOK())
	assert.True(t, u3.ScoreOK())
	assert.True(t, u4.ScoreOK())
}

func TestDataOK(t *testing.T) {
	// ok
	u1 := &User{Location: "Berlin", Email: "foo@example.com"}

	// no email
	u2 := &User{Location: "Berlin"}

	// wrong location
	u3 := &User{Location: "San Francisco", Email: "foo@example.com"}

	assert.True(t, u1.DataOK())
	assert.False(t, u2.DataOK())
	assert.False(t, u3.DataOK())
}
