package index

import "github.com/couchbase/gocb/v2"

func FindIndex(name string, indexes []gocb.QueryIndex) *gocb.QueryIndex {
	for _, index := range indexes {
		if index.Name == name {
			return &index
		}
	}

	return nil
}
