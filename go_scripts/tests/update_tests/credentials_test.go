package update_tests

import (
	"fmt"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/a-novel/divanDocker/utils"
	"os"
	"testing"
)

func TestCredentialsUpdate(t *testing.T) {
	test_utils.Clean(t)
	test_utils.Launch(t)
	defer test_utils.Clean(t)

	dconf := config.Config{
		Resources: resources.Resources{
			RamSize:      1024,
			FtsRamSize:   256,
			IndexRamSize: 256,
		},
		Credentials: credentials.Credentials{
			Username: "Administrator",
			Password: "password",
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(false, "credentials are setup")

	if !utils.IsClusterSetup(&dconf.Credentials) {
		timer := test_utils.Time("")
		timer.EndWithFatalError("cannot access cluster with credentials", t)
	}

	oldCreds := dconf.Credentials
	dconf.Credentials.Username = "admin"
	dconf.Credentials.Password = "123456"

	timer := test_utils.Time("updating credentials manually (required)...")
	if _, err := utils.Command("sh", "-c", fmt.Sprintf(
		"%s setting-cluster -c 127.0.0.1 --username \"%s\" --password \"%s\" --cluster-username \"%s\" --cluster-password \"%s\"",
		os.Getenv("COUCHBASE_CLI_PATH"),
		oldCreds.Username, oldCreds.Password,
		dconf.Credentials.Username, dconf.Credentials.Password,
	)); err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot update credentials : %s", err.Error()), t)
	} else {
		timer.End("updated credentials successfully")
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "credentials are updated")
	if !utils.IsClusterSetup(&dconf.Credentials) {
		timer := test_utils.Time("")
		timer.EndWithFatalError("cannot access cluster with updated credentials", t)
	}
}
