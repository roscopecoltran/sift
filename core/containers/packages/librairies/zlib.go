package librairies

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Zlib struct{}

func (zlib Zlib) Name() string {
	return "zlib"
}

func (zlib Zlib) URL(version string) string {
	return fmt.Sprintf("http://zlib.net/zlib-%s.tar.gz", version)
}

func (zlib Zlib) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(zlib),
		Args: []string{ "--static" },
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (zlib Zlib) Install(config sift.Config) error {
	make := sift.MakeCmd{
		Args: []string{"install"},
		Jobs: config.NumCores,
	}.Cmd()
	return make.Run()
}

func (zlib Zlib) Dependencies() []sift.Package {
	return []sift.Package{}
}
