package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type XZ struct{}

func (xz XZ) Name() string {
	return "xz"
}

func (xz XZ) URL(version string) string {
	return fmt.Sprintf("https://tukaani.org/xz/xz-%s.tar.gz", version)
}

func (xz XZ) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(xz),
		Args: []string{
			"--disable-shared",
			"--enable-static",
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

func (xz XZ) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (xz XZ) Dependencies() []sift.Package {
	return []sift.Package{
		AutoMake{},
	}
}
