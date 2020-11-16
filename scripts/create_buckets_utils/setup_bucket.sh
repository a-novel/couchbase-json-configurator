#!/bin/sh

bucket_name="$1"
current_buckets_count="$2"
current_buckets="$3"

bucket_data="$(jq -re ".database.resources.buckets[\"${bucket_name}\"] // empty" <"${DIVAN_CONFIG}")"

# Default value for bucket type is couchbase.
bucket_type="$(echo "$bucket_data" | jq -re ".type // empty")"
if [ -z "$bucket_type" ]; then
  bucket_type="couchbase"
fi

# Total RAM allocated for the bucket, in Mb.
bucket_ram="$(echo "$bucket_data" | jq -re ".ramSize // empty")"

# Above parameters are always given, but below ones are optional (and better left default if not given).
# If given, each optional parameter will add its command to a string, that will later be evaluated during the
# cli execution.

bucket_priority="$(echo "$bucket_data" | jq -re ".priority // empty")"

bucket_eviction_policy="$(echo "$bucket_data" | jq -re ".evictionPolicy // empty")"

flush="$(echo "$bucket_data" | jq -re ".flush // empty")"

bucket_compaction_threshold_percentage="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.threshold.percentage // empty" <"${DIVAN_CONFIG}"
)"

bucket_compaction_threshold_size="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.threshold.size // empty" <"${DIVAN_CONFIG}"
)"

bucket_view_compaction_threshold_percentage="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.viewThreshold.percentage // empty" <"${DIVAN_CONFIG}"
)"

bucket_view_compaction_threshold_size="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.viewThreshold.size // empty" <"${DIVAN_CONFIG}"
)"

bucket_compaction_from_hour="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.from.hour // empty" <"${DIVAN_CONFIG}"
)"

bucket_compaction_from_minute="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.from.minute // empty" <"${DIVAN_CONFIG}"
)"

bucket_compaction_to_hour="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.to.hour // empty" <"${DIVAN_CONFIG}"
)"

bucket_compaction_to_minute="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.to.minute // empty" <"${DIVAN_CONFIG}"
)"

bucket_abort_outside="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.abortOutside // empty" <"${DIVAN_CONFIG}"
)"

bucket_parallel_compaction="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].compaction.parallelCompaction // empty" <"${DIVAN_CONFIG}"
)"

bucket_purge_interval="$(
  jq -re ".database.resources.buckets[\"${bucket_name}\"].purgeInterval // empty" <"${DIVAN_CONFIG}"
)"

# Action determines what cli command to execute :
# - "" : create a new bucket
# - "{old_bucket_data}" : update an existing bucket
action="$(
  bash "$DIVAN_SCRIPTS/create_buckets_utils/should_bucket_update.sh" \
  "$bucket_name" "$bucket_type" "$bucket_eviction_policy" \
  "$current_buckets_count" "$current_buckets"
)" || {
  printf "%s" "$action" 1>&2
  exit 1
}

eval "$action"

# Create new bucket.
if [ -z "$OLD_BUCKET_DATA" ]; then
  sh "$DIVAN_SCRIPTS/create_buckets_utils/create_new_bucket.sh" \
"$bucket_name" "$bucket_type" "$bucket_ram" "$bucket_priority" "$bucket_eviction_policy" "$flush" \
"$bucket_compaction_threshold_percentage" "$bucket_compaction_threshold_size" \
"$bucket_view_compaction_threshold_percentage" "$bucket_view_compaction_threshold_size" \
"$bucket_compaction_from_hour" "$bucket_compaction_from_minute" \
"$bucket_compaction_to_hour" "$bucket_compaction_to_minute" \
"$bucket_abort_outside" "$bucket_purge_interval" "$bucket_parallel_compaction"

# Update existing bucket.
else
  sh "$DIVAN_SCRIPTS/create_buckets_utils/update_existing_bucket.sh" \
"$bucket_name" "$bucket_type" "$bucket_ram" "$bucket_priority" "$bucket_eviction_policy" "$flush" \
"$bucket_compaction_threshold_percentage" "$bucket_compaction_threshold_size" \
"$bucket_view_compaction_threshold_percentage" "$bucket_view_compaction_threshold_size" \
"$bucket_compaction_from_hour" "$bucket_compaction_from_minute" \
"$bucket_compaction_to_hour" "$bucket_compaction_to_minute" \
"$bucket_abort_outside" "$bucket_purge_interval" "$bucket_parallel_compaction" \
"$OLD_BUCKET_DATA"
fi

exit 0