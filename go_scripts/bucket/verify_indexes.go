package bucket

import (
	"fmt"
	"github.com/a-novel/divanDocker/index"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
	"regexp"
)

func (b *Bucket) VerifyIndexes(name string, cluster *gocb.Cluster) *errors.Error {
	if b.PrimaryIndex != "" {
		if err := checkIndexName(b.PrimaryIndex, name); err != nil {
			return err
		}
	}

	var indexes []gocb.QueryIndex
	var err error

	if cluster != nil {
		indexes, err = cluster.QueryIndexes().GetAllIndexes(name, nil)
		if err != nil {
			return errors.New(
				ErrCannotFetchIndexesInformation,
				fmt.Sprintf("unable to fetch indexes information on checkup : %s", err.Error()),
			)
		}
	}

	if indexes != nil {
		if output := index.FindIndex(b.PrimaryIndex, indexes); output != nil {
			b.doPrimaryIndexExit = true
		}
	}

	if b.Indexes != nil && len(b.Indexes) > 0 {
		if b.PrimaryIndex == "" {
			return errors.New(
				ErrCannotSetSecondaryIndexesWithoutPrimaryIndex,
				"cannot set secondary indexes if no primary index is set",
			)
		}

		for indexName, indexData := range b.Indexes {
			if indexData == nil {
				indexData = &index.Index{}
			}

			indexData.KeyspaceID = name

			if err := checkIndexName(indexName, name); err != nil {
				return err
			}

			if indexes == nil {
				continue
			}

			if output := index.FindIndex(indexName, indexes); output != nil {
				if !indexData.Equal(output) {
					indexData.SetSkip()
				} else {
					indexData.SetRecreate()
				}
			}
		}
	}

	return nil
}

func checkIndexName(name, bucketName string) *errors.Error {
	isIndexNameValid := regexp.MustCompile("^[0-9A-Za-z#\\-_)]+$").MatchString
	isIndexNamePrefixValid := regexp.MustCompile("^[A-Za-z)].*").MatchString

	if !isIndexNameValid(name) {
		return errors.New(
			ErrNonValidIndexName,
			fmt.Sprintf(
				"non valid index name %s in bucket %s : only alphanumeric characters are allowed, plus `#`, `-` and `_`",
				name, bucketName,
			),
		)
	}

	if !isIndexNamePrefixValid(name) {
		return errors.New(
			ErrNonValidIndexName,
			fmt.Sprintf(
				"non valid index name %s in bucket %s : name must start with an alphabet character",
				name, bucketName,
			),
		)
	}

	return nil
}
