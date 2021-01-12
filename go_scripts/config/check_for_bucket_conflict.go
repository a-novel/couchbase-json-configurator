package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
)

func (c *Config) CheckForBucketConflict(cBucket gocb.BucketSettings, prod bool) (bool, *errors.Error) {
	var found *bucket.Bucket

	for bucketName, bucketData := range c.Buckets {
		if bucketName == cBucket.Name {
			found = bucketData
			break
		}
	}

	if found == nil {
		if prod {
			return false, errors.New(
				ErrCannotAutoRemoveBucketsInSafeMode,
				fmt.Sprintf(
					"cannot auto-remove bucket %s in safe mode : please do it manually from UI before updating your "+
						"cluster",
					cBucket.Name,
				),
			)
		} else {
			return true, nil
		}
	}

	if gocb.BucketType(found.Type) != cBucket.BucketType {
		if prod {
			return false, errors.New(
				ErrCannotChangeBucketTypeInSafeMode,
				fmt.Sprintf("cannot change type for bucket %s in safe mode", cBucket.Name),
			)
		} else {
			return true, nil
		}
	}

	if found.Type == bucket.EphemeralBucket && gocb.EvictionPolicyType(found.EvictionPolicy) != cBucket.EvictionPolicy {
		if prod {
			return false, errors.New(
				ErrCannotChangeEphemeralBucketEvictionPolicyInSafeMode,
				fmt.Sprintf("cannot change evictionPolicy for ephemeral bucket %s in safe mode", cBucket.Name),
			)
		} else {
			return true, nil
		}
	}

	stats, err := c.GetBucketStats(cBucket.Name)
	if err != nil {
		return false, err
	}

	if stats.BasicStats.MemUsed >= utils.ToBytes(found.RamSize) {
		return false, errors.New(
			ErrResizingWithNotEnoughCapacity,
			fmt.Sprintf(
				"data in bucket %s is actually using %v Mb of memory, while new configuration only allocates %v Mb (overflow)",
				cBucket.Name, stats.BasicStats.MemUsed/1048576, found.RamSize,
			),
		)
	}

	return false, nil
}
