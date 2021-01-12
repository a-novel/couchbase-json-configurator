package bucket

import (
	"fmt"
	"github.com/a-novel/errors"
)

func (b *Bucket) VerifyBucketPriority(name string) *errors.Error {
	if b.Priority == "" {
		b.Priority = PriorityLow
	}

	if b.Priority != PriorityLow && b.Priority != PriorityHigh {
		return errors.New(
			ErrUnknownBucketPriority,
			fmt.Sprintf(
				"bucket %s has unknown bucket priority %s : should be either %s or %s",
				name, b.Priority, PriorityLow, PriorityHigh,
			),
		)
	}

	return nil
}
