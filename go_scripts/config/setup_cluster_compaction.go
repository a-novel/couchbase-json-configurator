package config

import (
	"fmt"
	"github.com/a-novel/errors"
)

func (c *Config) SetupClusterCompaction() *errors.Error {
	clusterUrl := "http://127.0.0.1:8091/controller/setAutoCompaction"

	if c.Compaction.IsCompactionSet() {
		if err := c.Compaction.Setup(clusterUrl, c.Resources.PurgeInterval, c.Credentials); err != nil {
			return errors.New(
				ErrCannotUpdateClusterCompaction,
				fmt.Sprintf("cannot set compaction settings for cluster : %s", err.Error()))
		}
	} else {
		if err := c.Compaction.Unset(clusterUrl, c.Credentials); err != nil {
			return errors.New(
				ErrCannotUpdateClusterCompaction,
				fmt.Sprintf("cannot unset compaction settings for cluster : %s", err.Error()))
		}
	}

	return nil
}
