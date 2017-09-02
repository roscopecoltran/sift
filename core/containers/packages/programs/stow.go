package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Stow struct{}

func (stow Stow) Name() string {
	return "stow"
}

func (stow Stow) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/stow/stow-%s.tar.gz", version)
}

func (stow Stow) Build(config sift.Config) error {

	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(stow),
		Paths: []string{
			config.BinDir(AutoMake{}),
			config.BinDir(TexInfo{}),
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}

	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Paths: []string{
			config.BinDir(AutoMake{}),
			config.BinDir(TexInfo{}),
		},
	}.Cmd()
	return make.Run()
}

func (stow Stow) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{
		Args: []string{"install"},
		Paths: []string{
			config.BinDir(AutoMake{}),
			config.BinDir(TexInfo{}),
		},
	}.Cmd()
	return makeInstall.Run()
}

func (stow Stow) Dependencies() []sift.Package {
	return []sift.Package{TexInfo{}}
}
