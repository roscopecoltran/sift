package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type ReadLine struct{}

func (readline ReadLine) Name() string {
	return "readline"
}

func (readline ReadLine) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/readline/readline-%s.tar.gz", version)
}

func (readline ReadLine) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(readline),
		Args: []string{
			"--disable-shared",
			"--enable-static",
			"--enable-multibyte",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (readline ReadLine) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (readline ReadLine) Dependencies() []sift.Package {
	return []sift.Package{

	}
}
