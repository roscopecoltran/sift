package librairies

// TODO: Migrate to meson (recommended Python 3 build system).
// ./configure support will soon be deprecated.

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type FUSE struct{}

func (fuse FUSE) Name() string {
	return "fuse"
}

func (fuse FUSE) URL(version string) string {
	return fmt.Sprintf("https://github.com/libfuse/libfuse/releases/download/fuse-%s/fuse-%s.tar.gz", version, version)
}

func (fuse FUSE) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(fuse),
		Args: []string{
			"--disable-shared",
			"--enable-static",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (fuse FUSE) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (fuse FUSE) Dependencies() []sift.Package {
	return []sift.Package{

	}
}
