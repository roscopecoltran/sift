package builders

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Ninja struct{}

func (ninja Ninja) Name() string {
	return "ninja"
}

func (ninja Ninja) URL(version string) string {
	return fmt.Sprintf("https://github.com/ninja-build/ninja/archive/v%s.tar.gz", version)
}

func (ninja Ninja) Build(config sift.Config) error {
	configure := exec.Command("./configure.py", "--bootstrap")
	return configure.Run()
}

func (ninja Ninja) Install(config sift.Config) error {
	os.MkdirAll(config.BinDir(ninja), 0755)
	return gogurt.CopyFile(
		filepath.Join(config.BuildDir(ninja), "ninja"),
		filepath.Join(config.BinDir(ninja), "ninja"))
}

func (ninja Ninja) Dependencies() []sift.Package {
	return []sift.Package{}
}
