package start_script

import (
	"encoding/json"
	"fmt"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"io/ioutil"
	"os"
)

func Start(cancelSetup bool) *errors.Error {
	cliPath, err2 := utils.SetCLIPath()
	if err2 != nil {
		return err2
	}

	err := os.Setenv("COUCHBASE_CLI_PATH", cliPath)
	if err != nil {
		return errors.New("unknown", err.Error())
	}

	configPath := os.Getenv("DIVAN_CONFIG")
	var configData config.Config

	file, err := ioutil.ReadFile(configPath)
	if err != nil {
		return errors.New("unknown", fmt.Sprintf("cannot read config file : %s", err.Error()))
	}

	if err = json.Unmarshal(file, &configData); err != nil {
		return errors.New("unknown", err.Error())
	}

	if err := configData.Parameters.Verify(); err != nil {
		return err
	}

	if !cancelSetup {
		// Wait no more than 30 seconds for the backend to be ready.
		ok := utils.WaitForBackend(configData.Parameters.Timeout)
		if !ok {
			return errors.New("unknown", "cannot reach couchbase cluster (timeout)")
		}
	}

	configData.AutoSetResources()

	if err := configData.Verify(); err != nil {
		return err
	}

	if cancelSetup {
		return nil
	}

	if err := configData.Setup(); err != nil {
		return err
	}

	return nil
}
