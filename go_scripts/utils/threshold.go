package utils

import (
	"fmt"
	"github.com/a-novel/errors"
)

const (
	ErrThresholdPercentageTooLow  = "err_threshold_percentage_too_low"
	ErrThresholdPercentageTooHigh = "err_threshold_percentage_too_high"
)

type Threshold struct {
	Percentage uint64 `json:"percentage"`
	Size       uint64 `json:"size"`
}

func (t *Threshold) Verify() *errors.Error {
	if t.Percentage > 0 {
		if t.Percentage < 2 {
			return errors.New(
				ErrThresholdPercentageTooLow,
				fmt.Sprintf("threshold percentage value %v is too low, should be at least 2", t.Percentage),
			)
		}

		if t.Percentage > 100 {
			return errors.New(
				ErrThresholdPercentageTooHigh,
				fmt.Sprintf("threshold percentage value %v is too high, should be at most 100", t.Percentage),
			)
		}
	}

	return nil
}

func (t *Threshold) IsSet() bool {
	return t.Percentage > 0 || t.Size > 0
}
