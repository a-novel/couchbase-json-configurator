package test_utils

import (
	"fmt"
	"github.com/a-novel/divanDocker/utils"
	"os"
	"testing"
	"time"
)

func Clean(t *testing.T) {
	_, err := utils.Command("sh", fmt.Sprintf("%s/scripts/cleaner.sh", os.Getenv("DIVAN_SCRIPTS")))
	timer := Time("shutting down cluster...")

	if err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot shut down cluster : %s", err.Error()), t)
	} else {
		timer.End("shut down cluster successfully")
	}

	// Necessary because Couchbase Server doesn't stop immediately.
	time.Sleep(10 * time.Second)
}
