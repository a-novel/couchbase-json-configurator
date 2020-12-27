package divanDocker

import (
	"fmt"
	"github.com/a-novel/errors"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/mount"
	"io"
	"os"
)

type ContainerOptions struct {
	Name                   string `json:"name"`
	Version                string `json:"version"`
	DisableDataConsistency bool   `json:"ephemeral"`
	VolumeName             string `json:"volume_name"`
}

func Create(configPath string, options *ContainerOptions) (string, *errors.Error) {
	if err := Init(); err != nil {
		return "", err
	}

	if options == nil {
		options = &ContainerOptions{}
	}

	// Use latest image version available.
	if options.Version == "" {
		options.Version = Version
	}

	if options.VolumeName == "" {
		options.VolumeName = "db"
	}

	image := fmt.Sprintf("kushuh/divan:%s", options.Version)

	// Pull container image.
	out, err := cli.ImagePull(ctx, image, types.ImagePullOptions{})
	if err != nil {
		return "", errors.New(ErrCannotPullImage, err.Error())
	}
	_, err = io.Copy(os.Stdout, out)
	if err != nil {
		// Do not fail for this situation, since it is only a convenience error and might depend on a faulty user
		// environment.
		fmt.Printf("cannot print docker logs : %s", err.Error())
	}

	ports, err2 := PortMapper("8091-8096:8091-8096", "11210-11211:11210-11211")
	if err2 != nil {
		return "", err2
	}

	volumes := []mount.Mount{
		{
			Type:   mount.TypeBind,
			Source: configPath,
			Target: "/root/DIVAN-config",
		},
	}

	if !options.DisableDataConsistency {
		volumes = append(volumes, mount.Mount{
			Type:   mount.TypeVolume,
			Source: options.VolumeName,
			Target: "/opt/couchbase/var",
		})
	}

	// Create container.
	resp, err := cli.ContainerCreate(ctx, &container.Config{
		Image: image,
	}, &container.HostConfig{
		PortBindings: ports,
		Mounts:       volumes,
	}, nil, nil, options.Name)
	if err != nil {
		return "", errors.New(ErrCannotRunDocker, err.Error())
	}

	// Launch container.
	if err := cli.ContainerStart(ctx, resp.ID, types.ContainerStartOptions{}); err != nil {
		return "", errors.New(ErrCannotRunDocker, err.Error())
	}

	return resp.ID, nil
}
