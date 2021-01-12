package test_utils

import (
	"fmt"
	"github.com/a-novel/divanDocker/config"
	"github.com/couchbase/gocb/v2"
	"testing"
)

func GetCluster(t *testing.T, dconf *config.Config) *gocb.Cluster {
	timer := Timer{Message: "getting cluster object"}
	cluster, err := dconf.Cluster()
	if err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot get cluster : %s", err.Error()), t)
	}
	timer.End("got cluster object")

	return cluster
}
