package utils

import (
	"net/http"
	"time"
)

// Wait for web UI to be available.
func WaitForBackend(timeout int) bool {
	for i := 0; i < timeout; i++ {
		if res, err := http.Get("http://127.0.0.1:8091/ui/index.html"); err == nil && res != nil && res.StatusCode == 200 {
			return true
		}

		time.Sleep(time.Second)
	}

	return false
}
