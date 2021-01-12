package bucket

import (
	"fmt"
	"github.com/a-novel/errors"
	"github.com/couchbase/gocb/v2"
)

func (b *Bucket) Verify(name string, cluster *gocb.Cluster) *errors.Error {
	if b.RamSize < 100 {
		return errors.New(
			ErrNotEnoughRam,
			fmt.Sprintf("bucket %s ramSize value %v Mb is too small, should be at least 100", name, b.RamSize),
		)
	}

	if err := b.VerifyBucketType(name); err != nil {
		return err
	}

	if err := b.VerifyBucketPriority(name); err != nil {
		return err
	}

	if err := b.VerifyBucketEvictionPolicy(name); err != nil {
		return err
	}

	if err := b.VerifyBucketPurgeInterval(name); err != nil {
		return err
	}

	if err := b.VerifyIndexes(name, cluster); err != nil {
		return err
	}

	if b.Type == EphemeralBucket {
		if b.IsIndexSetup() {
			return errors.New(
				ErrIndexSettingsAreCouchbaseBucketsOnly,
				fmt.Sprintf("index settings are only allowed for couchbase buckets in community edition, in bucket %s", name),
			)
		}

		if b.Compaction != nil {
			return errors.New(
				ErrCompactionSettingsAreCouchbaseBucketsOnly,
				fmt.Sprintf("compaction settings are only allowed for couchbase buckets, in bucket %s", name),
			)
		}
	}

	if b.Compaction != nil {
		if err := b.Compaction.Verify(); err != nil {
			err.Message = fmt.Sprintf("non valid compaction for bucket %s : %s", name, err.Message)
			return err
		}
	}

	return nil
}
