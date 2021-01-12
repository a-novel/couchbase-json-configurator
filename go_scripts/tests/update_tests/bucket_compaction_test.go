package update_tests

import (
	"fmt"
	"github.com/a-novel/divan-data-manager"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/compaction"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/a-novel/divanDocker/utils"
	"testing"
)

func verifyBucketCompaction(dconf *config.Config) {
	timer := test_utils.Time("checking compaction on server")
	currentSettings, err := divan_data_manager.GetBucketsData(
		dconf.Credentials.Username,
		dconf.Credentials.Password,
		"",
	)

	if err != nil {
		timer.EndWithError(fmt.Sprintf("cannot retrieve buckets data : %s", err.Error()))
		return
	}

	for _, bucketSettings := range currentSettings {
		if err := bucketSettings.GetAutocompaction(); err != nil {
			timer.EndWithError(fmt.Sprintf(
				"cannot retrieve bucket autocompaction data in bucket %s : %s",
				bucketSettings.Name,
				err.Error(),
			))
			return
		}

		if err := test_utils.VerifyCompaction(
			dconf.Buckets[bucketSettings.Name].Compaction,
			bucketSettings.AutoCompactionSettingsD,
		); err != nil {
			timer.EndWithError(fmt.Sprintf(
				"unexpected autocompaction config on bucket %s : %s",
				bucketSettings.Name,
				err.Error(),
			))
			return
		}
	}

	timer.End("compaction checked")
}

func TestBucketCompactionUpdate(t *testing.T) {
	test_utils.Clean(t)
	test_utils.Launch(t)
	defer test_utils.Clean(t)

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
				RamSize: 128,
				Compaction: &compaction.Compaction{
					ParallelCompaction: true,
				},
			},
			"bucket_3": {
				RamSize: 128,
				Compaction: &compaction.Compaction{
					ParallelCompaction: false,
					Threshold: utils.Threshold{
						Size:       100,
						Percentage: 10,
					},
					ViewThreshold: utils.Threshold{
						Size:       100,
						Percentage: 10,
					},
				},
			},
			"bucket_4": {
				RamSize: 128,
				Compaction: &compaction.Compaction{
					ParallelCompaction: false,
					Threshold: utils.Threshold{
						Percentage: 50,
					},
					ViewThreshold: utils.Threshold{
						Size:       256,
						Percentage: 15,
					},
					From: utils.Time{
						Hour: 2,
					},
					To: utils.Time{
						Hour:   6,
						Minute: 30,
					},
				},
			},
			"bucket_5": {
				RamSize: 128,
				Compaction: &compaction.Compaction{
					ParallelCompaction: false,
					Threshold: utils.Threshold{
						Percentage: 50,
					},
					ViewThreshold: utils.Threshold{
						Size:       256,
						Percentage: 15,
					},
					From: utils.Time{
						Hour: 2,
					},
					To: utils.Time{
						Hour:   6,
						Minute: 30,
					},
					AbortOutside: true,
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(false, "cluster is setup with buckets compactions")
	verifyBucketCompaction(&dconf)

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 128,
		},
		"bucket_2": {
			RamSize: 128,
		},
		"bucket_3": {
			RamSize: 128,
		},
		"bucket_4": {
			RamSize: 128,
		},
		"bucket_5": {
			RamSize: 128,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "bucket compaction is removed")
	verifyBucketCompaction(&dconf)
}
