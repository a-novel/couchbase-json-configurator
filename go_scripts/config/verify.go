package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"os"
)

func (c *Config) Verify() *errors.Error {
	if err := c.Parameters.Verify(); err != nil {
		return err
	}
	if err := c.Credentials.Verify(); err != nil {
		return err
	}
	if err := c.Resources.Verify(); err != nil {
		return err
	}
	if err := c.Compaction.Verify(); err != nil {
		return err
	}
	if err := c.VerifyBuckets(); err != nil {
		return err
	}

	if bucketsSize := c.ComputeBucketsRamSize(); bucketsSize > c.Resources.RamSize {
		return errors.New(
			ErrBucketResourcesOverflow,
			fmt.Sprintf(
				"total bucket ramSize %v Mb exceed the reserved amount in configuration (%v Mb)",
				bucketsSize,
				c.Resources.RamSize,
			),
		)
	}

	env := os.Getenv("ENV")
	if err := c.CheckBucketsConflicts(env == utils.EnvProduction || env == utils.EnvStaging); err != nil {
		return err
	}

	return nil
}
