package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
	"time"
)

func (c *Config) Cluster() (*gocb.Cluster, *errors.Error) {
	if c.cluster == nil {
		if ok := utils.WaitForBackend(c.Parameters.Timeout); !ok {
			return nil, errors.New(ErrCannotReachCluster, "unable to reach server (timeout)")
		}

		cluster, err := gocb.Connect(
			"localhost",
			gocb.ClusterOptions{
				Username: c.Credentials.Username,
				Password: c.Credentials.Password,
				TimeoutsConfig: gocb.TimeoutsConfig{
					ConnectTimeout:   time.Duration(c.Parameters.Timeout) * time.Second,
					KVDurableTimeout: time.Duration(c.Parameters.Timeout) * time.Second,
					KVTimeout:        time.Duration(c.Parameters.Timeout) * time.Second,
					QueryTimeout:     time.Duration(c.Parameters.Timeout) * time.Second,
					SearchTimeout:    time.Duration(c.Parameters.Timeout) * time.Second,
				},
			},
		)

		if err != nil {
			return nil, errors.New(
				ErrCannotConnectToCluster,
				fmt.Sprintf("unable to connect to cluster : %s", err.Error()),
			)
		}

		if err := cluster.WaitUntilReady(
			time.Duration(c.Parameters.Timeout)*time.Second,
			&gocb.WaitUntilReadyOptions{
				DesiredState: gocb.ClusterStateOnline,
				ServiceTypes: []gocb.ServiceType{
					gocb.ServiceTypeQuery,
					gocb.ServiceTypeManagement,
					gocb.ServiceTypeSearch,
				},
			},
		); err != nil {
			return nil, errors.New(
				ErrCannotReachCluster,
				fmt.Sprintf("unable to reach cluster (timeout) : %s", err.Error()),
			)
		}

		c.cluster = cluster
	}

	return c.cluster, nil
}
