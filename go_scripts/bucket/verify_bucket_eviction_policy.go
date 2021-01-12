package bucket

import (
	"fmt"
	"github.com/a-novel/errors"
)

func (b *Bucket) VerifyBucketEvictionPolicy(name string) *errors.Error {
	switch b.Type {
	case CouchbaseBucket:
		if b.EvictionPolicy == "" {
			b.EvictionPolicy = EvictionPolicyValueOnly
		}

		if b.EvictionPolicy != EvictionPolicyValueOnly && b.EvictionPolicy != EvictionPolicyFullEviction {
			return errors.New(
				ErrUnknownBucketEvictionPolicy,
				fmt.Sprintf(
					"bucket %s has unknown bucket evictionPolicy %s : should be either %s or %s",
					name, b.EvictionPolicy, EvictionPolicyValueOnly, EvictionPolicyFullEviction,
				),
			)
		}
	case EphemeralBucket:
		if b.EvictionPolicy == "" {
			return errors.New(
				ErrMissingBucketEvictionPolicy,
				fmt.Sprintf(
					"missing evictionPolicy for bucket %s : this parameter is required for ephemeral buckets",
					name,
				),
			)
		}

		if b.EvictionPolicy != EvictionPolicyNoEviction && b.EvictionPolicy != EvictionPolicyNruEviction {
			return errors.New(
				ErrUnknownBucketEvictionPolicy,
				fmt.Sprintf(
					"bucket %s has unknown bucket evictionPolicy %s : should be either %s or %s",
					name, b.EvictionPolicy, EvictionPolicyNoEviction, EvictionPolicyNruEviction,
				),
			)
		}
	}

	return nil
}
