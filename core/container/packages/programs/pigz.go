package programs

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Pigz struct{}

func (pigz Pigz) Name() string {
	return "pigz"
}

func (pigz Pigz) URL(version string) string {
	return fmt.Sprintf("https://zlib.net/pigz/pigz-%s.tar.gz", version)
}

func (pigz Pigz) Build(config sift.Config) error {
	gogurt.CopyFile(filepath.Join(config.IncludeDir(Zlib{}), "zlib.h"), config.BuildDir(pigz))
	gogurt.CopyFile(filepath.Join(config.IncludeDir(Zlib{}), "zconf.h"), config.BuildDir(pigz))
	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Args: []string{
			"LDFLAGS=-static -L" + config.LibDir(Zlib{}),
		},
	}.Cmd()
	return make.Run()
}

func (pigz Pigz) Install(config sift.Config) error {
	os.MkdirAll(config.BinDir(pigz), 0755)
	return gogurt.CopyFile(filepath.Join(config.BuildDir(pigz), "pigz"), config.BinDir(pigz))
}

func (pigz Pigz) Dependencies() []sift.Package {
	return []sift.Package{
		Zlib{},
	}
}
