package bucket

import (
	"fmt"
	"github.com/a-novel/errors"
)

func (b *Bucket) VerifyBucketPurgeInterval(name string) *errors.Error {
	switch b.Type {
	case CouchbaseBucket:
		if b.PurgeInterval > 0 {
			if b.PurgeInterval < 0.04 {
				return errors.New(
					ErrPurgeIntervalTooSmall,
					fmt.Sprintf(
						"bucket %s purgeInterval value %v is too small, should be at least 0.04",
						name, b.PurgeInterval,
					),
				)
			}

			if b.PurgeInterval > 60 {
				return errors.New(
					ErrPurgeIntervalTooLarge,
					fmt.Sprintf(
						"bucket %s purgeInterval value %v is too large, should be at most 60",
						name, b.PurgeInterval,
					),
				)
			}
		}
	case EphemeralBucket:
		if b.PurgeInterval > 0 {
			if b.PurgeInterval < 0.007 {
				return errors.New(
					ErrPurgeIntervalTooSmall,
					fmt.Sprintf(
						"bucket %s purgeInterval value %v is too small, should be at least 0.007",
						name, b.PurgeInterval,
					),
				)
			}

			if b.PurgeInterval > 60 {
				return errors.New(
					ErrPurgeIntervalTooLarge,
					fmt.Sprintf(
						"bucket %s purgeInterval value %v is too large, should be at most 60",
						name, b.PurgeInterval,
					),
				)
			}
		}
	}

	return nil
}
