package utils

import (
	"fmt"
	"github.com/a-novel/errors"
)

const (
	ErrHourTooHigh   = "err_hour_too_high"
	ErrMinuteTooHigh = "err_minute_too_high"
)

type Time struct {
	Hour   uint64 `json:"hour"`
	Minute uint64 `json:"minute"`
}

func (t *Time) Verify() *errors.Error {
	if t.Hour > 23 {
		return errors.New(
			ErrHourTooHigh,
			fmt.Sprintf("hour value %v is too high, should be at most 23", t.Hour),
		)
	}

	if t.Minute > 59 {
		return errors.New(
			ErrMinuteTooHigh,
			fmt.Sprintf("minute value %v is too high, should be at most 59", t.Minute),
		)
	}

	return nil
}

func (t *Time) Equal(u Time) bool {
	return t.Hour == u.Hour && t.Minute == u.Minute
}
