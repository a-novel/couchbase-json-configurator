package index

import (
	"github.com/a-novel/divanDocker/utils"
	"github.com/couchbase/gocb/v2"
)

func (i *Index) Equal(j *gocb.QueryIndex) bool {
	return i.Condition == j.Condition &&
		utils.StrSliceEqual(i.IndexKey, j.IndexKey) &&
		i.KeyspaceID == j.Keyspace
}
