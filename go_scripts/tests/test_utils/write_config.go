package test_utils

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"testing"
)

func WriteConfig(config interface{}) error {
	configPath := path.Join(os.Getenv("DIVAN_SCRIPTS"), "config.json")
	if err := os.Setenv("DIVAN_CONFIG", configPath); err != nil {
		return err
	}

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		if err := os.MkdirAll(filepath.Dir(configPath), 0770); err != nil {
			return err
		}

		// File doesn't exist, so we create it
		_, err := os.Create(configPath)
		if err != nil {
			return err
		}
	}

	cb, err := json.Marshal(config)
	if err != nil {
		return err
	}

	if err := ioutil.WriteFile(configPath, cb, 0755); err != nil {
		return err
	}

	return nil
}

func WriteConfigAuto(config interface{}, t *testing.T) {
	timer := Time("writing config data...")
	if err := WriteConfig(config); err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot write config file : %s", err.Error()), t)
	} else {
		timer.End("wrote config data successfully")
	}
}

func DeleteConfigAuto(t *testing.T) {
	timer := Time("removing config data...")

	configPath := path.Join(os.Getenv("DIVAN_SCRIPTS"), "config.json")
	if err := os.Setenv("DIVAN_CONFIG", configPath); err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot get config path : %s", err.Error()), t)
	}

	if err := os.Remove(configPath); err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot remove config file : %s", err.Error()), t)
	} else {
		timer.End("deleted config data successfully")
	}
}
