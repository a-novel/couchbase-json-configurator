package check_tests

import (
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/compaction"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"strings"
	"testing"
)

func TestWithNonValidBucketParameters(t *testing.T) {
	dconf := config.Config{
		Resources: resources.Resources{
			RamSize:      1024,
			FtsRamSize:   256,
			IndexRamSize: 256,
		},
		Credentials: credentials.Credentials{
			Username: "Administrator",
			Password: "password",
		},
		Buckets: map[string]*bucket.Bucket{
			"": {
				RamSize: 128,
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldFailWith(true, config.ErrEmptyBucketName, "bucket name is empty")

	dconf.Buckets = map[string]*bucket.Bucket{
		strings.Repeat("a", 101): {
			RamSize: 128,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, config.ErrBucketNameTooLong, "bucket name is too long")

	dconf.Buckets = map[string]*bucket.Bucket{
		"really??!": {
			RamSize: 128,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, config.ErrNonValidBucketName, "bucket name contains non allowed characters")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 99,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrNotEnoughRam, "bucket ramSize value is too low")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 100,
			Type:    "memcached",
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrUnknownBucketType, "bucket type value is not supported")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:  100,
			Priority: "medium",
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrUnknownBucketPriority, "bucket priority value is not supported")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:        100,
			EvictionPolicy: "nruEviction",
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrUnknownBucketEvictionPolicy, "bucket evictionPolicy value is not supported (couchbase buckets)")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:        100,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: "valueOnly",
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrUnknownBucketEvictionPolicy, "bucket evictionPolicy value is not supported (ephemeral buckets)")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:       100,
			PurgeInterval: 0.007,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrPurgeIntervalTooSmall, "bucket purgeInterval value is too low (couchbase buckets)")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:        100,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: bucket.EvictionPolicyNruEviction,
			PurgeInterval:  0.006,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrPurgeIntervalTooSmall, "bucket purgeInterval value is too low (ephemeral buckets)")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:       100,
			PurgeInterval: 61,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrPurgeIntervalTooLarge, "bucket purgeInterval value is too large (couchbase buckets)")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:        100,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: bucket.EvictionPolicyNruEviction,
			PurgeInterval:  61,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrPurgeIntervalTooLarge, "bucket purgeInterval value is too large (ephemeral buckets)")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:        100,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: bucket.EvictionPolicyNruEviction,
			Compaction: &compaction.Compaction{
				ParallelCompaction: true,
			},
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrCompactionSettingsAreCouchbaseBucketsOnly, "bucket compaction is set on ephemeral bucket")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 100,
			Type:    bucket.EphemeralBucket,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, bucket.ErrMissingBucketEvictionPolicy, "bucket evictionPolicy is missing on ephemeral bucket")
}

func TestWithValidBucketParameters(t *testing.T) {
	dconf := config.Config{
		Resources: resources.Resources{
			RamSize:      4096,
			FtsRamSize:   256,
			IndexRamSize: 256,
		},
		Credentials: credentials.Credentials{
			Username: "Administrator",
			Password: "password",
		},
		Buckets: map[string]*bucket.Bucket{
			".-_%Ab01%_-.": {
				RamSize: 100,
			},
			".-_%Ab02%_-.": {
				RamSize:        100,
				EvictionPolicy: bucket.EvictionPolicyValueOnly,
			},
			".-_%Ab03%_-.": {
				RamSize:        100,
				EvictionPolicy: bucket.EvictionPolicyFullEviction,
			},
			".-_%Ab04%_-.": {
				RamSize:        100,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNruEviction,
			},
			".-_%Ab05%_-.": {
				RamSize:        100,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNoEviction,
			},
			".-_%Ab06%_-.": {
				RamSize:  100,
				Priority: bucket.PriorityLow,
			},
			".-_%Ab07%_-.": {
				RamSize:  100,
				Priority: bucket.PriorityHigh,
			},
			".-_%Ab08%_-.": {
				RamSize:        100,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNruEviction,
				Priority:       bucket.PriorityLow,
			},
			".-_%Ab09%_-.": {
				RamSize:        100,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNoEviction,
				Priority:       bucket.PriorityHigh,
			},
			".-_%Ab10%_-.": {
				RamSize:       100,
				PurgeInterval: 0.04,
			},
			".-_%Ab11%_-.": {
				RamSize:        100,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNruEviction,
				PurgeInterval:  0.007,
			},
			".-_%Ab12%_-.": {
				RamSize: 100,
				Compaction: &compaction.Compaction{
					ParallelCompaction: true,
				},
			},
			".-_%Ab13%_-.": {
				RamSize: 100,
				Type:    "couchbase",
			},
			".-_%Ab14%_-.": {
				RamSize: 100,
				Type:    "membase",
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(true, "buckets are valid")
}
