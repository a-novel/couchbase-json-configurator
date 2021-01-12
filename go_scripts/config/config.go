package config

import (
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/compaction"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/parameters"
	"github.com/a-novel/divanDocker/resources"
	"github.com/couchbase/gocb/v2"
)

type Config struct {
	Parameters  parameters.Parameters     `json:"parameters"`
	Credentials credentials.Credentials   `json:"credentials"`
	Resources   resources.Resources       `json:"resources"`
	Compaction  compaction.Compaction     `json:"compaction"`
	Buckets     map[string]*bucket.Bucket `json:"buckets"`

	cluster *gocb.Cluster
}
