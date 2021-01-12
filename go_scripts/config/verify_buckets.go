package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
	"regexp"
)

func (c *Config) VerifyBuckets() *errors.Error {
	isBucketNameValid := regexp.MustCompile("^[0-9A-Za-z_.%-]+$").MatchString

	if c.Buckets != nil {
		for bucketName, bucketData := range c.Buckets {
			if bucketData == nil {
				bucketData = &bucket.Bucket{}
			}

			if len(bucketName) == 0 {
				return errors.New(
					ErrEmptyBucketName,
					"bucketData has empty name",
				)
			}

			if len(bucketName) > 100 {
				return errors.New(
					ErrBucketNameTooLong,
					"bucketData name cannot be longer than 100 characters",
				)
			}

			if !isBucketNameValid(bucketName) {
				return errors.New(
					ErrNonValidBucketName,
					fmt.Sprintf(
						"non valid bucketData name %s : only alphanumeric characters are allowed, plus `_`, `.`, `%%` and `-`",
						bucketName,
					),
				)
			}

			var cluster *gocb.Cluster
			var err *errors.Error

			if utils.IsClusterSetup(&c.Credentials) {
				cluster, err = c.Cluster()
				if err != nil {
					return err
				}
			}

			if err := bucketData.Verify(bucketName, cluster); err != nil {
				return err
			}
		}
	}

	return nil
}
