package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type CCache struct{}

func (ccache CCache) Name() string {
	return "ccache"
}

func (ccache CCache) URL(version string) string {
	return fmt.Sprintf("https://www.samba.org/ftp/ccache/ccache-%s.tar.xz", version)
}

func (ccache CCache) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(ccache),
		CFlags: []string{
			"-I" + config.IncludeDir(Zlib{}),
		},
		LdFlags: []string{
			"-L" + config.LibDir(Zlib{}),
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (ccache CCache) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (ccache CCache) Dependencies() []sift.Package {
	return []sift.Package{
		Zlib{},
	}
}
