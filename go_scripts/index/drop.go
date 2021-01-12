package index

import (
	"fmt"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
)

func (i *Index) Drop(name, bucketName string, cluster *gocb.Cluster) *errors.Error {
	if err := cluster.QueryIndexes().DropIndex(bucketName, name, nil); err != nil {
		return errors.New(ErrCannotDropSecondaryIndex, fmt.Sprintf(
			"cannot drop secondary index %s on bucket %s : %s",
			name, bucketName, err.Error(),
		))
	}

	return nil
}

func (i *Index) DropPrimary(name, bucketName string, cluster *gocb.Cluster) *errors.Error {
	if err := cluster.QueryIndexes().DropPrimaryIndex(bucketName, &gocb.DropPrimaryQueryIndexOptions{
		CustomName: name,
	}); err != nil {
		return errors.New(ErrCannotDropPrimaryIndex, fmt.Sprintf(
			"cannot drop primary index %s on bucket %s : %s",
			name, bucketName, err.Error(),
		))
	}

	return nil
}
