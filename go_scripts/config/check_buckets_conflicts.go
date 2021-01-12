package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
)

func (c *Config) CheckBucketsConflicts(prod bool) *errors.Error {
	if ok := utils.IsClusterSetup(&c.Credentials); ok {
		cluster, err := c.Cluster()
		if err != nil {
			return err
		}

		currentBuckets, err2 := cluster.Buckets().GetAllBuckets(nil)
		if err2 != nil {
			return errors.New(ErrCannotReadBuckets, fmt.Sprintf("cannot read buckets for checking : %s", err.Error()))
		}

		for _, cBucket := range currentBuckets {
			rm, err := c.CheckForBucketConflict(cBucket, prod)

			if err != nil {
				return err
			}

			if rm {
				if err := cluster.Buckets().DropBucket(cBucket.Name, nil); err != nil {
					return errors.New(
						ErrCannotDeleteBucket,
						fmt.Sprintf("cannot delete bucket %s : %s", cBucket.Name, err.Error()),
					)
				}
			}
		}
	}

	return nil
}
