package cmd

import "testing"

// Test_Parse checks correctness of the command line
// parsing by running test cases.
func Test_Parse(t *testing.T) {
	testParse(t, ``, []string{""})
	testParse(t, `a`, []string{"a"})
	testParse(t, `a `, []string{"a"})
	testParse(t, `a  `, []string{"a"})
	testParse(t, `ab`, []string{"ab"})
	testParse(t, `ab `, []string{"ab"})
	testParse(t, `ab  `, []string{"ab"})
	testParse(t, `a c`, []string{"a", "c"})
	testParse(t, `a c `, []string{"a", "c"})
	testParse(t, `a cd`, []string{"a", "cd"})
	testParse(t, `a cd `, []string{"a", "cd"})
	testParse(t, `""`, []string{""})
	testParse(t, `""""`, []string{""})
	testParse(t, `" "`, []string{" "})
	testParse(t, `"a"`, []string{"a"})
	testParse(t, `"a"""`, []string{"a"})
	testParse(t, `a""`, []string{"a"})
	testParse(t, `a""b`, []string{"ab"})
}

func testParse(t *testing.T, test string, expected []string) {
	cmd, args := Parse(test)
	actual := append([]string{cmd}, args...)
	if len(actual) != len(expected) {
		t.Errorf("%#v => %#v != %#v", test, actual, expected)
	}
	for i := 0; i < len(actual) && i < len(expected); i++ {
		if actual[i] != expected[i] {
			t.Errorf("%#v => %#v != %#v", test, actual, expected)
		}
	}
}

func Test_GetLines(t *testing.T) {
	lines := GetLines("go version")
	if len(lines) != 1 {
		t.Errorf("Expect single line output from `go version`.")
	}
}

func Test_Get(t *testing.T) {
	output := Get("go version")
	if output == "" {
		t.Errorf("Expect non-empty output from `go version`.")
	}
}