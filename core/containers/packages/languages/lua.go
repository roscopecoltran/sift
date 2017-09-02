package packages

import (
	"fmt"
	"github.com/roscopecoltran/sniperkit-sift/core/sift"
)

type Lua struct{}

func (lua Lua) Name() string {
	return "lua"
}

func (lua Lua) URL(version string) string {
	return fmt.Sprintf("https://www.lua.org/ftp/lua-%s.tar.gz", version)
}

func (lua Lua) Build(config sift.Config) error {
	make := sift.MakeCmd{
		Jobs: config.NumCores,
		Args: []string{
			"linux",
			"MYCFLAGS=-I" + config.IncludeDir(ReadLine{}),
			"MYLDFLAGS=-L" + config.LibDir(ReadLine{}) + " -L" + config.LibDir(Ncurses{}),
			"MYLIBS=-ltinfow",
		},
	}.Cmd()
	return make.Run()
}

func (lua Lua) Install(config sift.Config) error {
	makeInstall := sift.MakeCmd{
		Args: []string{
			"install",
			"INSTALL_TOP=" + config.InstallDir(lua),
		},
	}.Cmd()
	return makeInstall.Run()
}

func (lua Lua) Dependencies() []sift.Package {
	return []sift.Package{
		Ncurses{},
		ReadLine{},
	}
}
