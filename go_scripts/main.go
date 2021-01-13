package main

import (
	"github.com/a-novel/divanDocker/start_script"
	"log"
)

func main() {
	start_script.StartListener()
	start_script.MarkAsProcessing()

	if err := start_script.Start(false); err != nil {
		start_script.MarkAsFaulty(err.Error())
		log.Fatal(err.Error())
	} else {
		start_script.MarkAsReady()
	}
}
