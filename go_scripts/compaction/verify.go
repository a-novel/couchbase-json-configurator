package compaction

import (
	"fmt"
	"github.com/a-novel/divanDocker/utils"
	"github.com/a-novel/errors"
)

func (c *Compaction) Verify() *errors.Error {
	if err := c.Threshold.Verify(); err != nil {
		err.Message = fmt.Sprintf("non valid threshold : %s", err.Message)
		return err
	}

	if err := c.ViewThreshold.Verify(); err != nil {
		switch err.ID {
		case utils.ErrThresholdPercentageTooLow:
			return errors.New(
				ErrViewThresholdPercentageTooLow,
				fmt.Sprintf("non valid view threshold : %s", err.Error()),
			)
		case utils.ErrThresholdPercentageTooHigh:
			return errors.New(
				ErrViewThresholdPercentageTooHigh,
				fmt.Sprintf("non valid view threshold : %s", err.Error()),
			)
		}
	}

	if err := c.From.Verify(); err != nil {
		switch err.ID {
		case utils.ErrHourTooHigh:
			return errors.New(
				ErrFromHourTooHigh,
				fmt.Sprintf("non valid timeframe from : %s", err.Error()),
			)
		case utils.ErrMinuteTooHigh:
			return errors.New(
				ErrFromMinuteTooHigh,
				fmt.Sprintf("non valid timeframe from : %s", err.Error()),
			)
		}
	}

	if err := c.To.Verify(); err != nil {
		switch err.ID {
		case utils.ErrHourTooHigh:
			return errors.New(
				ErrToHourTooHigh,
				fmt.Sprintf("non valid timeframe to : %s", err.Error()),
			)
		case utils.ErrMinuteTooHigh:
			return errors.New(
				ErrToMinuteTooHigh,
				fmt.Sprintf("non valid timeframe to : %s", err.Error()),
			)
		}
	}

	if !c.From.Equal(c.To) && !c.Threshold.IsSet() && !c.ViewThreshold.IsSet() {
		return errors.New(
			ErrTimeFrameWithNoThreshold,
			"you can only set compaction timeframe with a compaction threshold",
		)
	}

	if c.AbortOutside && c.From.Equal(c.To) {
		return errors.New(
			ErrAbortOutsideOnEmptyFrame,
			"abortOutside can only be set with non empty timeframe",
		)
	}

	return nil
}
