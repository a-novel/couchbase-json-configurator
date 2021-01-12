package check_tests

import (
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"testing"
)

func TestWithMissingResources(t *testing.T) {
	dconf := config.Config{
		Credentials: credentials.Credentials{
			Username: "Administrator",
			Password: "password",
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldFailWith(true, resources.ErrNotEnoughRam, "resources are missing")

	dconf.Resources.RamSize = 255
	dconf.Resources.IndexRamSize = 256
	dconf.Resources.FtsRamSize = 256
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, resources.ErrNotEnoughRam, "ramSize is too small")

	dconf.Resources.RamSize = 1024
	dconf.Resources.IndexRamSize = 255
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, resources.ErrNotEnoughIndexRam, "indexRamSize is too small")

	dconf.Resources.IndexRamSize = 256
	dconf.Resources.FtsRamSize = 255
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, resources.ErrNotEnoughFtsRam, "ftsRamSize is too small")

	dconf.Resources.FtsRamSize = 256
	dconf.Resources.PurgeInterval = 0.03
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, resources.ErrPurgeIntervalTooSmall, "purgeInterval is too small")

	dconf.Resources.PurgeInterval = 61
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, resources.ErrPurgeIntervalTooLarge, "purgeInterval is too large")

	dconf.Resources.PurgeInterval = 0
	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 1024,
		},
		"bucket_2": {
			RamSize: 1024,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, config.ErrBucketResourcesOverflow, "buckets are asking for too much resources")

	dconf.Resources.RamSize = 0
	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 100,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldFailWith(true, resources.ErrNotEnoughRam, "buckets are not asking for enough resources with automatic allocation")
}

func TestWithValidResources(t *testing.T) {
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
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(true, "resources are valid")

	dconf.Resources.PurgeInterval = 33.3
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(true, "resources has a valid purgeInterval value")

	dconf.Resources.RamSize = 0
	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 512,
		},
		"bucket_2": {
			RamSize: 512,
		},
	}
	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(true, "resources are set with automatic allocation")
}
