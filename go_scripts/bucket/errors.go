package bucket

const (
	ErrNotEnoughRam                                 = "err_not_enough_ram"
	ErrUnknownBucketType                            = "err_unknown_bucket_type"
	ErrUnknownBucketPriority                        = "err_unknown_bucket_priority"
	ErrUnknownBucketEvictionPolicy                  = "err_unknown_bucket_eviction_policy"
	ErrMissingBucketEvictionPolicy                  = "err_missing_bucket_eviction_policy"
	ErrCompactionSettingsAreCouchbaseBucketsOnly    = "err_compaction_settings_are_couchbase_buckets_only"
	ErrPurgeIntervalTooSmall                        = "err_purge_interval_too_small"
	ErrPurgeIntervalTooLarge                        = "err_purge_interval_too_large"
	ErrNonValidIndexName                            = "err_non_valid_index_name"
	ErrCannotFetchIndexesInformation                = "err_cannot_fetch_indexes_information"
	ErrCannotParseIndexesInformation                = "err_cannot_parse_indexes_information"
	ErrCannotSetSecondaryIndexesWithoutPrimaryIndex = "err_cannot_set_secondary_indexes_without_primary_index"
	ErrIndexSettingsAreCouchbaseBucketsOnly         = "err_index_settings_are_couchbase_buckets_only"
)
