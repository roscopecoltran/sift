package docker

import (
	"fmt"

	"github.com/stretchr/testify/assert"
	"os"
	"testing"
)

func TestValidFromQuay(t *testing.T) {
	rules, _ := loadRulesFromFile("rules.yaml")
	dfile, err := DockerfileFromPath("testfiles/Dockerfile.quay_unittest")
	v := Validation{rules, dfile}
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	assert.True(t, v.validFrom(), "FROM entry is valid")
}

func TestValidFrom(t *testing.T) {
	rules, _ := loadRulesFromFile("rules.yaml")
	dfile, err := DockerfileFromPath("testfiles/Dockerfile")
	v := Validation{rules, dfile}
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	assert.True(t, v.validFrom(), "FROM entry is valid")
}

func TestDockerfileRead(t *testing.T) {

	dfile, err := DockerfileFromPath("Dockerfile")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	assert.NotNil(t, dfile, "Read Dockerfile")
}

func TestFailFrom(t *testing.T) {
	rules, _ := loadRulesFromFile("rules.yaml")
	dfile, err := DockerfileFromPath("testfiles/Dockerfile.fail_unittest")
	v := Validation{rules, dfile}
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	assert.False(t, v.validFrom(), "FROM entry is valid")
}

func TestIsRootUser(t *testing.T) {
	rules, _ := loadRulesFromFile("testfiles/rules.yaml")
	dfile, err := DockerfileFromPath("testfiles/Dockerfile.fail_unittest")
	v := Validation{rules, dfile}
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	assert.True(t, v.isRootUser(), "Runs as root")
}

func TestIsNOTRootUser(t *testing.T) {
	rules, _ := loadRulesFromFile("testfiles/rules.yaml")
	dfile, err := DockerfileFromPath("testfiles/Dockerfile.unittest")
	v := Validation{rules, dfile}
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	assert.False(t, v.isRootUser(), "Runs as non root")
}

func TestValidate(t *testing.T) {
	rules, _ := loadRulesFromFile("testfiles/rules.yaml")
	dfile, err := DockerfileFromPath("testfiles/Dockerfile.unittest")
	v := Validation{rules, dfile}
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	r, _ := v.validate()
	assert.True(t, r, "Dockerfile is valid")
}

func TestRootUserAllowed(t *testing.T) {
	rules, _ := loadRulesFromFile("testfiles/rules.yaml")
	dfile, _ := DockerfileFromPath("testfiles/Dockerfile")
	v := Validation{rules, dfile}
	assert.True(t, v.isRootUserAllowed(), "Root user is allowed")

}

func TestUserAllowed(t *testing.T) {
	rules, _ := loadRulesFromFile("testfiles/rules.yaml")
	dfile, _ := DockerfileFromPath("testfiles/Dockerfile.unittest")
	v := Validation{rules, dfile}
	assert.True(t, v.isRootUserAllowed(), "Root user is allowed")
}

func TestRootUserNotAllowed(t *testing.T) {
	dfile, _ := DockerfileFromPath("testfiles/Dockerfile.fail_unittest")
	rules, _ := loadRulesFromFile("testfiles/rules.unittest.yaml")
	v := Validation{rules, dfile}
	assert.False(t, v.isRootUserAllowed(), "Root user is not allowed")
}