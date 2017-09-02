package programs

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type GetText struct{}

func (gettext GetText) Name() string {
	return "gettext"
}

func (gettext GetText) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/gettext/gettext-%s.tar.xz", version)
}

func (gettext GetText) Build(config sift.Config) error {
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(gettext),
		Args: []string{
			"--enable-static",
			"--disable-shared",
			"--with-included-glib",
		},
	}.Cmd()
	if err := configure.Run(); err != nil {
		return err
	}
	make := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	return make.Run()
}

func (gettext GetText) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install"}}.Cmd()
	return makeInstall.Run()
}

func (gettext GetText) Dependencies() []sift.Package {
	return []sift.Package{}
}

