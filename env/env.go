package env

import (
	"os"
)

// Get returns the value of the specified ENV variable and panics if it is not set.
func Get(name string) (val string) {
	val = os.Getenv(name)
	if val == "" {
		panic("Please set " + name + " in your ENV!")
	}
	return
}
