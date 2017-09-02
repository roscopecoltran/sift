package librairies

import (
	"fmt"

	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type LibFFI struct{}

func (libffi LibFFI) Name() string {
	return "libffi"
}

func (libffi LibFFI) URL(version string) string {
	// We use the kernel.org mirror since it is avilable via https (not just ftp)
	return fmt.Sprintf("https://mirrors.kernel.org/sourceware/libffi/libffi-%s.tar.gz", version)
}

func (libffi LibFFI) Build(config sift.Config) error {
	// TODO: Remove this replacement, and rely on pkg-config to pick up libffi.
	err := gogurt.ReplaceInFile(
		"include/Makefile.in",
		"^includesdir.*",
		"includesdir = $(includedir)")
	if err != nil {
		fmt.Println("sed includesdir failed")
		return err
	}

	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(libffi),
		Args: []string{
			"--enable-static",
			"--disable-shared",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}

	err = gogurt.ReplaceInFile(
		"x86_64-unknown-linux-gnu/Makefile",
		"^toolexeclibdir.*",
		"toolexeclibdir = ${exec_prefix}\\/lib")
	if err != nil {
		return err
	}

	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (libffi LibFFI) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (libffi LibFFI) Dependencies() []sift.Package {
	return []sift.Package{}
}
