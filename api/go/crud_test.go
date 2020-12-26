package divanDocker

import (
	"fmt"
	"github.com/docker/docker/api/types"
	"path"
	"runtime"
	"testing"
)

func kill (id string) error {
	if err := cli.ContainerKill(ctx, id, ""); err != nil {
		return fmt.Errorf("unable to kill container : %s", err.Error())
	}

	if err := cli.ContainerRemove(ctx, id, types.ContainerRemoveOptions{}); err != nil {
		return fmt.Errorf("unable to kill container : %s", err.Error())
	}

	return nil
}

func TestCreate(t *testing.T) {
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatalf("unable to get caller path")
	}

	config := path.Join(path.Dir(filename), "test_files")

	id, err := Create("", nil)
	if err == nil {
		if err := kill(id); err != nil {
			t.Fatalf(err.Error())
		}

		t.Fatalf("container is created despite empty config path")
	}

	id, err = Create(config, nil)
	if err != nil {
		t.Fatalf("unable to create container : %s", err.Error())
	}

	if err := kill(id); err != nil {
		t.Fatalf(err.Error())
	}
}
