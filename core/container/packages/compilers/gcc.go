package compilers

import (
	"fmt"
	"os"
	"path/filepath"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

// TODO: Link to our own zlib

type GCC struct{}

func (gcc GCC) Name() string {
	return "gcc"
}

func (gcc GCC) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/pub/gnu/gcc/gcc-%s/gcc-%s.tar.gz", version, version)
}

func (gcc GCC) Build(config sift.Config) error {
	buildDir := filepath.Join(config.BuildDir(gcc), "build")
	os.MkdirAll(buildDir, 0755)
  // A lot of the options aren't documented in the root ./configure --help.
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(gcc),
		Args: []string{
			"--disable-shared",
			"--enable-static",
			"--disable-libada",
			"--disable-multilib", // we're not supporting 32-bit systems.
			"--enable-languages=c,c++",
			"--with-gmp=" + config.InstallDir(GMP{}),
			"--with-mpfr=" + config.InstallDir(MPFR{}),
			"--with-mpc=" + config.InstallDir(MPC{}),
			// "--with-system-zlib", // can't seem to link in our own. :/
		},
		Dir: buildDir,
		CFlags: []string{
			// "-I" + config.IncludeDir(Zlib{}),
		},
		CppFlags: []string{
			// "-I" + config.IncludeDir(Zlib{}),
		},
		CxxFlags: []string{
			// "-I" + config.IncludeDir(Zlib{}),
		},
		LdFlags: []string{
			// "-L" + config.LibDir(Zlib{}),
		},
		Libs: []string{
			// "-lz",
		},
	}.Cmd()
	// We're calling configure in the root of the source, but from inside the build directory.
	configure.Path = "../configure"
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Dir: buildDir,
	}.Cmd()
	return make.Run()
}

func (gcc GCC) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (gcc GCC) Dependencies() []sift.Package {
	return []sift.Package{
		GMP{},
		MPC{},
		MPFR{},
		Zlib{},
	}
}
