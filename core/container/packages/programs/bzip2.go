// Should really learn what 'package' does
package programs

import (
	"fmt"

	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Bzip2 struct {}

func (bzip2 Bzip2) Name() string {
	return "bzip2"
}

func (bzip2 Bzip2) URL(version string) string {
	return fmt.Sprintf("http://www.bzip.org/%s/bzip2-%s.tar.gz", version, version)
}


func (bzip2 Bzip2) Build(config sift.Config) error {
	cmd := sift.MakeCmd{Jobs: config.NumCores}.Cmd()
	fmt.Println(cmd)
	return cmd.Run()
}

func (bzip2 Bzip2) Install(config sift.Config) error {
	fmt.Println("Running bzip install...")
	cmd := sift.MakeCmd{
		Args: []string{
			"install",
			"PREFIX=" + config.InstallDir(bzip2),
		},
	}.Cmd()
	fmt.Println(cmd)
	return cmd.Run()
}

func (bzip2 Bzip2) Dependencies() []sift.Package {
	return []sift.Package{}
}
