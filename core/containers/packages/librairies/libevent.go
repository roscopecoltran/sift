package librairies

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Libevent struct{}

func (libevent Libevent) Name() string {
	return "libevent"
}

func (libevent Libevent) URL(version string) string {
	return fmt.Sprintf("https://github.com/libevent/libevent/releases/download/release-%s/libevent-%s.tar.gz", version, version)
}

func (libevent Libevent) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.Prefix,
		Args: []string{
			"--enable-static",
			"--disable-shared",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (libevent Libevent) Install(config sift.Config) error {
	make := sift.MakeCmd{
		Args: []string{
			"install",
			"prefix=" + config.InstallDir(libevent),
		},
	}.Cmd()
	return make.Run()
}

func (libevent Libevent) Dependencies() []sift.Package {
	return []sift.Package{}
}
