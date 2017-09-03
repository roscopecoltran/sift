package env

import (
	"testing"

	assert "github.com/stretchr/testify/require"
)

func TestGetPresent(t *testing.T) {
	home := Get("HOME")
	assert.True(t, len(home) > 3)
}

func TestGetAbsent(t *testing.T) {
	defer func() {
		assert.Equal(t, recover(), "Please set SOMETHING_THAT_SHOULD_NEVER_EXIST in your ENV!")
	}()

	Get("SOMETHING_THAT_SHOULD_NEVER_EXIST")
}
