package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type GMP struct{}

func (gmp GMP) Name() string {
	return "gmp"
}

func (gmp GMP) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/gmp/gmp-%s.tar.xz", version)
}

func (gmp GMP) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(gmp),
		Args: []string{
			"--disable-shared",
			"--enable-static",
			"--enable-cxx",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (gmp GMP) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (gmp GMP) Dependencies() []sift.Package {
	return []sift.Package{}
}
