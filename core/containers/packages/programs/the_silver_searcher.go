package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type TheSilverSearcher struct{}

func (ag TheSilverSearcher) Name() string {
	return "the_silver_searcher"
}

func (ag TheSilverSearcher) URL(version string) string {
	return fmt.Sprintf("http://geoff.greer.fm/ag/releases/the_silver_searcher-%s.tar.gz", version)
}

func (ag TheSilverSearcher) Build(config sift.Config) error {
	// pkg-config is messing up for some reason.
	gogurt.ReplaceInFile("configure", "^ *PKG_CHECK_MODULES.*", "")
	gogurt.ReplaceInFile("configure.ac", "^ *PKG_CHECK_MODULES.*", "")

	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(ag),
		Args: []string{
			"--enable-zlib",
			"--enable-lzma",
		},
		CFlags: []string{
			"-I" + config.IncludeDir(Pcre{}),
			"-I" + config.IncludeDir(XZ{}),
			"-I" + config.IncludeDir(Zlib{}),
		},
		CppFlags: []string{
			"-I" + config.IncludeDir(Pcre{}),
			"-I" + config.IncludeDir(XZ{}),
			"-I" + config.IncludeDir(Zlib{}),
		},
		LdFlags: []string{
			"-L" + config.LibDir(Pcre{}),
			"-L" + config.LibDir(XZ{}),
			"-L" + config.LibDir(Zlib{}),
		},
		Libs: []string{
			"-lpcre",
			"-llzma",
			"-lz",
		},
	}.Cmd()

	configure.Env = append(
		configure.Env,
		"PCRE_CFLAGS=-I" + config.IncludeDir(Pcre{}),
		"PCRE_LIBS=-L" + config.LibDir(Pcre{}) + " -lpcre",
		"LZMA_CFLAGS=-I" + config.IncludeDir(XZ{}),
		"LZMA_LIBS=-L" + config.LibDir(XZ{}) + " -llzma",
	)
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Paths: []string{
			config.BinDir(AutoMake{}),
		},
	}.Cmd()
	return make.Run()
}

func (ag TheSilverSearcher) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (ag TheSilverSearcher) Dependencies() []sift.Package {
	return []sift.Package{
		AutoMake{},
		Pcre{},
		XZ{},
		Zlib{},
	}
}
