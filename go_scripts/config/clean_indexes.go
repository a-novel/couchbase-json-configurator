package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/index"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
	"time"
)

func (c *Config) CleanIndexes() *errors.Error {
	cluster, err := c.Cluster()
	if err != nil {
		return err
	}

	var indexes []*index.BackendData

	var err2 error
	var res *gocb.QueryResult

	timer := time.Now().Second()
	for (time.Now().Second() - timer) < c.Parameters.Timeout {
		res, err2 = cluster.Query("SELECT `indexes`.* FROM system:indexes", &gocb.QueryOptions{
			Readonly: true,
			Adhoc:    false,
			Timeout:  time.Duration(c.Parameters.Timeout) * time.Second,
		})

		if err2 == nil {
			break
		}
	}

	if err2 != nil {
		return errors.New(
			bucket.ErrCannotFetchIndexesInformation,
			fmt.Sprintf("unable to fetch indexes information on cleaning (timeout) : %s", err2.Error()),
		)
	}

	for res.Next() {
		var output index.BackendData
		if err := res.Row(&output); err != nil {
			return errors.New(
				bucket.ErrCannotParseIndexesInformation,
				fmt.Sprintf("unable to parse indexes information : %s", err.Error()),
			)
		}

		indexes = append(indexes, &output)
	}

	id := index.Index{}
	for _, indexData := range indexes {
		found := false

		if c.Buckets != nil {
			if bucketData, ok := c.Buckets[indexData.KeyspaceID]; ok {
				if bucketData.PrimaryIndex == indexData.Name {
					found = true
					break
				}

				foundSub := false

				if bucketData.Indexes != nil {
					for indexName, _ := range bucketData.Indexes {
						if indexName == indexData.Name {
							foundSub = true
							break
						}
					}
				}

				if foundSub {
					found = true
				}
			}
		}

		if !found {
			dropFn := id.Drop
			if indexData.IsPrimary {
				dropFn = id.DropPrimary
			}

			if err := dropFn(indexData.Name, indexData.KeyspaceID, cluster); err != nil {
				return err
			}
		}
	}

	return nil
}
