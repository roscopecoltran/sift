package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Help2Man struct{}

func (help2man Help2Man) Name() string {
	return "help2man"
}

func (help2man Help2Man) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/help2man/help2man-%s.tar.xz", version)
}

func (help2man Help2Man) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(help2man),
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (help2man Help2Man) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (help2man Help2Man) Dependencies() []sift.Package {
	return []sift.Package{
	}
}
