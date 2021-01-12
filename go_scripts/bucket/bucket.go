package bucket

import (
	"github.com/a-novel/divanDocker/compaction"
	"github.com/a-novel/divanDocker/index"
)

/*
	Parameters for Couchbase buckets. If a bucket already exists, it will be updated with any modified value.

	RamSize is the only required parameter. In case of Ephemeral buckets, EvictionPolicy is also required.
*/
type Bucket struct {
	// The amount of Ram (Mb) to allocate for bucket data.
	RamSize uint64 `json:"ramSize"`
	// The type of the bucket. Currently only EphemeralBucket and CouchbaseBucket are supported.
	// Default value is CouchbaseBucket.
	Type string `json:"type"`
	// Set priority level for bucket background tasks. Supported values are PriorityLow and PriorityHigh.
	Priority string `json:"priority"`
	/*
		Policy to apply when the amount of data stored exceeds the amount of ram available for the bucket. Supported
		values depends on bucket Type:
		- EvictionPolicyValueOnly and EvictionPolicyFullEviction for CouchbaseBucket Type
		- EvictionPolicyNoEviction and EvictionPolicyNruEviction for EphemeralBucket Type

		This value is required for EphemeralBucket Type.
	*/
	EvictionPolicy string `json:"evictionPolicy"`
	// If set to true, enables bucket flush.
	Flush bool `json:"flush"`
	/*
		The interval between metadata purges. Supported values depends on bucket Type:
		- any float between 0.04 and 60 for CouchbaseBucket Type
		- any float between 0.007 and 60 for EphemeralBucket Type
	*/
	PurgeInterval float64 `json:"purgeInterval"`
	// Compaction settings for bucket (override global settings).
	Compaction *compaction.Compaction `json:"compaction" omitempty:"true"`
	// Required to perform queries.
	PrimaryIndex string                  `json:"primaryIndex"`
	Indexes      map[string]*index.Index `json:"indexes"`

	doPrimaryIndexExit bool
}

func (b *Bucket) DoPrimaryIndexExist() bool {
	return b.doPrimaryIndexExit
}
