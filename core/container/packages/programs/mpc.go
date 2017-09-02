package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type MPC struct{}

func (mpc MPC) Name() string {
	return "mpc"
}

func (mpc MPC) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/mpc/mpc-%s.tar.gz", version)
}

func (mpc MPC) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(mpc),
		Args: []string{
			"--disable-shared",
			"--enable-static",
			"--with-gmp=" + config.InstallDir(GMP{}),
			"--with-mpfr=" + config.InstallDir(MPFR{}),
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{
		Jobs: config.NumCores,
	}.Cmd()
	return make.Run()
}

func (mpc MPC) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (mpc MPC) Dependencies() []sift.Package {
	return []sift.Package{
		GMP{},
		MPFR{},
	}
}
