package test_utils

import (
	"fmt"
	"github.com/a-novel/divanDocker/utils"
	"os"
	"testing"
)

func Launch(t *testing.T) {
	_, err := utils.Command("sh", fmt.Sprintf("%s/scripts/launcher.sh", os.Getenv("DIVAN_SCRIPTS")))
	timer := Time("starting cluster...")

	if err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot start cluster : %s", err.Error()), t)
	} else {
		timer.End("started cluster successfully")
	}
}
