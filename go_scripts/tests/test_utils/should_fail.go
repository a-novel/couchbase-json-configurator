package test_utils

import (
	"fmt"
	"github.com/a-novel/divanDocker/start_script"
)

func ShouldFailWith(cancelSetup bool, expectedID, message string) {
	timer := Time(fmt.Sprintf("launching setup script (should fail when %s)...", message))
	timer.Important = true
	if _, err := start_script.Start(cancelSetup); err == nil {
		timer.EndWithError(fmt.Sprintf("should return an error when %s", message))
	} else if err.ID != expectedID {
		timer.UnexpectedErrID(expectedID, err, message)
	} else {
		timer.End(fmt.Sprintf("script failed successfully when %s", message))
	}
}
