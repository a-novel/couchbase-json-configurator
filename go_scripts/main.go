package main

import (
	"github.com/a-novel/divanDocker/start_script"
	"log"
)

func main() {
	if err := start_script.Start(false); err != nil {
		log.Fatal(err.Error())
	}
}
