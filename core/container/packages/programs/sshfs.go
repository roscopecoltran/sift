package programs

// TODO: Migrate to meson (recommended Python 3 build system).
// ./configure support will soon be deprecated.

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type SSHFS struct{}

func (sshfs SSHFS) Name() string {
	return "sshfs"
}

func (sshfs SSHFS) URL(version string) string {
	return fmt.Sprintf("https://github.com/libfuse/sshfs/releases/download/sshfs-%s/sshfs-%s.tar.gz", version, version)
}

func (sshfs SSHFS) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(sshfs),
		PkgConfigPaths: []string{
			config.PkgConfigLibDir(FUSE{}),
			config.PkgConfigLibDir(GLib{}),
			config.PkgConfigLibDir(Pcre{}),
		},
		LdFlags: []string{
			"-ldl",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (sshfs SSHFS) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (sshfs SSHFS) Dependencies() []sift.Package {
	return []sift.Package{
		FUSE{},
		GLib{},
	}
}
