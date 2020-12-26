package divanDocker

import (
	"github.com/a-novel/errors"
	"github.com/docker/go-connections/nat"
)

func PortMapper(portsRanges ...string) (nat.PortMap, *errors.Error) {
	portBindings := nat.PortMap{}

	for _, rawMapping := range portsRanges {
		mappings, err := nat.ParsePortSpec(rawMapping)
		if err != nil {
			return nil, errors.New(ErrCannotCreatePortMap, err.Error())
		}

		for _, pm := range mappings {
			portBindings[pm.Port] = []nat.PortBinding{pm.Binding}
		}

	}

	return portBindings, nil
}
