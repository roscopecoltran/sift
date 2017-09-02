package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

// This does not produce a "pure" static fish; it still has dependencies on
// system libraries:
//   linux-vdso.so.1
//   libdl.so.2 => /lib64/libdl.so.2
//   libpthread.so.0 => /lib64/libpthread.so.0
//   librt.so.1 => /lib64/librt.so.1
//   libstdc++.so.6 => /lib64/libstdc++.so.6
//   libm.so.6 => /lib64/libm.so.6
//   libgcc_s.so.1 => /lib64/libgcc_s.so.1
//   libc.so.6 => /lib64/libc.so.6
//   /lib64/ld-linux-x86-64.so.2
// The reason for this is that we still need a dependency on getpwnam_r, so that
// fish doesn't crash if it tries to expand ~.
// TODO: Revisit this issue once we are using musl.

type Fish struct{}

func (fish Fish) Name() string {
	return "fish"
}

func (fish Fish) URL(version string) string {
	return fmt.Sprintf("https://fishshell.com/files/%s/fish-%s.tar.gz", version, version)
}

func (fish Fish) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(fish),
		Args: []string{
			"--without-doxygen",
		},
		CxxFlags: []string{
			"-I" + config.IncludeDir(Ncurses{}),
		},
		CppFlags: []string{
			"-I" + config.IncludeDir(Ncurses{}),
		},
		LdFlags: []string{
			"-L" + config.LibDir(Ncurses{}),
		},
		Libs: []string{
			"-ltinfow",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (fish Fish) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (fish Fish) Dependencies() []sift.Package {
	return []sift.Package{
		Ncurses{},
	}
}
