package programs
// requires pexpect (python module)

import (
	"fmt"
	"os"
	"path/filepath"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type RR struct{}

func (rr RR) Name() string {
	return "rr"
}

func (rr RR) URL(version string) string {
	return fmt.Sprintf("https://github.com/mozilla/rr/archive/%s.tar.gz", version)
}

func (rr RR) Build(config sift.Config) error {
	buildDir := filepath.Join(config.BuildDir(rr), "build")
	os.Mkdir(buildDir, 0755)

	cmake := gogurt.CMakeCmd{
		Prefix: config.InstallDir(rr),
		SourceDir: config.BuildDir(rr),
		BuildDir: buildDir,
		CacheEntries: map[string]string{
			"disable32bit": "ON",
		},
		PkgConfigPaths: []string{
			config.PkgConfigLibDir(Zlib{}),
		},
	}.Cmd()

	if err := cmake.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Dir: buildDir,
	}.Cmd()
	return make.Run()
}

func (rr RR) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{
		Args: []string{"install"},
		Dir: filepath.Join(config.BuildDir(rr), "build"),
	}.Cmd()
	return makeInstall.Run()
}

func (rr RR) Dependencies() []sift.Package {
	return []sift.Package{
		Zlib{},
	}
}
