package divanDocker

import (
	"context"
	"github.com/a-novel/errors"
	"github.com/docker/docker/client"
)

const (
	Version = "1.0.0"
)

var cli *client.Client
var ctx context.Context
var err error
var inited bool

func Init() *errors.Error {
	if inited {
		return nil
	}

	// Use context to run Docker container.
	ctx = context.Background()

	// Launch docker client for Go.
	cli, err = client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return errors.New(ErrCannotRunDocker, err.Error())
	}

	inited = true
	return nil
}
