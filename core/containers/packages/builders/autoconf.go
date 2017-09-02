package builders

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type AutoConf struct{}

func (autoconf AutoConf) Name() string {
	return "autoconf"
}

func (autoconf AutoConf) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/autoconf/autoconf-%s.tar.gz", version)
}

func (autoconf AutoConf) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(autoconf),
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (autoconf AutoConf) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (autoconf AutoConf) Dependencies() []sift.Package {
	return []sift.Package{

	}
}
