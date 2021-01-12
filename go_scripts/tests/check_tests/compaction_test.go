package check_tests

import (
	"github.com/a-novel/divanDocker/compaction"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/a-novel/divanDocker/utils"
	"testing"
)

func TestWithNonValidCompaction(t *testing.T) {
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
		Compaction: compaction.Compaction{
			From: utils.Time{
				Hour: 2,
			},
			To: utils.Time{
				Hour: 6,
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldFailWith(true, compaction.ErrTimeFrameWithNoThreshold, "compaction timeframe is set with no compaction threshold")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 1,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, utils.ErrThresholdPercentageTooLow, "compaction threshold is set with percentage too low")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 101,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, utils.ErrThresholdPercentageTooHigh, "compaction threshold is set with percentage too high")

	dconf.Compaction = compaction.Compaction{
		ViewThreshold: utils.Threshold{
			Percentage: 1,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, compaction.ErrViewThresholdPercentageTooLow, "compaction view threshold is set with percentage too low")

	dconf.Compaction = compaction.Compaction{
		ViewThreshold: utils.Threshold{
			Percentage: 101,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, compaction.ErrViewThresholdPercentageTooHigh, "compaction view threshold is set with percentage too high")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 90,
		},
		From: utils.Time{
			Hour: 24,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, compaction.ErrFromHourTooHigh, "compaction timeframe from hour value is to high")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 90,
		},
		From: utils.Time{
			Minute: 60,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, compaction.ErrFromMinuteTooHigh, "compaction timeframe from minute value is to high")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 90,
		},
		To: utils.Time{
			Hour: 24,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, compaction.ErrToHourTooHigh, "compaction timeframe to hour value is to high")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 90,
		},
		To: utils.Time{
			Minute: 60,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, compaction.ErrToMinuteTooHigh, "compaction timeframe to minute value is to high")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 90,
		},
		AbortOutside: true,
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, compaction.ErrAbortOutsideOnEmptyFrame, "compaction abortOutside is set with no compaction timeframe")
}

func TestWithValidCompaction(t *testing.T) {
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
		Compaction: compaction.Compaction{
			ParallelCompaction: true,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(true, "compaction is set with parallelCompaction flag only")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 75,
			Size:       512,
		},
		ViewThreshold: utils.Threshold{
			Percentage: 75,
			Size:       512,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(true, "compaction is set with valid thresholds")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 75,
			Size:       512,
		},
		ViewThreshold: utils.Threshold{
			Percentage: 75,
			Size:       512,
		},
		From: utils.Time{
			Hour:   2,
			Minute: 30,
		},
		To: utils.Time{
			Hour:   6,
			Minute: 30,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(true, "compaction is set with valid timeframe")

	dconf.Compaction = compaction.Compaction{
		Threshold: utils.Threshold{
			Percentage: 75,
			Size:       512,
		},
		ViewThreshold: utils.Threshold{
			Percentage: 75,
			Size:       512,
		},
		From: utils.Time{
			Hour:   2,
			Minute: 30,
		},
		To: utils.Time{
			Hour:   6,
			Minute: 30,
		},
		AbortOutside: true,
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(true, "compaction is set with valid abortOutside")
}
