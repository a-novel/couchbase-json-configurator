package main

import (
	"github.com/a-novel/divanDocker/start_script"
	"time"
)

func main() {
	go start_script.StartListener()
	start_script.MarkAsProcessing()
	_, err := start_script.Start(false)

	if err != nil {
		start_script.MarkAsFaulty(err.Error())
	} else {
		start_script.MarkAsReady()
	}

	// Prevent status server from exiting.
	done := make(chan bool)
	go func() {
		for {
			time.Sleep(time.Second)
		}
	}()
	<-done
}
