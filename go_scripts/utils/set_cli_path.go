package utils

import (
	"fmt"
	"github.com/a-novel/errors"
	"runtime"
)

const (
	ErrUnknownOS = "err_unknown_os"
)

func SetCLIPath() (string, *errors.Error) {
	switch runtime.GOOS {
	case "darwin":
		return "/Applications/Couchbase\\ Server.app/Contents/Resources/couchbase-core/bin/couchbase-cli", nil
	case "linux":
		return "/opt/couchbase/bin/couchbase-cli", nil
	default:
		return "", errors.New(ErrUnknownOS, fmt.Sprintf("unknown operating system %s", runtime.GOOS))
	}
}
