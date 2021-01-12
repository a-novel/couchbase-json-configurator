package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
)

func (c *Config) CreateBucket(
	cluster *gocb.Cluster,
	bucketName string,
	bucketData *bucket.Bucket,
) *errors.Error {
	if err := cluster.Buckets().CreateBucket(gocb.CreateBucketSettings{
		BucketSettings: gocb.BucketSettings{
			Name:           bucketName,
			FlushEnabled:   bucketData.Flush,
			RAMQuotaMB:     bucketData.RamSize,
			BucketType:     gocb.BucketType(bucketData.Type),
			EvictionPolicy: gocb.EvictionPolicyType(bucketData.EvictionPolicy),
		},
	}, nil); err != nil {
		return errors.New(
			ErrCannotCreateBucketDefaults,
			fmt.Sprintf("cannot create default parameters for bucket %s : %s", bucketName, err.Error()),
		)
	}

	return nil
}
