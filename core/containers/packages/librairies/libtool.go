package librairies

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type LibTool struct{}

func (libtool LibTool) Name() string {
	return "libtool"
}

func (libtool LibTool) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/libtool/libtool-%s.tar.gz", version)
}

func (libtool LibTool) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(libtool),
		Args: []string{
			"--disable-shared",
			"--enable-static",
			"--enable-ltdl-install",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Paths: []string{
			config.BinDir(AutoMake{}),
		},
	}.Cmd()
	return make.Run()
}

func (libtool LibTool) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (libtool LibTool) Dependencies() []sift.Package {
	return []sift.Package{
		AutoMake{},
		// TODO: Requires help2man
	}
}
