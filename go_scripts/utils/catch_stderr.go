package utils

import (
	"bytes"
	"os/exec"
)

func CatchStderr(cmd *exec.Cmd) *bytes.Buffer {
	var catcher bytes.Buffer
	cmd.Stderr = &catcher
	return &catcher
}
