package update_tests

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/index"
	"github.com/a-novel/divanDocker/parameters"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/a-novel/divanDocker/utils"
	"strings"
	"testing"
)

func verifyIndexes(dconf config.Config) {
	timer := test_utils.Time("checking bucket indexes on server")
	cluster, err := dconf.Cluster()
	if err != nil {
		timer.EndWithError(fmt.Sprintf("cannot reach cluster : %s", err.Error()))
		return
	}

	for bucketName, bucketData := range dconf.Buckets {
		currentIndexes, err := cluster.QueryIndexes().GetAllIndexes(bucketName, nil)
		if err != nil {
			timer.EndWithError(fmt.Sprintf("cannot get indexes for bucket %s : %s", bucketName, err.Error()))
			return
		}

		if bucketData.Indexes == nil {
			bucketData.Indexes = map[string]*index.Index{}
		}

		for _, currentIndex := range currentIndexes {
			if currentIndex.IsPrimary && currentIndex.Name != bucketData.PrimaryIndex {
				timer.EndWithError(fmt.Sprintf(
					"unexpected primary index name on bucket %s : got %s instead of %s",
					bucketName,
					currentIndex.Name,
					bucketData.PrimaryIndex,
				))
				return
			}

			if currentIndex.IsPrimary {
				continue
			}

			confIndex, ok := bucketData.Indexes[currentIndex.Name]
			if !ok {
				timer.EndWithError(fmt.Sprintf(
					"unexpected index %s on bucket %s : not in config",
					currentIndex.Name,
					bucketName,
				))
				return
			}

			if confIndex.Condition != currentIndex.Condition {
				timer.EndWithError(fmt.Sprintf(
					"index %s on bucket %s have '%s' condition on server ('%s' in config)",
					currentIndex.Name,
					bucketName,
					currentIndex.Condition,
					confIndex.Condition,
				))
				return
			}

			if utils.StrSliceEqual(confIndex.IndexKey, currentIndex.IndexKey) {
				timer.EndWithError(fmt.Sprintf(
					"index %s on bucket %s have [%s] indexKeys on server ([%s] in config)",
					currentIndex.Name,
					bucketName,
					strings.Join(currentIndex.IndexKey, ","),
					strings.Join(confIndex.IndexKey, ","),
				))
				return
			}
		}

		for confIndexName, _ := range bucketData.Indexes {
			found := false
			for _, currentIndex := range currentIndexes {
				if currentIndex.Name == confIndexName {
					found = true
					break
				}
			}

			if !found {
				timer.EndWithError(fmt.Sprintf(
					"index %s on bucket %s was not found on cluster",
					confIndexName,
					bucketName,
				))
				return
			}
		}
	}

	timer.End("indexes checked")
}

func TestBucketIndexesUpdate(t *testing.T) {
	test_utils.Clean(t)
	test_utils.Launch(t)
	defer test_utils.Clean(t)

	dconf := config.Config{
		Parameters: parameters.Parameters{
			Timeout: 120,
		},
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
				PrimaryIndex: "bucket_2-primary-index",
			},
			"bucket_3": {
				RamSize: 128,
				PrimaryIndex: "bucket_3-primary-index",
				Indexes: map[string]*index.Index{
					"index-bucket_3-by-title": {
						IndexKey: []string{"title"},
					},
					"index-bucket_3-for-author-scifi": {
						IndexKey: []string{"author"},
					},
				},
			},
			"bucket_4": {
				RamSize: 128,
				PrimaryIndex: "bucket_4-primary-index",
				Indexes: map[string]*index.Index{
					"index-bucket_4-by-description": {
						IndexKey: []string{"description"},
					},
				},
			},
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(false, "cluster is setup with buckets indexes")
	verifyIndexes(dconf)

	dconf.Buckets = map[string]*bucket.Bucket{
		"bucket_1": {
			RamSize: 128,
			PrimaryIndex: "bucket_1-primary-index",
			Indexes: map[string]*index.Index{
				"index-bucket_4-by-description": {
					IndexKey: []string{"description"},
				},
			},
		},
		"bucket_2": {
			RamSize: 128,
		},
		"bucket_3": {
			RamSize: 128,
			PrimaryIndex: "bucket_3-primary-index#",
			Indexes: map[string]*index.Index{
				"index-bucket_3-by-title": {
					IndexKey: []string{"title"},
				},
				"index-bucket_3-for-author-scifi": {
					IndexKey: []string{"genre", "author"},
				},
			},
		},
		"bucket_4": {
			RamSize: 128,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "bucket indexes are updated")

	verifyIndexes(dconf)
}