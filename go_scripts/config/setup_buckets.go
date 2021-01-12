package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/index"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
	"os"
	"time"
)

func (c *Config) SetupBuckets() *errors.Error {
	cluster, err2 := c.Cluster()
	if err2 != nil {
		return err2
	}

	current, err := cluster.Buckets().GetAllBuckets(nil)
	if err != nil {
		return errors.New(ErrCannotReadBuckets, fmt.Sprintf("cannot read buckets : %s", err.Error()))
	}

	for bucketName, bucketData := range c.Buckets {
		if err := c.SetupBucket(current, bucketName, bucketData); err != nil {
			return err
		}
	}

	return nil
}

func (c *Config) SetupBucket(
	current map[string]gocb.BucketSettings,
	bucketName string,
	bucketData *bucket.Bucket,
) *errors.Error {
	cluster, err := c.Cluster()
	if err != nil {
		return err
	}

	if _, ok := current[bucketName]; ok {
		if err := c.UpdateBucket(cluster, bucketName, bucketData); err != nil {
			return err
		}
	} else {
		if err := c.CreateBucket(cluster, bucketName, bucketData); err != nil {
			return err
		}
	}

	if bucketData.Type == bucket.CouchbaseBucket {
		if err := SetupBucketCompaction(bucketName, bucketData, c.Credentials); err != nil {
			return err
		}
	}

	if _, err := utils.Command(
		"sh", "-c",
		fmt.Sprintf(
			"%s bucket-edit -c 127.0.0.1 --username \"%s\" --password \"%s\" --bucket \"%s\" --bucket-priority %s",
			os.Getenv("COUCHBASE_CLI_PATH"),
			c.Credentials.Username,
			c.Credentials.Password,
			bucketName,
			bucketData.Priority,
		),
	); err != nil {
		return errors.New(
			ErrCannotUpdateBucketPriority,
			fmt.Sprintf("cannot set priority for bucket %s : %s", bucketName, err.Error()))
	}

	if err := cluster.Bucket(bucketName).WaitUntilReady(
		time.Duration(c.Parameters.Timeout)*time.Second,
		&gocb.WaitUntilReadyOptions{
			ServiceTypes: []gocb.ServiceType{
				gocb.ServiceTypeKeyValue,
				gocb.ServiceTypeQuery,
				gocb.ServiceTypeSearch,
				gocb.ServiceTypeManagement,
			},
		},
	); err != nil {
		return errors.New(
			ErrCannotReachBucket,
			fmt.Sprintf("cannot reach bucket %s : %s", bucketName, err.Error()),
		)
	}

	if bucketData.PrimaryIndex != "" && !bucketData.DoPrimaryIndexExist() {
		id := index.Index{}
		if err := id.CreatePrimary(bucketData.PrimaryIndex, bucketName, cluster); err != nil {
			return err
		}
	}

	if bucketData.Indexes != nil {
		for indexName, indexData := range bucketData.Indexes {
			if indexData.Skipped() {
				continue
			}

			if indexData.Recreated() {
				if err := indexData.Drop(indexName, bucketName, cluster); err != nil {
					return err
				}
			}

			if err := indexData.Create(indexName, bucketName, cluster); err != nil {
				return err
			}
		}
	}

	return nil
}
