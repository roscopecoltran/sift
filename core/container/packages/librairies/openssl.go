package librairies

import (
	"fmt"
	"os/exec"

	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type OpenSSL struct{}

func (openssl OpenSSL) Name() string {
	return "openssl"
}

func (openssl OpenSSL) URL(version string) string {
	return fmt.Sprintf("https://www.openssl.org/source/openssl-%s.tar.gz", version)
}

func (openssl OpenSSL) Build(config sift.Config) error {
	zlib := Zlib{}
	configure := exec.Command(
		"./config",
		"--prefix=" + config.InstallDir(openssl),
		"no-shared",
		"--with-zlib-include=" + config.IncludeDir(zlib),
		"--with-zlib-lib=" + config.LibDir(zlib),
	)
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (openssl OpenSSL) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{
		Args: []string{"install"},
		Jobs: config.NumCores,
	}.Cmd()
	return makeInstall.Run()
}

func (openssl OpenSSL) Dependencies() []sift.Package {
	return []sift.Package{
		Zlib{},
	}
}

