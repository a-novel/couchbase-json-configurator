package docker_tests

import (
	"fmt"
	"path/filepath"
	"runtime"
)

func getExecPath() (string, error) {
	_, filename, _, ok := runtime.Caller(1)
	if !ok {
		return "", fmt.Errorf("cannot read current path")
	}

	return filepath.Dir(filename), nil
}
