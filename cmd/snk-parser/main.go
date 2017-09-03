package main

import (
    "fmt"
    "os/exec"
	"github.com/roscopecoltran/sniperkit-sift/core/plugins/parsers"
)

func main() {

	// Open file in CONTAINER_SCRIPT_DIR

    // here is a somewhat complex command line to execute
	fullCommand := `echo -e 'Starting LS\n===========' && ls -la && echo -e "===========\nI'm Done."`

    // split, so we can run this on the command line...
    cmmd, args := parsers.Split(fullCommand)

    // you should be checking errors, even though I don't here.
    // run it!
    o, _ := os.Command(cmmd, args...).Output()
    
    // output the current directory
    fmt.Println(string(o))


	src := parsers.GetLines("find . -name *.go")
	version := parsers.Get("go version")
	parsers.Run("go build")

}
