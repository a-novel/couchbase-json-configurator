package utils

import (
	"fmt"
	"os/exec"
)

func Command(inst string, args ...string) (string, error) {
	cmd := exec.Command(inst, args...)
	stderr := CatchStderr(cmd)

	if stdout, err := cmd.Output(); err != nil {
		return "", fmt.Errorf("%s\n\terror : %s\n\toutput : %s", err.Error(), stderr.String(), string(stdout))
	} else {
		return string(stdout), nil
	}
}
