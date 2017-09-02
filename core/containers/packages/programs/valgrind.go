package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Valgrind struct{}

func (valgrind Valgrind) Name() string {
	return "valgrind"
}

func (valgrind Valgrind) URL(version string) string {
	return fmt.Sprintf("http://sourceware.org/pub/valgrind/valgrind-%s.tar.bz2", version)
}

func (valgrind Valgrind) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(valgrind),
		Args: []string{
			"--enable-only64bit",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (valgrind Valgrind) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (valgrind Valgrind) Dependencies() []sift.Package {
	return []sift.Package{}
}

