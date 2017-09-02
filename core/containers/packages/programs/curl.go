package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

// Note that this does not generate a completely static binary,
// but one that links to system libraries, like linux-vdso.so.1 and libc.so.6.

type Curl struct{}

func (curl Curl) Name() string {
	return "curl"
}

func (curl Curl) URL(version string) string {
	return fmt.Sprintf("https://curl.haxx.se/download/curl-%s.tar.gz", version)
}

func (curl Curl) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(curl),
		Args: []string{
			"--disable-shared",
			"--enable-static",
			"--with-ssl=" + config.InstallDir(OpenSSL{}),
			"--with-zlib=" + config.InstallDir(Zlib{}),
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (curl Curl) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (curl Curl) Dependencies() []sift.Package {
	return []sift.Package{
		OpenSSL{},
		Zlib{},
	}
}
