package builders

import (
	"fmt"
	"os/exec"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type AutoMake struct{}

func (automake AutoMake) Name() string {
	return "automake"
}

func (automake AutoMake) URL(version string) string {
	return fmt.Sprintf("https://ftp.gnu.org/gnu/automake/automake-%s.tar.gz", version)
}

// We hit a slight problem here.
// For some reason, a configure followed by a make would produce:
// Can't locate <gogurt_build>/automake/1.15.1/bin/automake in @INC (@INC contains: /usr/local/lib64/perl5 /usr/local/share/perl5 /usr/lib64/perl5/vendor_perl /usr/share/perl5/vendor_perl /usr/lib64/perl5 /usr/share/perl5 .) at <gogurt_build>/automake/1.15.1/t/wrap/automake-1.15 line 27.
// For this reason, we run bootstrap to regenerate the configure script.
// However, this would require that the documentation is regenerated using texinfo (which requires a new version of automake). For this reason, we only build the executable scripts.
func (automake AutoMake) Build(config sift.Config) error {
	bootstrap := exec.Command("./bootstrap")
	if err := bootstrap.Run(); err != nil {
		return err
	}
	configure := sift.ConfigureCmd{
		Prefix: config.InstallDir(automake),
	}.Cmd()
	return configure.Run()
}

func (automake AutoMake) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{Args: []string{"install-exec-am", "prefix=" + config.InstallDir(automake)}}.Cmd()
	return makeInstall.Run()
}

func (automake AutoMake) Dependencies() []sift.Package {
	return []sift.Package{
		AutoConf{},
	}
}

