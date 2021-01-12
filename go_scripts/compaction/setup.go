package compaction

import (
	"fmt"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
	"strings"
)

func (c *Compaction) Setup(url string, purgeInterval float64, credentials credentials.Credentials) *errors.Error {
	updateParams := []string{
		"curl", "-sX", "POST",
		"-u", fmt.Sprintf("'%s':'%s'", credentials.Username, credentials.Password),
		fmt.Sprintf("'%s'", url),
		"-d", "\"autoCompactionDefined=true\"",
		"-d", fmt.Sprintf("\"parallelDBAndViewCompaction=%v\"", c.ParallelCompaction),
	}

	if c.Threshold.Percentage > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"databaseFragmentationThreshold[percentage]=%v\"", c.Threshold.Percentage),
		)
	}
	if c.Threshold.Size > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"databaseFragmentationThreshold[size]=%v\"", utils.ToBytes(c.Threshold.Size)),
		)
	}

	if c.ViewThreshold.Percentage > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"viewFragmentationThreshold[percentage]=%v\"", c.ViewThreshold.Percentage),
		)
	}
	if c.ViewThreshold.Size > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"viewFragmentationThreshold[size]=%v\"", utils.ToBytes(c.ViewThreshold.Size)),
		)
	}

	if c.From.Hour > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"allowedTimePeriod[fromHour]=%v\"", c.From.Hour),
		)
	}
	if c.From.Minute > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"allowedTimePeriod[fromMinute]=%v\"", c.From.Minute),
		)
	}
	if c.To.Hour > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"allowedTimePeriod[toHour]=%v\"", c.To.Hour),
		)
	}
	if c.To.Minute > 0 {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"allowedTimePeriod[toMinute]=%v\"", c.To.Minute),
		)
	}

	if !c.From.Equal(c.To) {
		updateParams = append(
			updateParams, "-d",
			fmt.Sprintf("\"allowedTimePeriod[abortOutside]=%v\"", c.AbortOutside),
		)
	}

	if purgeInterval == 0 {
		purgeInterval = 3
	}

	updateParams = append(
		updateParams, "-d",
		fmt.Sprintf("\"purgeInterval=%v\"", purgeInterval),
	)

	if _, err := utils.Command(
		"sh", "-c",
		strings.Join(updateParams, " "),
	); err != nil {
		return errors.New(
			ErrCannotUpdateCompaction,
			err.Error(),
		)
	}

	return nil
}
