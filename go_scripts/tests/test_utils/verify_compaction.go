package test_utils

import (
	"fmt"
	"github.com/a-novel/divan-data-manager/types"
	"github.com/a-novel/divanDocker/compaction"
	"github.com/a-novel/divanDocker/utils"
)

func VerifyCompaction(initialSettings *compaction.Compaction, currentSettings *divan_types.AutoCompactionSettings) error {
	if initialSettings != nil && currentSettings == nil {
		return fmt.Errorf("no compaction settings detected")
	} else if initialSettings == nil && currentSettings != nil {
		return fmt.Errorf("compaction settings where returned while none where set")
	}

	if initialSettings == nil || currentSettings == nil {
		return nil
	}

	currentSettings.Parse()

	if initialSettings.ParallelCompaction != currentSettings.ParallelDBAndViewCompaction {
		return fmt.Errorf(
			"unexpected value for parallelCompaction : got %v instead of %v",
			currentSettings.ParallelDBAndViewCompaction,
			initialSettings.ParallelCompaction,
		)
	}

	if currentSettings.AllowedTimePeriod == nil {
		currentSettings.AllowedTimePeriod = &divan_types.AutoCompactionTimePeriodD{}
	}

	if utils.ToBytes(initialSettings.Threshold.Size) != currentSettings.DatabaseFragmentationThreshold.Size {
		return fmt.Errorf(
			"unexpected value for threshold.size : got %v instead of %v",
			currentSettings.DatabaseFragmentationThreshold.Size,
			utils.ToBytes(initialSettings.Threshold.Size),
		)
	}

	if initialSettings.Threshold.Percentage != currentSettings.DatabaseFragmentationThreshold.Percentage {
		return fmt.Errorf(
			"unexpected value for threshold.percentage : got %v instead of %v",
			currentSettings.DatabaseFragmentationThreshold.Percentage,
			initialSettings.Threshold.Percentage,
		)
	}

	if utils.ToBytes(initialSettings.ViewThreshold.Size) != currentSettings.ViewFragmentationThreshold.Size {
		return fmt.Errorf(
			"unexpected value for viewThreshold.size : got %v instead of %v",
			currentSettings.DatabaseFragmentationThreshold.Size,
			utils.ToBytes(initialSettings.Threshold.Size),
		)
	}

	if initialSettings.ViewThreshold.Percentage != currentSettings.ViewFragmentationThreshold.Percentage {
		return fmt.Errorf(
			"unexpected value for viewThreshold.percentage : got %v instead of %v",
			currentSettings.DatabaseFragmentationThreshold.Percentage,
			initialSettings.Threshold.Percentage,
		)
	}

	if initialSettings.From.Hour != currentSettings.AllowedTimePeriod.FromHour {
		return fmt.Errorf(
			"unexpected value for from.hour : got %v instead of %v",
			currentSettings.AllowedTimePeriod.FromHour,
			initialSettings.From.Hour,
		)
	}

	if initialSettings.From.Minute != currentSettings.AllowedTimePeriod.FromMinute {
		return fmt.Errorf(
			"unexpected value for from.minute : got %v instead of %v",
			currentSettings.AllowedTimePeriod.FromMinute,
			initialSettings.From.Minute,
		)
	}

	if initialSettings.To.Hour != currentSettings.AllowedTimePeriod.ToHour {
		return fmt.Errorf(
			"unexpected value for to.hour : got %v instead of %v",
			currentSettings.AllowedTimePeriod.ToHour,
			initialSettings.To.Hour,
		)
	}

	if initialSettings.To.Minute != currentSettings.AllowedTimePeriod.ToMinute {
		return fmt.Errorf(
			"unexpected value for to.minute : got %v instead of %v",
			currentSettings.AllowedTimePeriod.ToMinute,
			initialSettings.To.Minute,
		)
	}

	if initialSettings.AbortOutside != currentSettings.AllowedTimePeriod.AbortOutside {
		return fmt.Errorf(
			"unexpected value for abortOutside : got %v instead of %v",
			currentSettings.AllowedTimePeriod.AbortOutside,
			initialSettings.AbortOutside,
		)
	}

	return nil
}
