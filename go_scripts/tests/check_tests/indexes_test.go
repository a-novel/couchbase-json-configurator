package check_tests

import (
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/index"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"testing"
)

func TestWithNonValidBucketIndexes(t *testing.T) {
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
			"bucket_1": {
				RamSize:        128,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNoEviction,
				PrimaryIndex:   "bucket_1-primary-index",
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldFailWith(true, bucket.ErrIndexSettingsAreCouchbaseBucketsOnly, "index is set on ephemeral bucket")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 128,
			Indexes: map[string]*index.Index{
				"index-sample": {
					IndexKey: []string{
						"name",
					},
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(
		true,
		bucket.ErrCannotSetSecondaryIndexesWithoutPrimaryIndex,
		"secondary indexes are set without primary index",
	)

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:      128,
			PrimaryIndex: "ind@ex",
			Indexes: map[string]*index.Index{
				"index-sample": {
					IndexKey: []string{
						"name",
					},
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(
		true,
		bucket.ErrNonValidIndexName,
		"primary index name contains forbidden character",
	)

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:      128,
			PrimaryIndex: "-index",
			Indexes: map[string]*index.Index{
				"index-sample": {
					IndexKey: []string{
						"name",
					},
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(
		true,
		bucket.ErrNonValidIndexName,
		"primary index name doesn't start with alphabet letter",
	)

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:      128,
			PrimaryIndex: "bucket_1-index",
			Indexes: map[string]*index.Index{
				"ind@ex-sample": {
					IndexKey: []string{
						"name",
					},
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(
		true,
		bucket.ErrNonValidIndexName,
		"secondary index name contains forbidden character",
	)

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:      128,
			PrimaryIndex: "bucket_1-index",
			Indexes: map[string]*index.Index{
				"-index-sample": {
					IndexKey: []string{
						"name",
					},
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(
		true,
		bucket.ErrNonValidIndexName,
		"secondary index name doesn't start with alphabet letter",
	)
}

func TestWithValidBucketIndexes(t *testing.T) {
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
			"bucket_1": {
				RamSize:      128,
				PrimaryIndex: "bucket_1-primary-index",
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(true, "primary index is setup alone")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:      128,
			PrimaryIndex: "bucket_1-index",
			Indexes: map[string]*index.Index{
				"index-sample": {
					IndexKey: []string{
						"name",
					},
				},
				"index-sample#2": {
					IndexKey: []string{
						"description",
					},
					Condition: "type = `sci-fi`",
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(true, "secondary indexes are setup")
}
