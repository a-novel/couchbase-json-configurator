package index

import (
	"fmt"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
)

func (i *Index) Create(name, bucketName string, cluster *gocb.Cluster) *errors.Error {
	if err := cluster.QueryIndexes().CreateIndex(bucketName, name, i.IndexKey, nil); err != nil {
		return errors.New(ErrCannotCreateSecondaryIndex, fmt.Sprintf(
			"cannot create secondary index %s on bucket %s : %s",
			name, bucketName, err.Error(),
		))
	}

	return nil
}

func (i *Index) CreatePrimary(name, bucketName string, cluster *gocb.Cluster) *errors.Error {
	if err := cluster.QueryIndexes().CreatePrimaryIndex(bucketName, &gocb.CreatePrimaryQueryIndexOptions{
		CustomName: name,
	}); err != nil {
		return errors.New(ErrCannotCreatePrimaryIndex, fmt.Sprintf(
			"cannot create primary index %s on bucket %s : %s",
			name, bucketName, err.Error(),
		))
	}

	return nil
}
