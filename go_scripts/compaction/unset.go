package compaction

import (
	"fmt"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
)

func (c *Compaction) Unset(url string, credentials credentials.Credentials) *errors.Error {
	if _, err := utils.Command(
		"sh", "-c",
		fmt.Sprintf(
			"curl -sX POST -u '%s':'%s' '%s' -d \"autoCompactionDefined=false\" -d \"parallelDBAndViewCompaction=false\"",
			credentials.Username,
			credentials.Password,
			url,
		),
	); err != nil {
		return errors.New(
			ErrCannotUnsetCompaction,
			err.Error(),
		)
	}

	return nil
}
