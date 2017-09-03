package docker

import (
	"fmt"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

var debug = false
var rules Rules

func (v Validation) validFrom() bool {
	for _, entry := range v.Rules.From {
		// If there's a wildcard, check the substring, otherwise, check the image
		if strings.Contains(entry, "/*") {
			seed := entry[:len(entry)-2]
			if strings.Contains(v.Dockerfile.From(), seed) {
				return true
			} else {
				return false
			}
		}
		if entry == v.Dockerfile.From() {
			return true
		}
	}
	return false
}

func (v Validation) isRootUser() bool {
	if v.Dockerfile.User() == "root" || v.Dockerfile.User() == "" {
		return true
	}
	return false
}

func (v Validation) isRootUserAllowed() bool {
	// Rules.RootUser = true allow root
	if v.Rules.AllowRootUser {
		return true
	} else {
		// root user not allowed
		if !v.isRootUser() {
			return true
		}
	}

	return false

}

func (v Validation) validate() (bool, string) {
	lines := []string{}
	valid := true
	if !v.validFrom() {
		valid = false
		lines = append(lines, "FROM not valid")
	}

	if v.isRootUser() {
		if !v.Rules.AllowRootUser {
			valid = false
			lines = append(lines, "Running as root")
		}
	}

	return valid, strings.Join(lines, "\n")

}

var (
	startDaemon = kingpin.Flag("daemon", "start a simple HTTP serving your slides.").Short('d').Bool()
	port        = kingpin.Flag("port", "port where to run the server.").Short('p').Default("8080").Int()

	dockerfile = kingpin.Flag("dockerfile", "dockerfile to be analysed").Short('f').Default("Dockerfile").String()
	rulesFile  = kingpin.Flag("rules", "Rules file").Short('r').String()
)

func dockerfileValidator() {
	kingpin.Parse()

	if *startDaemon {
		debug, _ = strconv.ParseBool(os.Getenv("DEBUG"))
		rules, _ = loadRulesFromFile("rules.yaml")
		log.Println("Daemon is listening in port", strconv.Itoa(*port))
		http.HandleFunc("/validate", validateHandler)
		http.HandleFunc("/setup", uploadHandler)
		http.HandleFunc("/rules", uploadRulesHandler)
		http.HandleFunc("/", defaultHandler)
		http.ListenAndServe(":8080", nil)

	} else {
		rules, _ = loadRulesFromFile(*rulesFile)
		dfile, _ := DockerfileFromPath(*dockerfile)

		v := Validation{rules, dfile}
		valid, msg := v.validate()
		if valid {
			fmt.Println("Dockerfile valid")
			os.Exit(0)
		} else {
			fmt.Println("Docker file not vallid:", msg)
			os.Exit(1)
		}

	}
}