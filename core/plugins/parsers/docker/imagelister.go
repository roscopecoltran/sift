package docker

import (
	"fmt"
	"log"

	"gopkg.in/yaml.v2"
	"io/ioutil"
	"os"
)

type Compose struct {
	Service map[string]Services `yaml:"services"`
}
type Services struct {
	Image string `yaml:"image"`
}

func imageLister() {
	var tempFolder = "/tmp"
	var filename string
	if len(os.Args) > 1 {
		filename = os.Args[1]
	}

	if filename == "" {
		filename = tempFolder + "/docker-compose-dev.yml"
	}

	data , err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	var c Compose

	err = yaml.Unmarshal(data, &c)
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	outputFilename := tempFolder + "/images.txt"
	f, err :=os.OpenFile(outputFilename, os.O_WRONLY|os.O_CREATE, 0666)
	if err != nil {
		panic(err)
	}

	defer f.Close()

	for k := range c.Service {
		fmt.Fprintln(f,c.Service[k].Image)
	}

	log.Println("Successfully generated images file")
}