package test_utils

import (
	"fmt"
	"github.com/a-novel/divanDocker/start_script"
)

func ShouldPass(cancelSetup bool, message string) {
	timer := Time(fmt.Sprintf("launching setup script (should pass when %s)...", message))
	timer.Important = true
	if _, err := start_script.Start(cancelSetup); err != nil {
		timer.EndWithError(fmt.Sprintf("failed to run when %s : %s", message, err.Error()))
	} else {
		timer.End(fmt.Sprintf("script ran successfully when %s", message))
	}
}
