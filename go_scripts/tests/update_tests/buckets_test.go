package update_tests

import (
	"fmt"
	"github.com/a-novel/divanDocker/bucket"
	"github.com/a-novel/divanDocker/config"
	"github.com/a-novel/divanDocker/credentials"
	"github.com/a-novel/divanDocker/parameters"
	"github.com/a-novel/divanDocker/resources"
	"github.com/a-novel/divanDocker/tests/test_utils"
	"github.com/couchbase/gocb/v2"
	"testing"
)

type sampleData struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	Timestamp   uint64 `json:"timestamp"`
}

func (s *sampleData) Equal(t *sampleData) bool {
	return s.Title == t.Title && s.Description == t.Description && s.Timestamp == t.Timestamp
}

func verifyBucket(name string, cluster *gocb.Cluster, data *sampleData) {
	timer := test_utils.Time(fmt.Sprintf("checking bucket %s", name))

	result, err := cluster.Bucket(name).DefaultCollection().Get("elem_1", nil)

	if result == nil {
		timer.EndWithError(fmt.Sprintf("cannot find document 'elem_1' in bucket %s", name))
		return
	}

	if err != nil {
		timer.EndWithError(fmt.Sprintf("query error in bucket %s : %s", name, err.Error()))
	}

	var output sampleData

	if err := result.Content(&output); err != nil {
		timer.EndWithError(fmt.Sprintf("malformed query result in bucket %s : %s", name, err.Error()))
	}

	if !output.Equal(data) {
		timer.EndWithError(fmt.Sprintf("unexpected query result in bucket %s", name))
	}

	timer.End(fmt.Sprintf("bucket %s checked successfully", name))
}

func populateBuckets(t *testing.T, cluster *gocb.Cluster, data1, data2 sampleData) {
	timer := test_utils.Time("populating bucket sample")
	_, err2 := cluster.Bucket("sample").DefaultCollection().Insert("elem_1", data1, nil)
	if err2 != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot populate bucket sample : %s", err2.Error()), t)
	}
	timer.End("populated bucket sample successfully")

	timer = test_utils.Time("populating bucket eph_sample")
	_, err2 = cluster.Bucket("eph_sample").DefaultCollection().Insert("elem_1", data2, nil)
	if err2 != nil {
		timer.EndWithFatalError(fmt.Sprintf("cannot populate bucket eph_sample : %s", err2.Error()), t)
	}
	timer.End("populated bucket eph_sample successfully")
}

func TestBucketsUpdate(t *testing.T) {
	test_utils.Clean(t)
	test_utils.Launch(t)
	defer test_utils.Clean(t)

	dconf := config.Config{
		Parameters: parameters.Parameters{
			Timeout: 120,
		},
		Resources: resources.Resources{
			RamSize:      2048,
			FtsRamSize:   256,
			IndexRamSize: 256,
		},
		Credentials: credentials.Credentials{
			Username: "Administrator",
			Password: "password",
		},
		Buckets: map[string]*bucket.Bucket{
			"sample": {
				RamSize: 512,
			},
			"eph_sample": {
				RamSize:        256,
				Type:           bucket.EphemeralBucket,
				EvictionPolicy: bucket.EvictionPolicyNoEviction,
			},
		},
	}

	data1 := sampleData{Title: "my book", Description: "A sci-fi novel", Timestamp: 123456789}
	data2 := sampleData{Title: "my other book", Description: "A fantasy novel", Timestamp: 111111111}

	test_utils.WriteConfigAuto(dconf, t)
	defer test_utils.DeleteConfigAuto(t)
	test_utils.ShouldPass(false, "buckets are setup")

	cluster := test_utils.GetCluster(t, &dconf)
	populateBuckets(t, cluster, data1, data2)

	verifyBucket("sample", cluster, &data1)
	verifyBucket("eph_sample", cluster, &data2)

	dconf.Buckets = map[string]*bucket.Bucket{
		"sample": {
			RamSize: 1024,
		},
		"eph_sample": {
			RamSize:        512,
			Type:           bucket.EphemeralBucket,
			EvictionPolicy: bucket.EvictionPolicyNoEviction,
		},
	}

	test_utils.WriteConfigAuto(dconf, t)
	test_utils.ShouldPass(false, "buckets are updated")

	cluster = test_utils.GetCluster(t, &dconf)
	verifyBucket("sample", cluster, &data1)
	verifyBucket("eph_sample", cluster, &data2)
}
