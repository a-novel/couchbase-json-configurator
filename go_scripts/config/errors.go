package config

const (
	ErrEmptyBucketName                                     = "err_empty_bucket_name"
	ErrBucketNameTooLong                                   = "err_bucket_name_too_long"
	ErrNonValidBucketName                                  = "err_non_valid_bucket_name"
	ErrCannotSetupCluster                                  = "err_cannot_setup_cluster"
	ErrCannotAutoRemoveBucketsInSafeMode                   = "err_cannot_auto_remove_buckets_in_safe_mode"
	ErrCannotDeleteBucket                                  = "err_cannot_delete_bucket"
	ErrCannotConnectToCluster                              = "err_cannot_connect_to_cluster"
	ErrBucketResourcesOverflow                             = "err_bucket_resources_overflow"
	ErrCannotUpdateBucketDefaults                          = "err_cannot_update_bucket_defaults"
	ErrCannotUpdateBucketCompaction                        = "err_cannot_update_bucket_compaction"
	ErrCannotUpdateClusterCompaction                       = "err_cannot_update_cluster_compaction"
	ErrCannotUpdateBucketPriority                          = "err_cannot_update_bucket_priority"
	ErrCannotCreateBucketDefaults                          = "err_cannot_create_bucket_defaults"
	ErrCannotChangeBucketTypeInSafeMode                    = "err_cannot_change_bucket_type_in_safe_mode"
	ErrCannotChangeEphemeralBucketEvictionPolicyInSafeMode = "err_cannot_change_ephemeral_bucket_eviction_policy_in_safe_mode"
	ErrCannotReadBuckets                                   = "err_cannot_read_buckets"
	ErrCannotReachCluster                                  = "err_cannot_reach_cluster"
	ErrCannotFetchBucketsInformation                       = "err_cannot_fetch_buckets_information"
	ErrCannotReachBucket                                   = "err_cannot_reach_bucket"
	ErrCannotFindBucketStats                               = "err_cannot_find_bucket_stats"
	ErrResizingWithNotEnoughCapacity                       = "err_resizing_with_not_enough_capacity"
)
