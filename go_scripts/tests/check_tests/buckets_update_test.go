package check_tests

import (
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/a-novel/divanDocker/utils"
	"os"
	"testing"
)

func TestRemovingNonUpgradableParametersInProductionMode(t *testing.T) {
	test_utils.Clean(t)
	test_utils.Launch(t)
	defer test_utils.Clean(t)

	if err := os.Setenv("ENV", utils.EnvProduction); err != nil {
		t.Fatalf("cannot setup env variable : %s", err.Error())
	}
	defer os.Setenv("ENV", "")

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
				RamSize: 128,
			},
			"bucket_2": {
				RamSize:        128,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNruEviction,
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(false, "setting up cluster with validated parameters")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 128,
		},
		"bucket_2": {
			RamSize:        128,
			Type:           bucket.CouchbaseBucket,
			EvictionPolicy: bucket.EvictionPolicyValueOnly,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, config.ErrCannotChangeBucketTypeInSafeMode, "changing ephemeral bucket type")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize:        128,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: bucket.EvictionPolicyNruEviction,
		},
		"bucket_2": {
			RamSize:        128,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: bucket.EvictionPolicyNruEviction,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, config.ErrCannotChangeBucketTypeInSafeMode, "changing couchbase bucket type")

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 128,
			Type:    bucket.CouchbaseBucket,
		},
		"bucket_2": {
			RamSize:        128,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: bucket.EvictionPolicyNoEviction,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(
		true,
		config.ErrCannotChangeEphemeralBucketEvictionPolicyInSafeMode,
		"changing ephemeral bucket evictionPolicy",
	)

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 128,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, config.ErrCannotAutoRemoveBucketsInSafeMode, "removing bucket in safe mode")
}
