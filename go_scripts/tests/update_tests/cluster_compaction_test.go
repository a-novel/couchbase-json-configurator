package update_tests

import (
	"fmt"
	"github.com/a-novel/divan-data-manager"
	"github.com/a-novel/divanDocker/compaction"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/a-novel/divanDocker/utils"
	"testing"
)

func verifyClusterCompaction(dconf *config.Config) {
	timer := test_utils.Time("checking compaction on server")
	currentSettings, err := divan_data_manager.GetClusterData(
		dconf.Credentials.Username,
		dconf.Credentials.Password,
		"",
	)

	if err != nil {
		timer.EndWithError(fmt.Sprintf("cannot retrieve cluster data : %s", err.Error()))
		return
	}

	if err := currentSettings.GetAutocompaction(); err != nil {
		timer.EndWithError(fmt.Sprintf("cannot retrieve cluster autocompaction data : %s", err.Error()))
		return
	}

	if err := test_utils.VerifyCompaction(&dconf.Compaction, currentSettings.AutoCompactionSettingsD); err != nil {
		timer.EndWithError(fmt.Sprintf("unexpected autocompaction config on server : %s", err.Error()))
		return
	}

	timer.End("compaction checked")
}

func TestClusterCompactionUpdate(t *testing.T) {
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
	test_utils.ShouldPass(false, "cluster is setup with no compaction")
	verifyClusterCompaction(&dconf)

	dconf.Compaction = compaction.Compaction{
		ParallelCompaction: true,
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "compaction is updated with only parallel compaction")
	verifyClusterCompaction(&dconf)

	dconf.Compaction = compaction.Compaction{
		ParallelCompaction: false,
		Threshold: utils.Threshold{
			Size:       100,
			Percentage: 10,
		},
		ViewThreshold: utils.Threshold{
			Size:       100,
			Percentage: 10,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "compaction is updated with thresholds")
	verifyClusterCompaction(&dconf)

	dconf.Compaction = compaction.Compaction{
		ParallelCompaction: false,
		Threshold: utils.Threshold{
			Percentage: 50,
		},
		ViewThreshold: utils.Threshold{
			Size:       256,
			Percentage: 15,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "compaction thresholds are updated")
	verifyClusterCompaction(&dconf)

	dconf.Compaction = compaction.Compaction{
		ParallelCompaction: false,
		Threshold: utils.Threshold{
			Percentage: 50,
		},
		ViewThreshold: utils.Threshold{
			Size:       256,
			Percentage: 15,
		},
		From: utils.Time{
			Hour: 2,
		},
		To: utils.Time{
			Hour:   6,
			Minute: 30,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "compaction is updated with timeframe")
	verifyClusterCompaction(&dconf)

	dconf.Compaction = compaction.Compaction{
		ParallelCompaction: false,
		Threshold: utils.Threshold{
			Percentage: 50,
		},
		ViewThreshold: utils.Threshold{
			Size:       256,
			Percentage: 15,
		},
		From: utils.Time{
			Hour: 2,
		},
		To: utils.Time{
			Hour:   6,
			Minute: 30,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "compaction timeframe is updated")
	verifyClusterCompaction(&dconf)

	dconf.Compaction = compaction.Compaction{
		ParallelCompaction: false,
		Threshold: utils.Threshold{
			Percentage: 50,
		},
		ViewThreshold: utils.Threshold{
			Size:       256,
			Percentage: 15,
		},
		From: utils.Time{
			Hour: 2,
		},
		To: utils.Time{
			Hour:   6,
			Minute: 30,
		},
		AbortOutside: true,
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "compaction is updated with abortOutside")
	verifyClusterCompaction(&dconf)

	dconf.Compaction = compaction.Compaction{}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "compaction is removed")
	verifyClusterCompaction(&dconf)
}
