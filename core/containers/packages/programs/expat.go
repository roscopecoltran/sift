package programs

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Expat struct{}

func (expat Expat) Name() string {
	return "expat"
}

func (expat Expat) URL(version string) string {
	underscoredVersion := strings.Replace(version, ".", "_", 2)
	return fmt.Sprintf("https://github.com/libexpat/libexpat/archive/R_%s.tar.gz", underscoredVersion)
}

func (expat Expat) Build(config sift.Config) error {

	expatDir := filepath.Join(config.BuildDir(expat), "expat")
	// CMake will probably be the way to go in future,
	// but until then we'll stick with configure.
	buildconf := exec.Command("./buildconf.sh")
	buildconf.Dir = expatDir
	if err := buildconf.Run(); err != nil {
		return err
	}

	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(expat),
		Args: []string{
			"--disable-shared",
			"--enable-static",
		},
		Dir: expatDir,
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Dir: expatDir,
	}.Cmd()
	return make.Run()
}

func (expat Expat) Install(config sift.Config) error {
	expatDir := filepath.Join(config.BuildDir(expat), "expat")
	makeInstall := sift.MakeCmd{
		Args: []string{
			// We don't use 'install' as this will try to generate documentation using docbook.
			"installlib",
		},
		Dir: expatDir,
	}.Cmd()
	return makeInstall.Run()
}

func (expat Expat) Dependencies() []sift.Package {
	return []sift.Package{
	}
}
