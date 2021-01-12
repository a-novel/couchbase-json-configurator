package bucket

import (
	"fmt"
	"github.com/a-novel/errors"
)

func (b *Bucket) VerifyBucketType(name string) *errors.Error {
	if b.Type == "" || b.Type == "couchbase" {
		b.Type = CouchbaseBucket
	}

	if b.Type != CouchbaseBucket && b.Type != EphemeralBucket {
		return errors.New(
			ErrUnknownBucketType,
			fmt.Sprintf(
				"bucket %s has unknown bucket type %s : should be either %s or %s",
				name, b.Type, CouchbaseBucket, EphemeralBucket,
			),
		)
	}

	return nil
}
