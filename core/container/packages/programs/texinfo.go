package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type TexInfo struct{}

func (texinfo TexInfo) Name() string {
	return "texinfo"
}

func (texinfo TexInfo) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/texinfo/texinfo-%s.tar.gz", version)
}

func (texinfo TexInfo) Build(config sift.Config) error {

	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(texinfo),
		Args: []string{
			"--disable-perl-api-texi-build",
		},
		Paths: []string{
			config.BinDir(AutoMake{}),
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

func (texinfo TexInfo) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (texinfo TexInfo) Dependencies() []sift.Package {
	return []sift.Package{
		AutoMake{},
	}
}
