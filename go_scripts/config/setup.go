package config

import (
	"github.com/a-novel/errors"
)

func (c *Config) Setup() *errors.Error {
	if err := c.SetupCluster(); err != nil {
		return err
	}

	if err := c.CleanIndexes(); err != nil {
		return err
	}

	if err := c.SetupBuckets(); err != nil {
		return err
	}

	return nil
}
