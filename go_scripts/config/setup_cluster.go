package config

import (
	"fmt"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"os"
	"strconv"
)

func (c *Config) SetupCluster() *errors.Error {
	mode := "setting-cluster"
	username := "--username"
	password := "--password"
	suffix := ""

	if ok := utils.IsClusterSetup(&c.Credentials); !ok {
		mode = "cluster-init"
		username = "--cluster-username"
		password = "--cluster-password"
		suffix = "--services data,query,index,fts"
	}

	if _, err := utils.Command(
		"sh", "-c",
		fmt.Sprintf(
			"%s %s -c 127.0.0.1 %s \"%s\" %s \"%s\" --cluster-ramsize %s --cluster-fts-ramsize %s --cluster-index-ramsize %s %s",
			os.Getenv("COUCHBASE_CLI_PATH"),
			mode,
			username, c.Credentials.Username,
			password, c.Credentials.Password,
			strconv.FormatUint(c.Resources.RamSize, 10),
			strconv.FormatUint(c.Resources.FtsRamSize, 10),
			strconv.FormatUint(c.Resources.IndexRamSize, 10),
			suffix,
		),
	); err != nil {
		return errors.New(ErrCannotSetupCluster, fmt.Sprintf("cannot setup cluster : %s", err.Error()))
	}

	if err := c.SetupClusterCompaction(); err != nil {
		return err
	}

	return nil
}
