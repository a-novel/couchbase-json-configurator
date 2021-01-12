package update_tests

import (
	"fmt"
	"github.com/a-novel/divan-data-manager"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"testing"
)

func CheckClusterResources(t *testing.T, dconf config.Config, message string) {
	timer := test_utils.Time(fmt.Sprintf("checking allocated resources when %s", message))
	timer.Important = true
	clusterData, err := divan_data_manager.GetClusterData(dconf.Credentials.Username, dconf.Credentials.Password, "")
	if err != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot fetch cluster data : %s", err.Error()), t)
	} else if clusterData.MemoryQuota != dconf.Resources.RamSize {
		timer.EndWithFatalError(fmt.Sprintf(
			"wrong ramSize returned when %s : got %v instead of %v",
			message, clusterData.MemoryQuota, dconf.Resources.RamSize,
		), t)
	} else if clusterData.FtsMemoryQuota != dconf.Resources.FtsRamSize {
		timer.EndWithFatalError(fmt.Sprintf(
			"wrong ramSize returned when %s : got %v instead of %v",
			message, clusterData.FtsMemoryQuota, dconf.Resources.FtsRamSize,
		), t)
	} else if clusterData.IndexMemoryQuota != dconf.Resources.IndexRamSize {
		timer.EndWithFatalError(fmt.Sprintf(
			"wrong ramSize returned when %s : got %v instead of %v",
			message, clusterData.IndexMemoryQuota, dconf.Resources.IndexRamSize,
		), t)
	} else {
		timer.End("quota setup successfully")
	}
}

func TestResourcesUpdate(t *testing.T) {
	test_utils.Clean(t)
	test_utils.Launch(t)
	defer test_utils.Clean(t)

	dconf := config.Config{
		Resources: resources.Resources{
			RamSize:      1024,
			FtsRamSize:   256,
			IndexRamSize: 256,
		},
		Credentials: credentials.Credentials{
			Username: "Administrator",
			Password: "password",
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(false, "resources are setup")
	CheckClusterResources(t, dconf, "setting resources first time")

	dconf.Resources = resources.Resources{
		RamSize:      2048,
		FtsRamSize:   512,
		IndexRamSize: 512,
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "resources are updated")
	CheckClusterResources(t, dconf, "updating resources")

	dconf.Resources = resources.Resources{
		FtsRamSize:   512,
		IndexRamSize: 512,
	}

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 512,
		},
		"bucket_2": {
			RamSize: 512,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "ramSize is updated with automatic allocation")

	// The value ramSize should have been set to.
	dconf.Resources.RamSize = 1024
	CheckClusterResources(t, dconf, "ramSize is updated with automatic allocation")
}
