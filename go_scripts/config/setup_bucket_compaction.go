package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/errors"
)

func SetupBucketCompaction(
	bucketName string,
	bucketData *bucket.Bucket,
	credentials credentials.Credentials,
) *errors.Error {
	bucketUrl := fmt.Sprintf("http://127.0.0.1:8091/pools/default/buckets/%s", bucketName)

	if bucketData.Compaction != nil && bucketData.Compaction.IsCompactionSet() {
		if err := bucketData.Compaction.Setup(bucketUrl, bucketData.PurgeInterval, credentials); err != nil {
			return errors.New(
				ErrCannotUpdateBucketCompaction,
				fmt.Sprintf("cannot set compaction settings for bucket %s : %s", bucketName, err.Error()))
		}
	} else {
		if err := bucketData.Compaction.Unset(bucketUrl, credentials); err != nil {
			return errors.New(
				ErrCannotUpdateBucketCompaction,
				fmt.Sprintf("cannot unset compaction settings for bucket %s : %s", bucketName, err.Error()))
		}
	}

	return nil
}
