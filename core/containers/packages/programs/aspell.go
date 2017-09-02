package programs

// TODO: Include aspell-en dictionary, either here or as a separate package.
import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Aspell struct{}

func (aspell Aspell) Name() string {
	return "aspell"
}

func (aspell Aspell) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/aspell/aspell-%s.tar.gz", version)
}

func (aspell Aspell) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(aspell),
		Args: []string{
			"--enable-static",
			"--disable-shared",
		},
		CFlags: []string{
			"-I" + config.IncludeDir(Ncurses{}),
		},
		CxxFlags: []string{
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

func (aspell Aspell) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (aspell Aspell) Dependencies() []sift.Package {
	return []sift.Package{
		Ncurses{},
	}
}
