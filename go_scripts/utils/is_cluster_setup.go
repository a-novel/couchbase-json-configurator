package utils

import (
	"fmt"
	"github.com/a-novel/divanDocker/credentials"
	"os"
)

func IsClusterSetup(creds *credentials.Credentials) bool {
	_, err := Command(
		"sh", "-c",
		fmt.Sprintf(
			"%s server-list -c 127.0.0.1 --username \"%s\" --password \"%s\"",
			os.Getenv("COUCHBASE_CLI_PATH"),
			creds.Username,
			creds.Password,
		),
	)

	return err == nil
}
