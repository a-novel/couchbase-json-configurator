package resources

import (
	"fmt"
	"github.com/a-novel/errors"
)

func (r *Resources) Verify() *errors.Error {
	if r.RamSize < 256 {
		return errors.New(
			ErrNotEnoughRam,
			fmt.Sprintf("cluster ramSize value %vMb is too small, should be at least 1024", r.RamSize),
		)
	}

	if r.IndexRamSize < 256 {
		return errors.New(
			ErrNotEnoughIndexRam,
			fmt.Sprintf("cluster indexRamSize value %vMb is too small, should be at least 256", r.IndexRamSize),
		)
	}

	if r.FtsRamSize < 256 {
		return errors.New(
			ErrNotEnoughFtsRam,
			fmt.Sprintf("cluster ftsRamSize value %vMb is too small, should be at least 256", r.FtsRamSize),
		)
	}

	if r.PurgeInterval > 0 {
		if r.PurgeInterval < 0.04 {
			return errors.New(
				ErrPurgeIntervalTooSmall,
				fmt.Sprintf("cluster purgeInterval value %v is too small, should be at least 0.04", r.PurgeInterval),
			)
		}

		if r.PurgeInterval > 60 {
			return errors.New(
				ErrPurgeIntervalTooLarge,
				fmt.Sprintf("cluster purgeInterval value %v is too large, should be at most 60", r.PurgeInterval),
			)
		}
	}

	return nil
}
