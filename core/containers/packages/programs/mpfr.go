package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type MPFR struct{}

func (mpfr MPFR) Name() string {
	return "mpfr"
}

func (mpfr MPFR) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/mpfr/mpfr-%s.tar.gz", version)
}

func (mpfr MPFR) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(mpfr),
		Args: []string{
			"--disable-shared",
			"--enable-static",
			"--with-gmp=" + config.InstallDir(GMP{}),
			"--enable-thread-safe",
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

func (mpfr MPFR) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (mpfr MPFR) Dependencies() []sift.Package {
	return []sift.Package{
		AutoMake{},
		GMP{},
	}
}
