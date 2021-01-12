package check_tests

import (
	"fmt"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"strings"
	"testing"
)

func TestWithMissingCredentials(t *testing.T) {
	dconf := config.Config{Resources: resources.Resources{
		RamSize:      1024,
		FtsRamSize:   256,
		IndexRamSize: 256,
	}}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldFailWith(true, credentials.ErrNoUsernameFound, "credentials are missing")

	dconf.Credentials.Username = "Administrator"
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, credentials.ErrNoPasswordFound, "admin password is missing")

	dconf.Credentials.Username = ""
	dconf.Credentials.Password = "password"
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, credentials.ErrNoUsernameFound, "admin username is missing")
}

func TestWithNonValidCredentials(t *testing.T) {
	dconf := config.Config{
		Resources: resources.Resources{
			RamSize:      1024,
			FtsRamSize:   256,
			IndexRamSize: 256,
		},
		Credentials: credentials.Credentials{
			Username: strings.Repeat("a", 129),
			Password: "password",
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldFailWith(true, credentials.ErrUsernameTooLong, "admin username is too long")

	dconf.Credentials.Username = "@dministrator"
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, credentials.ErrUsernameForbiddenPrefix, "admin username starts with character '@'")

	dconf.Credentials.Username = "Administrator"
	dconf.Credentials.Password = "passw"
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, credentials.ErrPasswordTooShort, "admin password is too short")

	dconf.Credentials.Password = "password"
	for _, chr := range strings.Split("()<>,;:\\\"/[]?={}", "") {
		dconf.Credentials.Username = "Administrator" + chr
		test_utils.WriteConfigAuto(dconf, t)
		test_utils.ShouldFailWith(
			true,
			credentials.ErrUsernameForbiddenCharacter,
			fmt.Sprintf("admin username contains forbidden character '%s'", chr),
		)
	}
}

func TestWithValidCredentials(t *testing.T) {
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
	test_utils.ShouldPass(true, "credentials are valid")

	dconf.Credentials.Username = "Administr@tor"
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(true, "admin username contains character '@' after position 0")
}
