package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
)

func (c *Config) UpdateBucket(
	cluster *gocb.Cluster,
	bucketName string,
	bucketData *bucket.Bucket,
) *errors.Error {
	if err := cluster.Buckets().UpdateBucket(gocb.BucketSettings{
		Name:           bucketName,
		FlushEnabled:   bucketData.Flush,
		RAMQuotaMB:     bucketData.RamSize,
		BucketType:     gocb.BucketType(bucketData.Type),
		EvictionPolicy: gocb.EvictionPolicyType(bucketData.EvictionPolicy),
	}, nil); err != nil {
		return errors.New(
			ErrCannotUpdateBucketDefaults,
			fmt.Sprintf("cannot update default parameters for bucket %s : %s", bucketName, err.Error()),
		)
	}

	return nil
}
