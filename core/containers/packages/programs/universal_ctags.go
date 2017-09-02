package programs

import (
	"fmt"
	"os/exec"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type UniversalCTags struct{}

func (ctags UniversalCTags) Name() string {
	return "universal-ctags"
}

func (ctags UniversalCTags) URL(version string) string {
	return fmt.Sprintf("https://github.com/universal-ctags/ctags/archive/%s.tar.gz", version)
}

func (ctags UniversalCTags) Build(config sift.Config) error {

	bootstrap := exec.Command("./autogen.sh")
	if err := bootstrap.Run(); err != nil {
		return err
	}

	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(ctags),
		Paths: []string{
			config.BinDir(AutoConf{}),
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}

	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (ctags UniversalCTags) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (ctags UniversalCTags) Dependencies() []sift.Package {
	return []sift.Package{
		AutoConf{},
	}
}

