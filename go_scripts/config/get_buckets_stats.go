package config

import (
	"fmt"
	"github.com/a-novel/divan-data-manager"
	"github.com/a-novel/divan-data-manager/types"
	"github.com/a-novel/errors"
)

func (c *Config) GetBucketStats(name string) (*divan_types.BucketData, *errors.Error) {
	buckets, err := divan_data_manager.GetBucketsData(c.Credentials.Username, c.Credentials.Password, "")
	if err != nil {
		return nil, errors.New(
			ErrCannotFetchBucketsInformation,
			fmt.Sprintf("unable to fetch buckets information : %s", err.Error()),
		)
	}

	if bucket := divan_data_manager.FindBucket(name, buckets); bucket != nil {
		return bucket, nil
	}

	return nil, errors.New(ErrCannotFindBucketStats, fmt.Sprintf("cannot find bucket information for bucket %s", name))
}
