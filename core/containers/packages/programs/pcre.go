package programs

// TODO: Requires aclocal-1.15
import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Pcre struct{}

func (pcre Pcre) Name() string {
	return "pcre"
}

func (pcre Pcre) URL(version string) string {
	return fmt.Sprintf("http://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-%s.tar.gz", version)
}

func (pcre Pcre) Build(config sift.Config) error {
  zlib := Zlib{}
	bzip2 := Bzip2{}
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(pcre),
		Args: []string{
			"--enable-unicode-properties",
			"--enable-static",
			"--disable-shared",
			"--enable-pcre16",
			"--enable-pcre32",
			"--enable-pcregrep-libz",
			"--enable-pcregrep-libbz2",
			"--enable-jit",
		},
		CFlags: []string{
			"-fPIC", // EditorConfig tries to build a shared lib, which requires a
			"-I" + config.IncludeDir(zlib),
			"-I" + config.IncludeDir(bzip2),
		},
		LdFlags: []string{
			"-L" + config.LibDir(zlib),
			"-L" + config.LibDir(bzip2),
		},
		Paths: []string{
			config.BinDir(AutoMake{}),
		},
	}.Cmd()
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

func (pcre Pcre) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (pcre Pcre) Dependencies() []sift.Package {
	return []sift.Package{
		AutoMake{},
		Bzip2{},
		Zlib{},
	}
}

